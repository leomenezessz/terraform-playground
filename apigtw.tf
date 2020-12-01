# API Gateway Configuration

resource "aws_api_gateway_rest_api" "OrdersAPI" {
  name        = "OrdersAPI"
  description = "Simple orders API"
}

# Resources

resource "aws_api_gateway_resource" "OrdersResource" {
  rest_api_id = aws_api_gateway_rest_api.OrdersAPI.id
  parent_id   = aws_api_gateway_rest_api.OrdersAPI.root_resource_id
  path_part   = "orders"
}

resource "aws_api_gateway_resource" "CreateOrderResource" {
  rest_api_id = aws_api_gateway_rest_api.OrdersAPI.id
  parent_id   = aws_api_gateway_rest_api.OrdersAPI.root_resource_id
  path_part   = "order"
}

# Methods

resource "aws_api_gateway_method" "GetOrdersMethod" {
  rest_api_id          = aws_api_gateway_rest_api.OrdersAPI.id
  resource_id          = aws_api_gateway_resource.OrdersResource.id
  http_method          = "GET"
  authorization        = "COGNITO_USER_POOLS"
  authorizer_id        = aws_api_gateway_authorizer.api-auth.id
  authorization_scopes = aws_cognito_resource_server.resource.scope_identifiers
}

resource "aws_api_gateway_method" "CreateOrderMethod" {
  rest_api_id          = aws_api_gateway_rest_api.OrdersAPI.id
  resource_id          = aws_api_gateway_resource.CreateOrderResource.id
  http_method          = "POST"
  authorization        = "COGNITO_USER_POOLS"
  authorizer_id        = aws_api_gateway_authorizer.api-auth.id
  authorization_scopes = aws_cognito_resource_server.resource.scope_identifiers
}

# API Gateway Integrations x Lambda Integration

resource "aws_api_gateway_integration" "OrdersIntegration" {
  rest_api_id             = aws_api_gateway_rest_api.OrdersAPI.id
  resource_id             = aws_api_gateway_resource.OrdersResource.id
  http_method             = aws_api_gateway_method.GetOrdersMethod.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.orders_lambda.invoke_arn
}


resource "aws_api_gateway_integration" "OrderIntegration" {
  rest_api_id             = aws_api_gateway_rest_api.OrdersAPI.id
  resource_id             = aws_api_gateway_resource.CreateOrderResource.id
  http_method             = aws_api_gateway_method.CreateOrderMethod.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.order_lambda.invoke_arn
}

# Deployment

resource "aws_api_gateway_deployment" "OrdersAPIDeployment" {
  depends_on  = [aws_api_gateway_integration.OrdersIntegration, aws_api_gateway_integration.OrderIntegration]
  rest_api_id = aws_api_gateway_rest_api.OrdersAPI.id
  stage_name  = "dev"
}

# API Gateway Lambda Invoke Permission

resource "aws_lambda_permission" "apigw_lambda_orders" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.orders_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execute-api:${var.region}:${var.account_id}:${aws_api_gateway_rest_api.OrdersAPI.id}/*/${aws_api_gateway_method.GetOrdersMethod.http_method}${aws_api_gateway_resource.OrdersResource.path}"
}

resource "aws_lambda_permission" "apigw_lambda_order" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.order_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execute-api:${var.region}:${var.account_id}:${aws_api_gateway_rest_api.OrdersAPI.id}/*/${aws_api_gateway_method.CreateOrderMethod.http_method}${aws_api_gateway_resource.CreateOrderResource.path}"
}

# API Gateway Authorizer

resource "aws_api_gateway_authorizer" "api-auth" {
  name          = "CognitoUserPoolAuthorizer"
  type          = "COGNITO_USER_POOLS"
  rest_api_id   = aws_api_gateway_rest_api.OrdersAPI.id
  provider_arns = ["arn:aws:cognito-idp:${var.region}:${var.account_id}:userpool/${aws_cognito_user_pool.orders.id}"]
}

