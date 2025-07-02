# Automated DVWA Security Lab on AWS

## Project Overview

This project provides an automated, secure, and repeatable deployment of the **Damn Vulnerable Web Application (DVWA)** on **Amazon Web Services (AWS)** using **Terraform**. It's designed as a personal cybersecurity lab for learning and practicing web exploitation, penetration testing, and cloud security principles in a controlled environment.

The solution provisions the necessary cloud infrastructure (EC2 instance, Security Groups), configures the Ubuntu Linux server with a LAMP (Linux, Apache, MySQL, PHP) stack, and deploys DVWA, ready for hands-on security testing.

## Features

* **Infrastructure as Code (IaC):** Fully automated infrastructure provisioning managed entirely by Terraform, ensuring consistent and reproducible deployments.
* **AWS Resource Provisioning:** Creates and configures essential AWS resources including:
    * **AWS EC2 Instance:** A dedicated Ubuntu server to host DVWA.
    * **AWS Security Groups:** Network-level firewalls configured to secure access to the EC2 instance, allowing only necessary traffic (SSH, HTTP/S).
* **Automated LAMP Stack Setup:** The EC2 instance automatically installs and configures Apache2, MySQL Server, and PHP with all required extensions upon launch via `user-data` scripting.
* **DVWA Deployment & Configuration:** Clones the DVWA application, configures its `config.inc.php` file with database credentials, and sets appropriate file permissions.
* **MySQL Hardening:** The deployment script includes steps to secure the MySQL database instance, equivalent to running `mysql_secure_installation` (e.g., removing anonymous users, test database, setting strong password policies programmatically).
* **Bash Scripting:** Leverages robust Bash scripting within `user-data` for efficient and automated server-side configuration and application deployment.

## Technologies Used

* **Cloud Provider:** AWS
    * Services: EC2, Security Groups, VPC
* **Infrastructure as Code:** Terraform
* **Operating System:** Ubuntu Linux
* **Web Server:** Apache2
* **Database:** MySQL
* **Scripting:** Bash
* **Version Control:** Git / GitHub
* **Vulnerable Web Application:** DVWA (Damn Vulnerable Web Application)

## Prerequisites

Before deploying this lab, ensure you have the following:

* An **AWS Account** with configured programmatic access (AWS CLI configured with credentials).
* **Terraform CLI** installed on your local machine.
* An **SSH Key Pair** configured in your AWS account and the corresponding private key (`.pem` file) accessible locally.

## Deployment Steps

Follow these steps to deploy your DVWA security lab on AWS:

1.  **Clone the Repository:**
    ```bash
    git clone https://github.com/devsharma-soc/aws-dvwa-terraform-lab.git
    cd aws-dvwa-terraform-lab
    ```

2.  **Review and Customize Variables (if needed):**
    Open `variables.tf` and `main.tf` to review the default configurations. You may need to customize:
    * `aws_region`: The AWS region where you want to deploy (e.g., `us-east-1`).
    * `ami_id`: The Amazon Machine Image (AMI) ID for your Ubuntu instance.
    * `instance_type`: The EC2 instance type (e.g., `t2.micro` for testing).
    * `key_pair_name`: The name of your existing SSH key pair in AWS.

3.  **Configure Database Password (CRITICAL SECURITY STEP):**
    Open `scripts/user_data.sh`. **Locate the line where `DVWA_DB_PASSWORD` is set.**
    **DO NOT HARDCODE YOUR DATABASE PASSWORD IN THIS SCRIPT IF YOU INTEND TO SHARE OR MAKE THE REPO PUBLIC.**
    For a secure deployment, you should:
    * Replace the placeholder with an environment variable reference that you set *before* running Terraform.
    * Or, use AWS Systems Manager Parameter Store or AWS Secrets Manager to retrieve the password securely at runtime.
    * For learning purposes, if you *must* include it, ensure you change it to a strong, unique password immediately after deployment and emphasize that this file is for a *lab environment only*.

    ```bash
    # Example placeholder in user_data.sh - REPLACE OR SECURELY MANAGE THIS!
    DVWA_DB_PASSWORD="<YOUR_DB_PASSWORD_HERE>"
    ```

4.  **Initialize Terraform:**
    This downloads the necessary AWS provider plugins.
    ```bash
    terraform init
    ```

5.  **Review the Deployment Plan:**
    This command shows you exactly what Terraform will create, change, or destroy. Review it carefully.
    ```bash
    terraform plan
    ```

6.  **Apply the Configuration:**
    This command will provision the resources in your AWS account.
    ```bash
    terraform apply
    ```
    Type `yes` when prompted to confirm the deployment.

## Accessing DVWA

Once `terraform apply` completes successfully, Terraform will output the Public IP address of your EC2 instance.

1.  Open your web browser and navigate to:
    `http://<YOUR_EC2_PUBLIC_IP>/dvwa/`
2.  On the DVWA page, click on **"Create / Reset Database"** to initialize the DVWA database and tables.
3.  Log in with the default DVWA credentials:
    * **Username:** `admin`
    * **Password:** `password`
    * (It's recommended to change these immediately if you intend to use the lab for more than quick testing.)

## Security Warning - VERY IMPORTANT!

**This project deploys DVWA, which is by its very nature a Damn Vulnerable Web Application.** It is designed with security flaws for educational purposes.

* **DO NOT deploy this application in a production environment.**
* **DO NOT expose this application to the public internet without strong, additional security controls** (e.g., a Web Application Firewall - WAF, stricter network ACLs, strong authentication proxies, etc.).
* This lab is intended solely for **controlled learning and ethical hacking practice within a secure, isolated environment**.
* Always ensure your `DVWA_DB_PASSWORD` and any other secrets are never hardcoded or pushed to public repositories.

## Future Enhancements

Consider these improvements for further learning and a more robust setup:

* **Remote Terraform State:** Store `terraform.tfstate` in an S3 bucket with DynamoDB locking for team collaboration and state management.
* **Advanced AWS Networking:** Implement a custom VPC with private subnets for database instances and public subnets for web servers, along with NAT Gateways for outbound access.
* **Secrets Management Integration:** Integrate directly with AWS Secrets Manager or Parameter Store within your Terraform code to retrieve all sensitive credentials securely.
* **CI/CD Pipeline:** Automate deployments using a CI/CD service like GitHub Actions or AWS CodePipeline.
* **AWS WAF:** Add an AWS Web Application Firewall (WAF) to protect the DVWA application (even though it's vulnerable, learning WAF is valuable).
* **Logging and Monitoring:** Configure CloudWatch Logs for Apache access logs and system logs, and set up CloudWatch Alarms for suspicious activities.

## Author

**Dev Sharma**
* \[LinkedIn Profile\](https://www.linkedin.com/in/devsharma-soc/)
* \[GitHub Profile\](https://github.com/devsharma-soc)

## License

This project is open-sourced under the [e.g., MIT License]. See the `LICENSE` file for more details.