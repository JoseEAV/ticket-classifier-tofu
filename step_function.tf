resource "aws_sfn_state_machine" "ticket_classifier" {
  name     = "${var.project_name}-${var.student_id}-ticket-classifier"
  role_arn = aws_iam_role.step_function_role.arn

  definition = jsonencode({
    Comment = "Support Ticket Classification Pipeline"
    StartAt = "ValidateTicket"
    States = {
      # Estado 1: Validar ticket
      ValidateTicket = {
        Type     = "Task"
        Resource = module.validate_ticket.lambda_arn
        Next     = "ClassifyTicket"
        Catch = [{
          ErrorEquals = ["States.ALL"]
          Next        = "ValidationFailed"
        }]
      }

      # Estado 2: Clasificar ticket
      ClassifyTicket = {
        Type     = "Task"
        Resource = module.classify_ticket.lambda_arn
        Next     = "RouteBySeverity"
      }

      # Estado 3: Choice - Enrutar según severidad
      RouteBySeverity = {
        Type = "Choice"
        Choices = [
          {
            Variable      = "$.severity"
            StringEquals  = "urgent"
            Next          = "RouteUrgent"
          },
          {
            Variable      = "$.severity"
            StringEquals  = "normal"
            Next          = "RouteNormal"
          },
          {
            Variable      = "$.severity"
            StringEquals  = "low"
            Next          = "RouteLow"
          }
        ]
        Default = "RouteNormal"
      }

      # Estado 4a: Ruta urgente
      RouteUrgent = {
        Type     = "Task"
        Resource = module.route_ticket.lambda_arn
        Next     = "TicketProcessedSuccessfully"
      }

      # Estado 4b: Ruta normal
      RouteNormal = {
        Type     = "Task"
        Resource = module.route_ticket.lambda_arn
        Next     = "TicketProcessedSuccessfully"
      }

      # Estado 4c: Ruta baja prioridad
      RouteLow = {
        Type     = "Task"
        Resource = module.route_ticket.lambda_arn
        Next     = "TicketProcessedSuccessfully"
      }

      # Estado de éxito
      TicketProcessedSuccessfully = {
        Type = "Succeed"
      }

      # Estado de fallo
      ValidationFailed = {
        Type  = "Fail"
        Error = "TicketValidationError"
        Cause = "The ticket failed validation checks"
      }
    }
  })

  logging_configuration {
    log_destination        = "${aws_cloudwatch_log_group.step_function_logs.arn}:*"
    include_execution_data = true
    level                  = "ALL"
  }

  tags = {
    Name        = "${var.project_name}-${var.student_id}-ticket-classifier"
    Environment = "learning"
    Project     = var.project_name
    StudentID   = var.student_id
  }
}

# CloudWatch Log Group para Step Function
resource "aws_cloudwatch_log_group" "step_function_logs" {
  name              = "/aws/stepfunctions/${var.project_name}-${var.student_id}-ticket-classifier"
  retention_in_days = 7

  tags = {
    Name      = "${var.project_name}-${var.student_id}-step-function-logs"
    Project   = var.project_name
    StudentID = var.student_id
  }
}

# IAM Role para Step Functions
resource "aws_iam_role" "step_function_role" {
  name = "${var.project_name}-${var.student_id}-step-function-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "states.amazonaws.com"
      }
    }]
  })

  tags = {
    Name      = "${var.project_name}-${var.student_id}-step-function-role"
    Project   = var.project_name
    StudentID = var.student_id
  }
}

# Política para invocar Lambdas
resource "aws_iam_role_policy" "step_function_lambda_policy" {
  name = "${var.project_name}-${var.student_id}-lambda-invoke"
  role = aws_iam_role.step_function_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "lambda:InvokeFunction"
      ]
      Resource = [
        module.validate_ticket.lambda_arn,
        module.classify_ticket.lambda_arn,
        module.route_ticket.lambda_arn
      ]
    }]
  })
}

# Política para CloudWatch Logs
resource "aws_iam_role_policy" "step_function_logs_policy" {
  name = "${var.project_name}-${var.student_id}-logs"
  role = aws_iam_role.step_function_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "logs:CreateLogDelivery",
        "logs:GetLogDelivery",
        "logs:UpdateLogDelivery",
        "logs:DeleteLogDelivery",
        "logs:ListLogDeliveries",
        "logs:PutResourcePolicy",
        "logs:DescribeResourcePolicies",
        "logs:DescribeLogGroups"
      ]
      Resource = "*"
    }]
  })
}

# Output del ARN del Step Function
output "step_function_arn" {
  description = "ARN de la Step Function para clasificación de tickets"
  value       = aws_sfn_state_machine.ticket_classifier.arn
}

output "step_function_name" {
  description = "Nombre de la Step Function"
  value       = aws_sfn_state_machine.ticket_classifier.name
}
