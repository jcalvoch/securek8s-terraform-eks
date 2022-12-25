data "aws_iam_policy_document" "cert-manager-assume-role-policy" {
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
        "system:serviceaccount:cert-manager:cert-manager"
      ]
    }
  }
}

resource "aws_iam_policy" "cert-manager-policy" {
  name        = "${var.project_name}${var.environment}--cert-manager-policy"
  path        = "/"
  description = "Policy, which allows CertManager to create Route53 records"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : "route53:GetChange",
        "Resource" : "arn:aws:route53:::change/*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "route53:ChangeResourceRecordSets",
          "route53:ListResourceRecordSets"
        ],
        "Resource" : "arn:aws:route53:::hostedzone/${var.route53_zoneid}"
      },
    ]
  })
}

resource "aws_iam_role" "cert-manager" {
  name                = "${var.project_name}-${var.environment}-cert-manager"
  assume_role_policy  = data.aws_iam_policy_document.cert-manager-assume-role-policy.json
  managed_policy_arns = [aws_iam_policy.cert-manager-policy.arn]
}

resource "helm_release" "cert-manager" {
  name             = "cert-manager"
  namespace        = "cert-manager"
  wait             = true
  create_namespace = true
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  values           = [file("${path.module}/cert-manager-values.yaml")]

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.cert-manager.arn
  }

  set {
    name = "installCRDs"
    value = "true"
  }

}



