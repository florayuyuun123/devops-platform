# Terraform — Infrastructure as Code

## Why this matters
Infrastructure as Code means your servers, networks and databases
are defined in files, version-controlled in Git, and reproducible.
Platform engineering teams require this on day one.

---

## Task 1 — Terraform basics
```bash
terraform version
mkdir ~/tf-lab && cd ~/tf-lab
```

## Task 2 — Your first configuration
```bash
cat > main.tf << 'TFEOF'
terraform {
  required_version = ">= 1.0"
}

# Local file provider — practice IaC without a cloud account
resource "local_file" "app_config" {
  filename = "/tmp/app.conf"
  content  = <<-EOT
    PORT=8080
    ENV=production
    VERSION=1.0.0
  EOT
}

resource "local_file" "readme" {
  filename = "/tmp/INFRASTRUCTURE.md"
  content  = "# Infrastructure managed by Terraform\nDo not edit manually."
}
TFEOF

terraform init      # download providers
terraform plan      # preview what will happen
terraform apply     # create the resources
cat /tmp/app.conf   # confirm files were created
```

## Task 3 — Variables and outputs
```bash
cat > variables.tf << 'VAREOF'
variable "app_port" {
  description = "Port the application listens on"
  type        = number
  default     = 8080
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "staging"
}
VAREOF

cat > outputs.tf << 'OUTEOF'
output "config_file_path" {
  description = "Path to the generated config file"
  value       = local_file.app_config.filename
}
OUTEOF

# Update main.tf to use variables
cat > main.tf << 'TFEOF'
terraform {
  required_version = ">= 1.0"
}

resource "local_file" "app_config" {
  filename = "/tmp/app-${var.environment}.conf"
  content  = "PORT=${var.app_port}\nENV=${var.environment}\n"
}
TFEOF

terraform apply -var="environment=production" -var="app_port=9090"
terraform output
```

## Task 4 — State management
```bash
terraform state list          # see all managed resources
terraform state show local_file.app_config
terraform plan                # see drift if files changed
terraform destroy             # destroy everything (be careful)
```

## Task 5 — Modules (reusable components)
```bash
mkdir -p modules/config-file
cat > modules/config-file/main.tf << 'MODEOF'
variable "filename" {}
variable "content"  {}

resource "local_file" "this" {
  filename = var.filename
  content  = var.content
}

output "path" { value = local_file.this.filename }
MODEOF

cat > main.tf << 'ROOTEOF'
module "web_config" {
  source   = "./modules/config-file"
  filename = "/tmp/web.conf"
  content  = "PORT=80\nSERVICE=web\n"
}

module "api_config" {
  source   = "./modules/config-file"
  filename = "/tmp/api.conf"
  content  = "PORT=8080\nSERVICE=api\n"
}
ROOTEOF

terraform init && terraform apply
```

## Challenge
Write a Terraform configuration that creates 5 config files
(web, api, db, cache, queue) using a module. All should be
created with a single `terraform apply`. Commit it to Git.
