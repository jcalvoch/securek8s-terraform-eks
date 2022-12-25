
data "tls_certificate" "cluster" {
  url = aws_eks_cluster.app.identity.0.oidc.0.issuer
}

data "aws_eks_cluster_auth" "cluster-auth" {
  name = aws_eks_cluster.app.name
  }


data "aws_iam_policy_document" "instance-assume-role-policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "eks-assume-role-policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}




resource "aws_iam_policy" "EKS-Cloudwatch" {
  name = "${var.project_name}-${var.environment}-EKS-Cloudwatch"

  policy = <<EOT
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "Cloudwatch",
            "Effect": "Allow",
            "Action": [
                "cloudwatch:PutMetricData",
                "ec2:DescribeVolumes",
                "ec2:DescribeTags",
                "logs:PutLogEvents",
                "logs:DescribeLogStreams",
                "logs:DescribeLogGroups",
                "logs:CreateLogStream",
                "logs:CreateLogGroup"
            ],
            "Resource": "*"
        },
        {
            "Sid": "SSM",
            "Effect": "Allow",
            "Action": [
                "ssm:GetParameter"
            ],
            "Resource": "arn:aws:ssm:*:*:parameter/AmazonCloudWatch-*"
        }
    ]
}
EOT
}



resource "aws_iam_role" "eks_nodegroup" {
  name                = "${var.project_name}-${var.environment}-eks-nodegroup"
  assume_role_policy  = data.aws_iam_policy_document.instance-assume-role-policy.json
  managed_policy_arns = ["arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy", "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly", "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy", "arn:aws:iam::aws:policy/AmazonSSMPatchAssociation", "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore", aws_iam_policy.EKS-Cloudwatch.arn]
}


resource "aws_iam_openid_connect_provider" "cluster" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.cluster.certificates.0.sha1_fingerprint]
  url             = aws_eks_cluster.app.identity.0.oidc.0.issuer
}


resource "aws_iam_role" "eks_cluster" {
  name                = "${var.project_name}-${var.environment}-eks-cluster"
  assume_role_policy  = data.aws_iam_policy_document.eks-assume-role-policy.json
  managed_policy_arns = ["arn:aws:iam::aws:policy/AmazonEKSClusterPolicy", "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"]
}



module "cluster_autoscaler" {
  source       = "git::https://github.com/rhythmictech/terraform-aws-eks-iam-cluster-autoscaler"
  cluster_name = aws_eks_cluster.app.name
  issuer_url   = aws_eks_cluster.app.identity[0].oidc[0].issuer
}


resource "aws_kms_key" "eks" {
  description             = "KMS key for K8s ETCD secrets encryption"
  deletion_window_in_days = 7

  enable_key_rotation = true

  tags = {
    Name = "${var.project_name}-${var.environment}-kms-eks"
  }
}


resource "aws_eks_cluster" "app" {
  name     = "${var.project_name}-${var.environment}-eks-cluster"
  role_arn = aws_iam_role.eks_cluster.arn

  vpc_config {
    subnet_ids              = var.subnet_ids
    endpoint_public_access  = false
    endpoint_private_access = true
    security_group_ids      = [var.security_group_id]
  }
  enabled_cluster_log_types = ["api", "audit"]
  encryption_config {
    provider {
      key_arn = aws_kms_key.eks.arn
    }
    resources = ["secrets"]
  }

  depends_on = [aws_cloudwatch_log_group.cluster, aws_kms_key.eks]
}


resource "aws_cloudwatch_log_group" "cluster" {
  name              = "/aws/eks/${var.project_name}-${var.environment}-eks-cluster/cluster"
  retention_in_days = 30
}


resource "aws_ecr_repository" "eks" {
  name = "${var.project_name}-${var.environment}-ecr"

  image_scanning_configuration {
    scan_on_push = true
  }
}



resource "aws_ec2_tag" "private_subnet_tag1" {
  resource_id = var.subnet_ids.0
  key         = "kubernetes.io/role/elb"
  value       = "1"
}

resource "aws_ec2_tag" "private_subnet_cluster_tag1" {
  resource_id = var.subnet_ids.0
  key         = "kubernetes.io/cluster/${aws_eks_cluster.app.name}"
  value       = "shared"
}

resource "aws_ec2_tag" "private_subnet_elb_tag1" {
  resource_id = var.subnet_ids.0
  key         = "kubernetes.io/role/internal-elb"
  value       = "1"
}

resource "aws_ec2_tag" "private_subnet_tag2" {
  resource_id = var.subnet_ids.1
  key         = "kubernetes.io/role/elb"
  value       = "1"
}

resource "aws_ec2_tag" "private_subnet_cluster_tag2" {
  resource_id = var.subnet_ids.1
  key         = "kubernetes.io/cluster/${aws_eks_cluster.app.name}"
  value       = "shared"
}

resource "aws_ec2_tag" "private_subnet_elb_tag2" {
  resource_id = var.subnet_ids.1
  key         = "kubernetes.io/role/internal-elb"
  value       = "1"
}
resource "aws_eks_node_group" "ec2" {
  cluster_name    = aws_eks_cluster.app.name
  node_group_name = "${var.project_name}-${var.environment}-eks-nodegroup"
  node_role_arn   = aws_iam_role.eks_nodegroup.arn
  subnet_ids      = var.subnet_ids
  instance_types  = ["t3a.medium"]

  scaling_config {
    desired_size = 2
    max_size     = 6
    min_size     = 2
  }

  update_config {
    max_unavailable = 1
  }

  depends_on = [
    aws_iam_role.eks_nodegroup
  ]
}
