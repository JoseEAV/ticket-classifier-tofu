terraform {
  required_version = ">= 1.6"

  backend "s3" {}

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# S3 Bucket para almacenar tickets clasificados
resource "aws_s3_bucket" "tickets_bucket" {
  bucket = "${var.project_name}-${var.student_id}-tickets"

  tags = {
    Name        = "${var.project_name}-${var.student_id}-tickets"
    Environment = "learning"
    Project     = var.project_name
    StudentID   = var.student_id
  }
}

# Bloquear acceso público al bucket
resource "aws_s3_bucket_public_access_block" "tickets_bucket" {
  bucket = aws_s3_bucket.tickets_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Versioning para el bucket (opcional pero recomendado)
resource "aws_s3_bucket_versioning" "tickets_bucket" {
  bucket = aws_s3_bucket.tickets_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Lambda 1: Validate Ticket
module "validate_ticket" {
  source = "./modules/lambda_function"

  function_name = "${var.project_name}-${var.student_id}-validate-ticket"
  source_dir    = "${path.module}/lambdas/validate_ticket"
  role_arn      = aws_iam_role.lambda_role.arn
  timeout       = 10

  environment_variables = {
    PROJECT_NAME = var.project_name
    STUDENT_ID   = var.student_id
  }
}

# Lambda 2: Classify Ticket
module "classify_ticket" {
  source = "./modules/lambda_function"

  function_name = "${var.project_name}-${var.student_id}-classify-ticket"
  source_dir    = "${path.module}/lambdas/classify_ticket"
  role_arn      = aws_iam_role.lambda_role.arn
  timeout       = 10

  environment_variables = {
    PROJECT_NAME = var.project_name
    STUDENT_ID   = var.student_id
  }
}

# Lambda 3: Route Ticket
module "route_ticket" {
  source = "./modules/lambda_function"

  function_name = "${var.project_name}-${var.student_id}-route-ticket"
  source_dir    = "${path.module}/lambdas/route_ticket"
  role_arn      = aws_iam_role.lambda_role.arn
  timeout       = 15

  environment_variables = {
    BUCKET_NAME  = aws_s3_bucket.tickets_bucket.bucket
    PROJECT_NAME = var.project_name
    STUDENT_ID   = var.student_id
  }
}
