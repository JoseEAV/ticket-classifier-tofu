output "lambda_arn" {
  description = "ARN de la función Lambda"
  value       = aws_lambda_function.this.arn
}
