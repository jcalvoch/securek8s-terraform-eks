output "private_subnet_ids" {
  value = [aws_subnet.app_privatesubnet1.id, aws_subnet.app_privatesubnet2.id]
}

output "eks_securitygroup_id" {
  value = aws_security_group.eks.id
}

output "app_vpc_id" {
  value = aws_vpc.app.id
}