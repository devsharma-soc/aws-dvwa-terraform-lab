# outputs.tf

output "dvwa_public_ip" {
  description = "The public IP address of the DVWA EC2 instance."
  value       = aws_instance.dvwa_server.public_ip
}

output "dvwa_url" {
  description = "The URL to access the DVWA web application. Remember to click 'Create/Reset Database' first."
  value       = "http://${aws_instance.dvwa_server.public_ip}/dvwa/setup.php"
}

output "ssh_command" {
  description = "SSH command to connect to the DVWA instance."
  value       = "ssh -i \"${var.key_pair_name}.pem\" ubuntu@${aws_instance.dvwa_server.public_ip}"
}