# API Gateway HTTP API — endpoint público que Alertmanager (dentro del
# cluster) usa para entregar el webhook. HTTP API en vez de REST API: más
# barato y simple, no necesitamos ninguna feature exclusiva de REST API acá.
resource "aws_apigatewayv2_api" "alertmanager" {
  name          = "saga-alertmanager-webhook"
  protocol_type = "HTTP"

  tags = { Name = "saga-alertmanager-webhook" }
}

resource "aws_apigatewayv2_integration" "dispatcher" {
  api_id                 = aws_apigatewayv2_api.alertmanager.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.dispatcher.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "webhook" {
  api_id    = aws_apigatewayv2_api.alertmanager.id
  route_key = "POST /alertmanager-webhook"
  target    = "integrations/${aws_apigatewayv2_integration.dispatcher.id}"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.alertmanager.id
  name        = "$default"
  auto_deploy = true
}

resource "aws_lambda_permission" "apigateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.dispatcher.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.alertmanager.execution_arn}/*/*"
}
