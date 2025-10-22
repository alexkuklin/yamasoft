# Requires the Kubernetes and Helm providers to be configured
# with the EKS cluster credentials (usually via the EKS module outputs).

provider "kubernetes" {
  config_path = "~/.kube/config"
}

# Create the Kubernetes Service Account used by the LBC Pods
resource "kubernetes_service_account" "aws_load_balancer_controller" {
  metadata {
    name      = "aws-load-balancer-controller"
    namespace = "kube-system"
    annotations = {
      # CRITICAL: Link the K8s SA to the AWS IAM Role (IRSA)
      "eks.amazonaws.com/role-arn" = module.lbc_iam_role.iam_role_arn
    }
  }
}

## Deploy the AWS Load Balancer Controller using the Helm Chart
#resource "helm_release" "aws_load_balancer_controller" {
#  name       = "aws-load-balancer-controller"
#  repository = "https://aws.github.io/eks-charts"
#  chart      = "aws-load-balancer-controller"
#  namespace  = "kube-system"
#  version    = "1.8.1" # Check for the latest stable version
#
#  # Ensure the service account is created before the Helm release attempts to use it
#  depends_on = [kubernetes_service_account.aws_load_balancer_controller]
#
#  set =[ {
#    name  = "clusterName"
#    value = var.cluster_name
#  },
#
#  {
#    name  = "serviceAccount.create"
#    value = "false" # Use the SA created above
#  },
#
#  {
#    name  = "serviceAccount.name"
#    value = kubernetes_service_account.aws_load_balancer_controller.metadata[0].name
#  } ]
#}
