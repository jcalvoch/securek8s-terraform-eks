data "aws_iam_policy_document" "prometheus-assume-role-policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = ["arn:aws:iam::${var.account_id}:oidc-provider/${replace(var.oidc_provider_url, "https://", "")}"]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(var.oidc_provider_url, "https://", "")}:aud"
      values = [
        "sts.amazonaws.com"
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(var.oidc_provider_url, "https://", "")}:sub"
      values = [
        "system:serviceaccount:prometheus:prometheus"
      ]
    }
  }
}

resource "aws_iam_policy" "prometheus-write-access-policy" {
  name = "AWSManagedPrometheusWriteAccessPolicy"

  policy = <<EOT
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "aps:RemoteWrite",
                "aps:QueryMetrics",
                "aps:GetSeries",
                "aps:GetLabels",
                "aps:GetMetricMetadata"
            ],
            "Resource": "*"
        }
    ]
}
EOT
}

resource "aws_iam_role" "prometheus" {
  name                = "${var.project_name}-${var.environment}-prometheus"
  assume_role_policy  = data.aws_iam_policy_document.prometheus-assume-role-policy.json
  managed_policy_arns = [aws_iam_policy.prometheus-write-access-policy.arn]
}

resource "aws_prometheus_workspace" "workspace" {
  alias = "${var.project_name}-${var.environment}-PrometheusWriteAccessPolicy"
}

