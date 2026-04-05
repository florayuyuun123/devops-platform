# Terraform — Infrastructure as Code (IaC)

In the old days, if you needed a server, you had to click a hundred buttons in the AWS or Azure console. With **Terraform**, you simply write a text file describing the server you want, and Terraform builds it for you. This is "Infrastructure as Code."

---

## Task 1 — The Concept of State

### The Concept (What)
Terraform uses a **State File** to keep track of every resource it has created. When you change your code, Terraform compares it to the state file and only changes what is necessary.

### Real-world Context (Why)
If you have 10,000 servers, you cannot remember which ones you created or what their settings are. Terraform's state file is the "Single Source of Truth" that prevents you from accidentally deleting your company's infrastructure.

### Execution (How)
Check your version and prepare your workspace.

```bash
terraform version
```

```bash
mkdir -p ~/tf-lab && cd ~/tf-lab
```

---

## Task 2 — Your First Configuration (The "Plan")

### The Concept (What)
We use `.tf` files to define our resources. `terraform init` downloads the tools, `terraform plan` shows you what will happen, and `terraform apply` actually does the work.

### Real-world Context (Why)
In DevOps, we **NEVER** run `apply` without looking at the `plan` first. The plan tells you exactly what Terraform is about to do, preventing catastrophic mistakes before they happen.

### Execution (How)
Create a small configuration that manages a local file (this is how we practice without needing an AWS account).

```bash
cat > main.tf << 'TFEOF'
terraform {
  required_version = ">= 1.0"
}

resource "local_file" "app_config" {
  filename = "/tmp/app.conf"
  content  = "PORT=8080\nENV=production\nVERSION=1.0.0"
}
TFEOF
```

```bash
terraform init
```

```bash
terraform plan
```

```bash
terraform apply -auto-approve
```

```bash
cat /tmp/app.conf
```

---

## Task 3 — Variables & Outputs

### The Concept (What)
**Variables** allow you to reuse your code for different environments (Development vs. Production). **Outputs** show you the final results of your work (like a server's IP address).

### Real-world Context (Why)
You don't want to copy-paste the same 1,000 lines of code for your "Testing" and "Production" clusters. You write the code once and use Variables to change the settings for each.

### Execution (How)
Add variables and outputs to your project.

```bash
cat > variables.tf << 'VAREOF'
variable "app_port" {
  type    = number
  default = 8080
}

variable "environment" {
  type    = string
  default = "staging"
}
VAREOF
```

```bash
cat > outputs.tf << 'OUTEOF'
output "config_file_path" {
  value = local_file.app_config.filename
}
OUTEOF
```

**Run it with custom variables:**
```bash
terraform apply -var="environment=production" -var="app_port=9090" -auto-approve
```

---

## Task 4 — Infrastructure Modules

### The Concept (What)
A **Module** is a reusable "package" of Terraform code.

### Real-world Context (Why)
If your company has 50 teams that all need a "Web Server," you write one perfect "Web Server Module" and share it with everyone. This ensures everyone follows the same security standards.

### Execution (How)
Create a reusable module and call it twice.

```bash
mkdir -p modules/config-file
```

```bash
cat > modules/config-file/main.tf << 'MODEOF'
variable "filename" {}
variable "content"  {}
resource "local_file" "this" {
  filename = var.filename
  content  = var.content
}
MODEOF
```

```bash
cat > main.tf << 'ROOTEOF'
module "web_config" {
  source   = "./modules/config-file"
  filename = "/tmp/web.conf"
  content  = "PORT=80\n"
}

module "api_config" {
  source   = "./modules/config-file"
  filename = "/tmp/api.conf"
  content  = "PORT=8080\n"
}
ROOTEOF
```

```bash
terraform init && terraform apply -auto-approve
```

---

## Challenge
Run `terraform destroy` and then check if the files in `/tmp` still exist. This is the most powerful (and dangerous) command in DevOps—it deletes everything your code created in one go!
