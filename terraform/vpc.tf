# Main VPC Definition
resource "aws_vpc" "devsecops_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "devsecops-3tier-vpc"
    Environment = var.environment
  }
}

# Internet Gateway for Tier 1 Public Subnets
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.devsecops_vpc.id

  tags = {
    Name = "devsecops-igw"
  }
}

# Tier 1: Public Subnets (Web / Nginx / ALB)
resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.devsecops_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = false

  tags = {
    Name = "devsecops-public-subnet-1"
    Tier = "Tier1-Presentation"
  }
}

# Tier 2: Private App Subnets (Flask Application)
resource "aws_subnet" "private_app_1" {
  vpc_id            = aws_vpc.devsecops_vpc.id
  cidr_block        = "10.0.10.0/24"
  availability_zone = "${var.aws_region}a"

  tags = {
    Name = "devsecops-private-app-subnet-1"
    Tier = "Tier2-Application"
  }
}

# Tier 3: Private Database Subnets (MySQL RDS)
resource "aws_subnet" "private_db_1" {
  vpc_id            = aws_vpc.devsecops_vpc.id
  cidr_block        = "10.0.20.0/24"
  availability_zone = "${var.aws_region}a"

  tags = {
    Name = "devsecops-private-db-subnet-1"
    Tier = "Tier3-Database"
  }
}

# Public Route Table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.devsecops_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "devsecops-public-rt"
  }
}

resource "aws_route_table_association" "public_1_assoc" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public_rt.id
}
