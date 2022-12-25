output "amp_workspaceid" {
  value = aws_prometheus_workspace.workspace.id
}

output "amp_rolearn" {
  value = aws_iam_role.prometheus.arn
}