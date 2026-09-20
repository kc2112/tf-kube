# Internal API Gateway → VPC Link v2 → ALB → EKS

Native AWS provider resources only. No `terraform-aws-modules/*` wrappers.

```
Client (inside the VPC)
        |
        | HTTPS, private DNS
        v
modules/api_gateway     private REST API + Lambda authorizer
        |
        | modules/vpc_link   (VPC Link v2 ENIs)
        v
modules/alb             internal ALB, instance targets, NodePort
        |
        v
modules/eks             managed node group
        |
        v
modules/ingress         Deployment + NodePort Service + Ingress
```

`modules/vpc` and `modules/authorizer` sit under that path.

## Tags

Every AWS resource inherits tags from the root provider. Modules do not declare their own AWS provider.

```hcl
# providers.tf
provider "aws" {
  region = var.aws_region
  default_tags {
    tags = var.default_tags
  }
}
```

```hcl
# terraform.tfvars
default_tags = {
  Project     = "int-api-eks"
  Environment = "dev"
  ManagedBy   = "terraform"
  Stack       = "apigw-vpclink-alb-eks"
}
```

The same map is passed into each module as `tags` and merged onto `Name` (and Kubernetes labels). Resource-level `tags` plus provider `default_tags` both land on the object; matching keys prefer the resource value.

## Layout

```
internal-apigw-eks/
  main.tf providers.tf variables.tf outputs.tf versions.tf
  terraform.tfvars.example
  modules/
    vpc/            VPC, subnets, NAT, routes
    eks/            cluster, node group, add-ons, OIDC, SGs
    alb/            internal ALB, listener, TG, ASG attachment
    vpc_link/       aws_apigatewayv2_vpc_link + ENI SG
    authorizer/     Lambda REQUEST authorizer
    api_gateway/    private REST API, VPCE, VPC Link v2 integration
    ingress/        namespace, Deployment, NodePort Service, Ingress
  k8s/sample-app.yaml
```

## Apply

The Kubernetes provider cannot talk to EKS until the cluster exists.

```bash
cp terraform.tfvars.example terraform.tfvars
# edit default_tags and authorizer_token

terraform init

# 1. AWS only
terraform apply -var='create_k8s_workload=false'

# 2. workload + Ingress
terraform apply -var='create_k8s_workload=true'
```

```bash
eval "$(terraform output -raw configure_kubectl)"
kubectl get deploy,svc,ingress -n apps
```

Invoke only from inside the VPC:

```bash
curl -sS -H "Authorization: Bearer change-me-now" \
  "$(terraform output -raw api_invoke_url)/"
```

A managed node group owns exactly one ASG. The ALB module attaches that ASG with a single `aws_autoscaling_attachment` (no `count`), because `node_group.resources` is unknown at plan time.

## How the hops connect

| Hop | Wiring |
| --- | --- |
| API Gateway → VPC Link | `connection_type = VPC_LINK`, `connection_id = module.vpc_link.vpc_link_id` |
| VPC Link → ALB | `integration_target = module.alb.alb_arn` (VPC Link v2) |
| ALB → EKS | Target group `instance` + `aws_autoscaling_attachment` on the node-group ASG, port `30080` |
| EKS → pods | NodePort Service `30080` → container `80` |

The Ingress object records the route in Kubernetes. It does not create a second ALB; the load balancer is entirely `modules/alb`.

`aws_api_gateway_account` is account-scoped. Remove it from `modules/api_gateway` if another stack already owns the API Gateway CloudWatch role.

Destroy with `terraform destroy`. NAT, EKS, VPC endpoints, and ALBs incur charges while running.
