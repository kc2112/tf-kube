data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

data "aws_iam_openid_connect_provider" "this" {
  url = module.eks.oidc_provider_url
}