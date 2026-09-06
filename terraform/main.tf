terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Outputs for Architecture Verification
output "vpc_id" {
  value = aws_vpc.devsecops_vpc.id
}

output "web_security_group_id" {
  value = aws_security_group.web_sg.id
}

output "app_security_group_id" {
  value = aws_security_group.app_sg.id
}

output "db_security_group_id" {
  value = aws_security_group.db_sg.id
}

output "iam_instance_profile_name" {
  value = aws_iam_instance_profile.ec2_profile.name
}
