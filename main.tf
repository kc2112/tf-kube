

module "vpc" {
  source = "./modules/vpc"

  name       = var.name
  cidr_block = var.vpc_cidr
  az_count   = var.az_count
  cluster_name = var.name
  tags       = var.default_tags
}

module "eks" {
  source = "./modules/eks"

  name                           = var.name
  kubernetes_version             = var.kubernetes_version
  vpc_id                         = module.vpc.vpc_id
  vpc_cidr_block                 = module.vpc.vpc_cidr_block
  private_subnet_ids             = module.vpc.private_subnet_ids
  cluster_endpoint_public_access = var.cluster_endpoint_public_access
  node_instance_types            = var.node_instance_types
  node_desired_size              = var.node_desired_size
  node_min_size                  = var.node_min_size
  node_max_size                  = var.node_max_size
  pod_identity_namespace = var.app_namespace
  pod_identity_service_account   =  var.app_name
  alb_security_group_id          = module.alb.security_group_id
  container_port                 = var.container_port
  tags                           = var.default_tags
  
}

module "vpc_link" {
  source = "./modules/vpc_link"

  name               = var.name
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  tags               = var.default_tags
}

module "alb" {
  source = "./modules/alb"
  name               = var.name
  service_name       = var.app_name
  vpc_id             = module.vpc.vpc_id
  vpc_cidr_block     = module.vpc.vpc_cidr_block
  private_subnet_ids = module.vpc.private_subnet_ids
  container_port      = var.container_port
  cluster_name = module.eks.cluster_name
  aws_region   = var.aws_region
  tags           = var.default_tags
}

module "authorizer" {
  source = "./modules/authorizer"

  name             = var.name
  authorizer_token = var.authorizer_token
  tags             = var.default_tags
}

module "api_gateway" {
  source = "./modules/api_gateway"

  name                     = var.name
  stage_name               = var.api_stage_name
  vpc_id                   = module.vpc.vpc_id
  vpc_cidr_block           = module.vpc.vpc_cidr_block
  private_subnet_ids       = module.vpc.private_subnet_ids
  vpc_link_id              = module.vpc_link.vpc_link_id
  alb_arn                  = module.alb.alb_arn
  alb_dns_name             = module.alb.alb_dns_name
  authorizer_invoke_arn    = module.authorizer.invoke_arn
  authorizer_function_name = module.authorizer.function_name
  container_port           = var.container_port
  tags                     = var.default_tags
}

module "ingress" {
  source = "./modules/ingress"

  create       = var.create_k8s_workload
  namespace    = var.app_namespace
  app_name     = var.app_name
  app_image    = var.app_image
  app_port     = var.app_port
  container_port = var.container_port
  alb_name       = module.alb.alb_name
  alb_dns_name = module.alb.alb_dns_name
  tags         = var.default_tags

  depends_on = [module.eks]
}

# ─────────────────────────────────────────────
# IRSA — AWS Load Balancer Controller
# ─────────────────────────────────────────────
data "aws_iam_policy_document" "aws_lbc_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [module.eks.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${data.aws_iam_openid_connect_provider.this.url}:sub"
      values   = ["system:serviceaccount:kube-system:aws-load-balancer-controller"]
    }

    condition {
      test     = "StringEquals"
      variable = "${data.aws_iam_openid_connect_provider.this.url}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "aws_lbc" {
  name               = "${var.name}-aws-lbc"
  assume_role_policy = data.aws_iam_policy_document.aws_lbc_assume.json
  tags               = var.default_tags
}

resource "aws_iam_policy" "aws_lbc" {
  name        = "AWSLoadBalancerControllerIAMPolicy"
  description = "IAM policy for AWS Load Balancer Controller"
  policy      = file("${path.module}/policies/aws_lbc_policy.json")
  tags        = var.default_tags
}

# Attach the newly created policy to the role
resource "aws_iam_role_policy_attachment" "aws_lbc" {
  role       = aws_iam_role.aws_lbc.name
  policy_arn = aws_iam_policy.aws_lbc.arn  # ← points to the resource above, not AWS managed
}


# ─────────────────────────────────────────────
# Helm — AWS Load Balancer Controller
# ─────────────────────────────────────────────
resource "helm_release" "aws_lbc" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = "1.8.1"

  set = [
    {
      name  = "clusterName"
      value = module.eks.cluster_name
      type  = "string"
    },
    {
      name  = "serviceAccount.create"
      value = "true"
      type  = "string"
    },
    {
      name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
      value = aws_iam_role.aws_lbc.arn
      type  = "string"
    },
    {
      name  = "vpcId"
      value = module.vpc.vpc_id
      type  = "string"
    }
  ]

  depends_on = [module.eks, aws_iam_role_policy_attachment.aws_lbc]
}

