# IAM Role for EC2 Instance to Access AWS Secrets Manager (Zero Hardcoded Keys)
resource "aws_iam_role" "ec2_secrets_role" {
  name = "devsecops-ec2-secrets-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# IAM Policy allowing Secrets Manager read access
resource "aws_iam_policy" "secrets_read_policy" {
  name        = "devsecops-secrets-read-policy"
  description = "Grant EC2 access to read application credentials from Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_secrets_policy" {
  role       = aws_iam_role.ec2_secrets_role.name
  policy_arn = aws_iam_policy.secrets_read_policy.arn
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "devsecops-ec2-instance-profile"
  role = aws_iam_role.ec2_secrets_role.name
}
