output "lambda_qualified_arn" {
  value = aws_lambda_function.alp_lambda_function.qualified_arn
}

output "lambda_version" {
  value = aws_lambda_function.alp_lambda_function.version
}

output "lambda_last_modified" {
  value = aws_lambda_function.alp_lambda_function.last_modified
}

output "lambda_size" {
  value = aws_lambda_function.alp_lambda_function.source_code_size
}

output "lambda_dns" {
  value = aws_lb.alp_alb.dns_name
}

output "s3_random_pet" {
  value = random_pet.pet.id
}

output "s3_random_uuid" {
  value = random_uuid.uuid.result
}

output "s3_alb_access_logs" {
  value = aws_s3_bucket.alp_s3.bucket
}
