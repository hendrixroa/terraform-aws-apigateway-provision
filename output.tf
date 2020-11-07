output "api_rest_id" {
  value = aws_api_gateway_rest_api.api.id
}

output "api_deployment" {
  value = aws_api_gateway_deployment.api.id
}

output "api_domain_name" {
  value = aws_api_gateway_domain_name.api_domain.regional_domain_name
}