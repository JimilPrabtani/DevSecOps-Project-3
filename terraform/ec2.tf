# EC2 Instance — Application Server (3-Tier Deployment Host)
resource "aws_instance" "app_server" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  monitoring             = true
  ebs_optimized          = true
  subnet_id              = aws_subnet.public_1.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  key_name               = var.key_pair_name
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "disabled"
  }

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  # Bootstrap: Install Docker automatically on first boot
  user_data = <<-EOF
    #!/bin/bash
    apt-get update -y
    apt-get install -y docker.io docker-compose-plugin git
    systemctl start docker
    systemctl enable docker
    usermod -aG docker ubuntu
  EOF

  tags = {
    Name        = "devsecops-app-server"
    Environment = var.environment
    Tier        = "All-Tiers-Host"
  }
}

# Output the public IP so you can SSH in right after terraform apply
output "ec2_public_ip" {
  value       = aws_instance.app_server.public_ip
  description = "Public IP of your EC2 instance — use this to SSH in and open the app in your browser"
}
