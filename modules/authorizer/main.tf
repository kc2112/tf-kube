

resource "aws_iam_role" "this" {
  name = "${var.name}-authorizer"
  tags = var.tags

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "logs" {
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/lambda/${var.name}-authorizer"
  retention_in_days = 14
  tags              = var.tags
}

resource "aws_lambda_function" "this" {
  function_name    = "${var.name}-authorizer"
  role             = aws_iam_role.this.arn
  filename         = data.archive_file.this.output_path
  source_code_hash = data.archive_file.this.output_base64sha256
  handler          = "index.handler"
  runtime          = "python3.12"
  timeout          = 8
  memory_size      = 256
  tags             = merge(var.tags, { Name = "${var.name}-authorizer" })

  environment {
    variables = {
      EXPECTED_TOKEN = var.authorizer_token
    }
  }

  depends_on = [aws_cloudwatch_log_group.this]
}
