#
# main.tf
#
# This file defines the core infrastructure for the DVWA Security Lab on AWS.
#

# Terraform and Provider Configuration
# ------------------------------------
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      # Using a compatible version of the AWS provider
      version = "~> 6.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  # The AWS region is defined in the variables.tf file
  region = var.aws_region
}

# -----------------------------------------------------------------
# 1. VPC, Subnet, and Network Resources
#    This section creates a new, dedicated VPC for the project.
#    It replaces the dependency on a pre-existing default VPC.
# -----------------------------------------------------------------
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "dvwa-vpc-${var.env_suffix}"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "dvwa-igw-${var.env_suffix}"
  }
}

resource "aws_subnet" "main" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true # Required for a public-facing EC2 instance
  tags = {
    Name = "dvwa-public-subnet-${var.env_suffix}"
  }
}

resource "aws_route_table" "main" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
}

resource "aws_route_table_association" "main" {
  subnet_id      = aws_subnet.main.id
  route_table_id = aws_route_table.main.id
}

# -----------------------------------------------------------------
# 2. Security Group
#    Defines firewall rules for the EC2 instance.
# -----------------------------------------------------------------
# Data source to get your current public IP for SSH access
data "http" "my_ip" {
  url = "http://ipv4.icanhazip.com"
}

resource "aws_security_group" "dvwa_sg" {
  name        = "dvwa-lab-security-group-${var.env_suffix}"
  description = "Security group for DVWA lab, allowing SSH, HTTP, HTTPS"
  # Associate this security group with the new VPC we created above
  vpc_id      = aws_vpc.main.id

  # Inbound Rules (Ingress)
  # Allow SSH from your current public IP only
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    # --- CHANGE: Using response_body instead of the deprecated body ---
    cidr_blocks = ["${chomp(data.http.my_ip.response_body)}/32"]
    description = "Allow SSH from my IP"
  }

  # Allow HTTP access to the DVWA application from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTP access to DVWA"
  }

  # Outbound Rules (Egress)
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

# -----------------------------------------------------------------
# 3. EC2 Instance
#    Defines the compute resource for the DVWA application.
# -----------------------------------------------------------------
resource "aws_instance" "dvwa_server" {
  ami               = var.ami_id
  instance_type     = var.instance_type
  key_name          = var.key_pair_name
  # Assign the instance to our new public subnet
  subnet_id = aws_subnet.main.id
  # Associate the security group with our new instance
  vpc_security_group_ids = [aws_security_group.dvwa_sg.id]

  # --- CHANGE: Using user_data_base64 to match the output of filebase64 ---
  user_data_base64 = filebase64("scripts/user_data.sh")

  tags = {
    Name    = "DVWA-Instance-${var.env_suffix}"
    Project = "Cybersecurity-Lab"
  }
}