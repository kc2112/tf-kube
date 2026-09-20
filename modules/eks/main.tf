data "aws_eks_cluster" "this" {
  name = aws_eks_cluster.this.name
}

locals {
  eks_service_role_arn = "arn:aws:iam::774552523771:role/aws-service-role/eks.amazonaws.com/AWSServiceRoleForAmazonEKS"
}

# ── Security Groups ────────────────────────────────────────────────────────────

resource "aws_security_group" "cluster" {
  name        = "${var.name}-eks-cluster"
  description = "EKS control plane"
  vpc_id      = var.vpc_id
  tags        = merge(var.tags, { Name = "${var.name}-eks-cluster" })
}

resource "aws_security_group" "nodes" {
  name        = "${var.name}-eks-nodes"
  description = "EKS worker nodes"
  vpc_id      = var.vpc_id
  tags        = merge(var.tags, { Name = "${var.name}-eks-nodes" })
}

resource "aws_vpc_security_group_ingress_rule" "cluster_from_nodes_https" {
  security_group_id            = aws_security_group.cluster.id
  description                  = "Nodes to API server"
  referenced_security_group_id = aws_security_group.nodes.id
  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "cluster_all" {
  security_group_id = aws_security_group.cluster.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_vpc_security_group_ingress_rule" "nodes_from_cluster" {
  security_group_id            = aws_security_group.nodes.id
  description                  = "Control plane to kubelet / extension APIs"
  referenced_security_group_id = aws_security_group.cluster.id
  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "nodes_from_cluster_kubelet" {
  security_group_id            = aws_security_group.nodes.id
  description                  = "Control plane to kubelet"
  referenced_security_group_id = aws_security_group.cluster.id
  from_port                    = 10250
  to_port                      = 10250
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "nodes_from_self" {
  security_group_id            = aws_security_group.nodes.id
  description                  = "Node to node"
  referenced_security_group_id = aws_security_group.nodes.id
  ip_protocol                  = "-1"
}

resource "aws_vpc_security_group_ingress_rule" "nodes_from_alb" {
  security_group_id            = aws_security_group.nodes.id
  description                  = "ALB to pods on container port"
  referenced_security_group_id = var.alb_security_group_id   # pass in from ALB module output
  from_port                    = var.container_port
  to_port                      = var.container_port
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "cluster_sg_from_alb" {
  security_group_id            = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
  description                  = "ALB to pods on container port"
  referenced_security_group_id = var.alb_security_group_id
  from_port                    = var.container_port
  to_port                      = var.container_port
  ip_protocol                  = "tcp"
}


resource "aws_vpc_security_group_egress_rule" "nodes_all" {
  security_group_id = aws_security_group.nodes.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# ── Cluster IAM Role ───────────────────────────────────────────────────────────

resource "aws_iam_role" "cluster" {
  name = "${var.name}-eks-cluster"
  tags = var.tags

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "eks.amazonaws.com" }
      Action    = ["sts:AssumeRole", "sts:TagSession"]
    }]
  })
}

resource "aws_iam_role_policy_attachment" "cluster_eks" {
  role       = aws_iam_role.cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "cluster_vpc" {
  role       = aws_iam_role.cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
}

# ── Auto Mode Node IAM Role ────────────────────────────────────────────────────

resource "aws_iam_role" "auto_nodes" {
  name = "${var.name}-auto-nodes"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "auto_nodes_minimal" {
  role       = aws_iam_role.auto_nodes.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodeMinimalPolicy"
}

# ✅ ADDED — was referenced in depends_on but missing from config
resource "aws_iam_role_policy_attachment" "auto_nodes_ecr" {
  role       = aws_iam_role.auto_nodes.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPullOnly"
}


resource "aws_iam_instance_profile" "auto_nodes" {
  name = "${var.name}-auto-nodes"
  role = aws_iam_role.auto_nodes.name

  tags = var.tags
}

# ── EKS Cluster ────────────────────────────────────────────────────────────────

resource "aws_eks_cluster" "this" {
  name     = var.name
  role_arn = aws_iam_role.cluster.arn
  version  = var.kubernetes_version

  bootstrap_self_managed_addons = false

  compute_config {
    enabled       = true
    node_pools    = ["general-purpose", "system"]
    node_role_arn = aws_iam_role.auto_nodes.arn
  }

  storage_config {
    block_storage { enabled = true }
  }

  kubernetes_network_config {
    elastic_load_balancing { enabled = true }
  }

  vpc_config {
    subnet_ids              = var.private_subnet_ids
    security_group_ids      = [aws_security_group.cluster.id]
    endpoint_private_access = true
    endpoint_public_access  = var.cluster_endpoint_public_access
  }

  access_config {
    authentication_mode                         = "API"
    bootstrap_cluster_creator_admin_permissions = true
  }

  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  tags = merge(var.tags, { Name = var.name })

  depends_on = [
    aws_iam_role_policy_attachment.cluster_eks,
    aws_iam_role_policy_attachment.cluster_vpc,
    aws_iam_role_policy_attachment.auto_nodes_minimal,
    aws_iam_role_policy_attachment.auto_nodes_ecr
  ]
}

resource "aws_eks_pod_identity_association" "cloudwatch_agent" {
  cluster_name    = var.name
  namespace       = "amazon-cloudwatch"
  service_account = "cloudwatch-agent"
  role_arn        = aws_iam_role.cloudwatch_agent.arn
}

resource "aws_eks_addon" "cloudwatch_observability" {
  cluster_name             = var.name
  addon_name               = "amazon-cloudwatch-observability"
  addon_version            = "v6.6.0-eksbuild.1"  # use latest available version
  service_account_role_arn = aws_iam_role.cloudwatch_agent.arn
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  # Enable OTel Container Insights (recommended) + Classic Container Insights
  configuration_values = jsonencode({
    containerInsights = {
      enabled = true
    }
    otelContainerInsights = {
      enabled = true
    }
  })

  depends_on = [
    aws_eks_pod_identity_association.cloudwatch_agent
  ]
}

# ── Access ─────────────────────────────────────────────────────────────────────

resource "aws_iam_role" "cloudwatch_agent" {
  name = "EKS-CloudWatch-Observability-Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "pods.eks.amazonaws.com"
        }
        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
      }
    ]
  })
}





resource "aws_iam_role_policy_attachment" "cloudwatch_agent_policy" {
  role       = aws_iam_role.cloudwatch_agent.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_eks_access_policy_association" "kurt_iam_admin" {
  cluster_name  = aws_eks_cluster.this.name   # ✅ use reference not hardcoded string
  principal_arn = "arn:aws:iam::774552523771:user/kurt-iam"
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_cluster.this]
}

# ── Pod Identity ───────────────────────────────────────────────────────────────

# ✅ REMOVED aws_eks_addon "pod_identity" — built into Auto Mode, and
#    depended on aws_eks_node_group.this which no longer exists

resource "aws_iam_role" "pod_identity" {
  name = "${var.name}-pod-identity"
  tags = merge(var.tags, { Name = "${var.name}-pod-identity" })

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "AllowEksAuthToAssumeRoleForPodIdentity"
      Effect = "Allow"
      Principal = {
        Service = "pods.eks.amazonaws.com"
      }
      Action = [
        "sts:AssumeRole",
        "sts:TagSession",
      ]
    }]
  })
}

resource "aws_eks_pod_identity_association" "app" {
  cluster_name    = aws_eks_cluster.this.name
  namespace       = var.pod_identity_namespace
  service_account = var.pod_identity_service_account
  role_arn        = aws_iam_role.pod_identity.arn
  tags            = var.tags

  depends_on = [aws_eks_cluster.this]   # ✅ no longer depends on deleted add-on
}

# ── OIDC Provider ──────────────────────────────────────────────────────────────

resource "aws_iam_openid_connect_provider" "eks" {
  url             = aws_eks_cluster.this.identity[0].oidc[0].issuer
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.oidc.certificates[0].sha1_fingerprint]
  tags            = merge(var.tags, { Name = "${var.name}-eks-oidc" })
}

resource "aws_iam_role_policy_attachment" "eks_compute_policy" {
  role       = aws_iam_role.cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSComputePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_block_storage_policy" {
  role       = aws_iam_role.cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSBlockStoragePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_load_balancing_policy" {
  role       = aws_iam_role.cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSLoadBalancingPolicy"
}

resource "aws_iam_role_policy_attachment" "eks_networking_policy" {
  role       = aws_iam_role.cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSNetworkingPolicy"
}