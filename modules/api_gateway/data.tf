data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "invoke" {
  statement {
    sid       = "AllowInvoke"
    effect    = "Allow"
    actions   = ["execute-api:Invoke"]
    resources = ["${aws_api_gateway_rest_api.this.execution_arn}/*"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }
  }
}