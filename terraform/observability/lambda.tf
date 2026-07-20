# Lambda dispatcher — transforma el webhook de Alertmanager en el mismo
# payload que sao-platform/lambda-dispatcher usa para EventBridge, y lo
# reenvía a MCP_SERVER_URL/incident si está configurado.
data "archive_file" "dispatcher" {
  type        = "zip"
  source_file = "${path.module}/../../lambda-alertmanager-dispatcher/dispatcher.py"
  output_path = "${path.module}/../../lambda-alertmanager-dispatcher/dispatcher.zip"
}

resource "aws_iam_role" "dispatcher" {
  name = "saga-alertmanager-dispatcher"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })

  tags = { Name = "saga-alertmanager-dispatcher" }
}

resource "aws_iam_role_policy_attachment" "dispatcher_basic" {
  role       = aws_iam_role.dispatcher.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "dispatcher" {
  function_name    = "saga-alertmanager-dispatcher"
  role             = aws_iam_role.dispatcher.arn
  filename         = data.archive_file.dispatcher.output_path
  source_code_hash = data.archive_file.dispatcher.output_base64sha256
  runtime          = "python3.12"
  handler          = "dispatcher.handler"
  timeout          = 15

  environment {
    variables = {
      MCP_SERVER_URL  = var.mcp_server_url
      AWS_ACCOUNT_ID  = data.aws_caller_identity.current.account_id
    }
  }

  tags = { Name = "saga-alertmanager-dispatcher" }
}

resource "aws_cloudwatch_log_group" "dispatcher" {
  name              = "/aws/lambda/${aws_lambda_function.dispatcher.function_name}"
  retention_in_days = 3
}
