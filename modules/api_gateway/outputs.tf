output "rest_api_id" {
  value = aws_api_gateway_rest_api.this.id
}

output "execution_arn" {
  value = aws_api_gateway_rest_api.this.execution_arn
}

output "invoke_url" {
  value = aws_api_gateway_stage.this.invoke_url
}

output "stage_name" {
  value = aws_api_gateway_stage.this.stage_name
}

output "vpc_endpoint_id" {
  value = aws_vpc_endpoint.execute_api.id
}

output "authorizer_id" {
  value = aws_api_gateway_authorizer.lambda.id
}
