# Download the official policy document for the Load Balancer Controller
#data "aws_iam_policy_document" "lbc_policy_doc" {
  #  url = "https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/install/iam_policy.json"
  #}

# Create the IAM policy using the downloaded document
resource "aws_iam_policy" "aws_load_balancer_controller" {
  name        = "AWSLoadBalancerControllerIAMPolicy-${var.cluster_name}"
  policy      = file("policy.json")
  #data.aws_iam_policy_document.lbc_policy_doc.json
  description = "IAM policy for AWS Load Balancer Controller"
}

# Create the IAM Role and attach the policy for the Kubernetes Service Account
module "lbc_iam_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name_prefix      = "aws-lbc-${var.cluster_name}"
  attach_load_balancer_controller_policy = true # Uses a predefined policy template
  create_role           = true
  
  # Crucial: Trust policy allowing the K8s Service Account to assume the role
  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }
}

