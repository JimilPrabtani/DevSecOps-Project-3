# Security Group 1: Tier 1 Presentation Layer (Nginx Web Proxy)
resource "aws_security_group" "web_sg" {
  name        = "devsecops-web-sg"
  description = "Allow inbound HTTP/HTTPS traffic to Nginx reverse proxy"
  vpc_id      = aws_vpc.devsecops_vpc.id

  ingress {
    description = "HTTP Public Access"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS Public Access"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH Access - restricted to your IP (set var.my_ip in variables.tf)"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  egress {
    description = "Allow HTTP/HTTPS Outbound"
    from_port   = 80
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "devsecops-web-sg"
  }
}


# Security Group 2: Tier 2 Application Layer (Flask API)
resource "aws_security_group" "app_sg" {
  name        = "devsecops-app-sg"
  description = "Allow traffic ONLY from Tier 1 Nginx Security Group"
  vpc_id      = aws_vpc.devsecops_vpc.id

  ingress {
    description     = "Flask API Port from Web SG Only"
    from_port       = 5000
    to_port         = 5000
    protocol        = "tcp"
    security_groups = [aws_security_group.web_sg.id]
  }

  egress {
    description = "Allow API/DB Outbound"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "devsecops-app-sg"
  }
}

# Security Group 3: Tier 3 Data Layer (MySQL Database)
resource "aws_security_group" "db_sg" {
  name        = "devsecops-db-sg"
  description = "Allow MySQL traffic ONLY from Tier 2 Application Security Group"
  vpc_id      = aws_vpc.devsecops_vpc.id

  ingress {
    description     = "MySQL Port 3306 from App SG Only"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.app_sg.id]
  }

  egress {
    description = "Allow DB Responses Only"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.0.10.0/24"]
  }

  tags = {
    Name = "devsecops-db-sg"
  }
}
