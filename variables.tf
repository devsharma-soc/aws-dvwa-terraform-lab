# variables.tf

variable "aws_region" {
  description = "The AWS region to deploy resources in."
  type        = string
  default     = "ap-south-1" # Or your preferred region
}

variable "instance_type" {
  description = "The EC2 instance type for DVWA."
  type        = string
  default     = "t2.micro" # Free tier eligible
}

variable "ami_id" {
  description = "The AMI ID for the Ubuntu 22.04 LTS server. Find the latest for your region."
  type        = string
  default = "ami-0f918f7e67a3323f0" # Example for ap-south-1 
}

variable "key_pair_name" {
  description = "The name of the EC2 Key Pair for SSH access."
  type        = string
  default     = "dvwa-key" # Make sure this matches the key pair you created manually in AWS
}

variable "env_suffix" {
  description = "A suffix for resource names to distinguish environments (e.g., 'dev', 'prod')."
  type        = string
  default     = "lab"
}