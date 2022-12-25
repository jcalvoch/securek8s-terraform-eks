resource "aws_iam_user" "user1" {
  name = var.user_name

}

/*
resource "aws_iam_access_key" "user1" {
  user = aws_iam_user.user1.name
}

*/


resource "aws_iam_policy" "user-eks-full-access" {
  name = "${var.project_name}-${var.environment}--user-eks-full-access"

  policy = <<EOT
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "eks",
            "Effect": "Allow",
            "Action": "eks:*",
            "Resource": "*"
        }
    ]
}
EOT
}




resource "aws_iam_policy" "user-cloudwatch" {
  name = "${var.project_name}-${var.environment}-user-cloudwatch"

  policy = <<EOT
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "Cloudwatch",
            "Effect": "Allow",
            "Action": [
                "cloudwatch:*",
                "logs:*"
            ],
            "Resource": "*"
        }
    ]
}
EOT
}



resource "aws_iam_user_policy_attachment" "user-cloudwatch" {
  user       = aws_iam_user.user1.name
  policy_arn = aws_iam_policy.user-cloudwatch.arn
}


resource "aws_iam_user_policy_attachment" "user-eks-full-access" {
  user       = aws_iam_user.user1.name
  policy_arn = aws_iam_policy.user-eks-full-access.arn
}