# main.tf

terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      # Change this line:
      version = "~> 6.0" # This means any version >= 6.0.0 and < 7.0.0
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.0"
    }
  }
}

# Configure the AWS provider
provider "aws" {
  region = var.aws_region
}

# Data source to get the default VPC ID
data "aws_vpc" "default" {
  default = true
}

# Data source to get your current public IP for SSH access
data "http" "my_ip" {
  url = "http://ipv4.icanhazip.com"
}

# Define the Security Group for DVWA
resource "aws_security_group" "dvwa_sg" {
  name        = "dvwa-lab-security-group-${var.env_suffix}"
  description = "Security group for DVWA lab, allowing SSH, HTTP, HTTPS"
  vpc_id      = data.aws_vpc.default.id # Use the default VPC

  # Inbound Rules (Ingress)
  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    # WARNING: This will get your current public IP. If your IP changes, you'll need to re-run 'terraform apply'
    cidr_blocks = ["${chomp(data.http.my_ip.body)}/32"] # Allow SSH from your current public IP
    description = "Allow SSH from my IP"
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow HTTP from anywhere (for DVWA)
    description = "Allow HTTP access to DVWA"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow HTTPS from anywhere (good practice)
    description = "Allow HTTPS access"
  }

  # Outbound Rules (Egress)
  # Allow all outbound traffic (needed for updates, git clone etc.)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # -1 means all protocols
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "DVWA-Security-Group-${var.env_suffix}"
    Project = "Cybersecurity-Lab"
  }
}

# Define the EC2 instance for DVWA
resource "aws_instance" "dvwa_server" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = var.key_pair_name
  vpc_security_group_ids = [aws_security_group.dvwa_sg.id] # Associate the security group

  # User data script to configure DVWA (as discussed previously)
  user_data = filebase64("scripts/user_data.sh") # Reads the script from a file and base64 encodes it

  tags = {
    Name    = "DVWA-Instance-${var.env_suffix}"
    Project = "Cybersecurity-Lab"
  }
}