// Api Gateway rest api resource of `Regional` type
resource "aws_api_gateway_rest_api" "api" {
  name               = "${var.app_name}_platform"
  binary_media_types = var.binary_media_types

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

// VPC Link used to forward all the trafic from ecs to Api Gateway and viceversa
resource "aws_api_gateway_vpc_link" "api_vpclink" {
  name        = "${var.app_name}-gateway-vpc-link"
  description = "VPC Link used to forward the trafic from ecs to Api Gateway"
  target_arns = [var.lb_arn]
}

// Custom domain name user friendly readable to hit into API.
resource "aws_api_gateway_domain_name" "api_domain" {
  domain_name              = var.domain_url
  regional_certificate_arn = var.certificate_arn

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

// Resource to link the user friendly domain name with the current api deployment.
resource "aws_api_gateway_base_path_mapping" "api_basepath" {
  api_id      = aws_api_gateway_rest_api.api.id
  stage_name  = var.api_stage
  domain_name = aws_api_gateway_domain_name.api_domain.domain_name
  base_path   = var.api_stage

  depends_on = [
    aws_api_gateway_deployment.api,
  ]

  lifecycle {
    ignore_changes = [
      id,
      api_id,
      domain_name,
    ]
  }
}

// Resource to deploy the current API Rest to be available to hit it.
resource "aws_api_gateway_deployment" "api" {
  depends_on = [
    aws_api_gateway_rest_api.api,
    aws_api_gateway_resource.api,
    aws_api_gateway_method.api,
    aws_api_gateway_integration.api,
  ]

  rest_api_id = aws_api_gateway_rest_api.api.id
  stage_name  = var.api_stage

  variables = {
    "vpcLinkId"  = aws_api_gateway_vpc_link.api_vpclink.id
    "nlbDnsName" = var.lb_dns_name
    "port"       = var.api_port
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_resource" "api" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "start"

  lifecycle {
    ignore_changes = [
      id,
      rest_api_id,
      parent_id,
      path_part,
    ]
  }
}

resource "aws_api_gateway_method" "api" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.api.id
  http_method   = "ANY"
  authorization = "NONE"

  lifecycle {
    ignore_changes = [
      id,
      resource_id,
      rest_api_id,
      http_method,
      authorization,
      api_key_required,
    ]
  }
}

resource "aws_api_gateway_integration" "api" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_method.api.resource_id
  http_method = aws_api_gateway_method.api.http_method
  type        = "MOCK"
  request_templates = {
    "application/json" = <<EOF
{
   "body" : $input.json('$')
}
EOF
  }

  lifecycle {
    ignore_changes = [
      id,
      cache_namespace,
      connection_type,
      rest_api_id,
      http_method,
      type,
      request_templates,
      timeout_milliseconds,
      resource_id,
    ]
  }
}