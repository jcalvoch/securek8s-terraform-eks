output "eks_cluster_name" {
  value = aws_eks_cluster.app.name
}

output "ecr_repo_name" {
  value = aws_ecr_repository.eks.name
}

output "ecr_repo_url" {
  value = aws_ecr_repository.eks.repository_url
}

output "eks_autoscaler_role" {
  value = module.cluster_autoscaler.iam_role_cluster_autoscaler_name
}

output "eks_nodegroup_role" {
  value = aws_eks_node_group.ec2.node_role_arn
}

output "eks_cluster_url" {
  value = aws_eks_cluster.app.endpoint
}

output "eks_cluster_cacertificate" {
  value = base64decode(aws_eks_cluster.app.certificate_authority.0.data)
}

output "eks_cluster_token" {
  value = data.aws_eks_cluster_auth.cluster-auth.token
}

output "eks_oidc_provider_url" {
  value = aws_iam_openid_connect_provider.cluster.url
}