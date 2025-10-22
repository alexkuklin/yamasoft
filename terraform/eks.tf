module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0" # Use a stable, recent version

  # Mandatory inputs
  cluster_name                   = "test" 
  cluster_version     = "1.34"
  vpc_id                 = module.vpc.vpc_id
  subnet_ids             = module.vpc.private_subnets # EKS control plane ENIs go here

  cluster_endpoint_public_access = true  

  # This grants the Terraform caller user/role admin permissions via a ClusterAccessEntry
  enable_cluster_creator_admin_permissions = true 

  # Define a minimal managed node group for worker nodes
  eks_managed_node_groups = {

    spot_group = {
      name         = "low-priority-spot"
      desired_size = 3
      min_size     = 0
      max_size     = 10
      
      # *** KEY SETTING: Set capacity_type to SPOT ***
      capacity_type = "SPOT" 

      # BEST PRACTICE: Use a mix of compatible instance types for availability
      instance_types = [
        "t3.medium", 
      ]

      # OPTIONAL: Apply a taint so only tolerant Pods schedule here
    }
  }
  cluster_addons = {
    coredns = {
      most_recent                 = true
      resolve_conflicts_on_create = "OVERWRITE"
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent              = true
      service_account_role_arn = aws_iam_role.vpc_cni.arn
    }
  }

  access_entries = {
    # One access entry with a policy associated
    github  = {
      kubernetes_groups = []
      principal_arn     = aws_iam_role.github_actions_role.arn

      policy_associations = {
        admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type       = "cluster"
          }
        }
      }
    }
  }

}

resource "aws_iam_role" "vpc_cni" {
  name               = "vpc-cni"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "${module.eks.oidc_provider_arn}"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "${module.eks.oidc_provider}:sub": "system:serviceaccount:kube-system:aws-node"
        }
      }
    }
  ]
}
EOF
}
resource "aws_iam_role_policy_attachment" "vpc_cni" {
  role       = aws_iam_role.vpc_cni.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"

}

resource "aws_iam_role_policy_attachment" "oidc_agent_attachment" {
  role       =  aws_iam_role.github_actions_role.name
  policy_arn =  "arn:aws:iam::aws:policy/AdministratorAccess"
}

