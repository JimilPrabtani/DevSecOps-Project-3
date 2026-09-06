variable "aws_region" {
  description = "AWS Region where all resources will be deployed (e.g. us-east-1, ap-south-1)"
  type        = string
  default     = "us-east-1"
  # ✏️ CHANGE THIS to the AWS region closest to you
}

variable "environment" {
  description = "Deployment environment label applied to all resource tags"
  type        = string
  default     = "production"
  # ✏️ CHANGE THIS if you want a different label (e.g. dev, staging)
}

variable "vpc_cidr" {
  description = "CIDR block for the main VPC"
  type        = string
  default     = "10.0.0.0/16"
  # Leave as-is unless you have a conflicting VPC CIDR in your AWS account
}

variable "key_pair_name" {
  description = "Name of the EC2 SSH Key Pair to attach to the instance (must already exist in AWS)"
  type        = string
  default     = "devsecops-key"
  # ✏️ CHANGE THIS to the name of the key pair you created with:
  #    aws ec2 create-key-pair --key-name devsecops-key ...
}

variable "my_ip" {
  description = "Your public IP address in CIDR notation — used to restrict SSH access to your machine only"
  type        = string
  default     = "43.241.194.24/32"
  # ✏️ CHANGE THIS to your own IP for security, e.g. "203.0.113.45/32"
  # Find your public IP at: https://checkip.amazonaws.com
}

variable "instance_type" {
  description = "EC2 instance type for the application server"
  type        = string
  default     = "t2.micro"
  # ✏️ CHANGE THIS to t3.small or t3.medium if you need more performance
}

variable "ami_id" {
  description = "AMI ID for Ubuntu Server 22.04 LTS in your chosen region"
  type        = string
  default     = "ami-0c7217cdde317cfec"
  # ✏️ CHANGE THIS if your region is NOT us-east-1.
  # Find the correct Ubuntu 22.04 AMI ID for your region at:
  # https://cloud-images.ubuntu.com/locator/ec2/
  # Search for: ubuntu 22.04 hvm ebs amd64
  #
  # Common region → AMI ID mappings:
  #   us-east-1      : ami-0c7217cdde317cfec
  #   us-west-2      : ami-03f65b8614a860c29
  #   eu-west-1      : ami-0694d931cee176e7d
  #   ap-south-1     : ami-006935d9a6773e4ec
  #   ap-southeast-1 : ami-0fa377108253bf620
}
