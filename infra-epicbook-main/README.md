# EpicBook Infrastructure Pipeline (Stage 1)

This repository is the first stage of a dual-pipeline deployment for EpicBook.

- Stage 1 (this repo): provisions Azure infrastructure with Terraform and publishes deployment outputs.
- Stage 2 (app deployment repo): consumes these outputs and deploys/configures the application with Ansible.

## Complete Deployment Guide

Use the full end-to-end guide here:

- https://docs.google.com/document/d/1cN-SRPxDvwvN3i20Hu63nqW5EJbXcBA0WdS6nTUKVq0/edit?usp=sharing

## What Stage 1 Provisions

Terraform in this repo creates:

- Resource Group
- Virtual Network and subnets (web + delegated DB subnet)
- Network Security Group (SSH + HTTP)
- Public IP and NIC for the VM
- Linux VM with SSH key-based access (password auth disabled)
- Azure MySQL Flexible Server (private access)
- MySQL database
- Private DNS zone and VNet link for DB name resolution

## Why DB Password Is Not Hardcoded

`db_password` is intentionally not committed in source control.

Security design:

- The pipeline imports secrets from Azure DevOps variable group `epicbook-secrets`.
- It exports the secret into Terraform runtime only via environment variable:
  - `TF_VAR_db_password="$(db_password)"`
- Terraform reads that value through variable `db_password` (`sensitive = true`).

This keeps credentials out of Git history and out of plain text IaC files.

## Repository File Structure

```text
infra-epicbook/
  .gitignore                # Ignore terraform state, plans, and local artifacts
  .terraform.lock.hcl       # Provider dependency lock file
  azure-pipelines.yml       # Azure DevOps CI/CD pipeline for Stage 1 infra deploy
  backend.tf                # Remote backend config (Azure Storage state)
  main.tf                   # Core Azure infrastructure resources
  outputs.tf                # Terraform outputs consumed by Stage 2
  terraform.tfvars          # Non-secret input values (region, names, sizing)
  variables.tf              # Input variable definitions, including sensitive db_password
```

## Terraform Configuration Overview

### `main.tf`

- Declares providers (`azurerm`, `random`, `local`) and version constraints.
- Creates networking, VM, MySQL flexible server, and database resources.
- Uses SSH public key authentication on VM (`disable_password_authentication = true`).

### `variables.tf`

Defines input parameters for location, naming, VM sizing, SSH key path, and DB settings.

- `db_password` is marked sensitive and expected at runtime.

### `terraform.tfvars`

Stores non-secret defaults like:

- `location`
- `resource_prefix`
- `vm_size`
- `admin_username`
- `public_key`
- `db_name`
- `db_user`

No real DB password is stored here.

### `outputs.tf`

Exports runtime outputs used by Stage 2:

- `public_ip`
- `db_host`
- `admin_user`

### `backend.tf`

Configures remote Terraform state in Azure Storage (`azurerm` backend) so state is centralized and pipeline-safe.

## Pipeline Flow (`azure-pipelines.yml`)

The Stage 1 Azure DevOps pipeline executes these steps:

1. Trigger on pushes to `main`.
2. Checkout the repository.
3. Download SSH public key secure file (`id_rsa.pub`).
4. Install required tooling (`unzip`, `curl`, Terraform binary).
5. Prepare SSH public key under `~/.ssh` for Terraform VM provisioning.
6. Run Terraform Init through `AzureCLI@2` with ARM auth env vars.
7. Run Terraform Plan (`-out=tfplan`).
8. Run Terraform Apply (`-auto-approve tfplan`).
9. Read Terraform outputs (`public_ip`, `db_host`) and write artifact file:
   - `infra-outputs.env`
   - keys emitted: `vmPublicIp`, `db_host`
10. Publish artifact `infra-outputs` for downstream pipeline consumption.

## Stage 1 to Stage 2 Handoff Contract

This pipeline publishes artifact `infra-outputs` containing:

```env
vmPublicIp=<public VM IP>
db_host=<mysql fqdn>
```

Stage 2 pipeline downloads this file and injects these values at runtime to:

- build Ansible inventory using `vmPublicIp`
- configure app/database connectivity using `db_host`

## How to Run (Pipeline-Centric)

Recommended path is Azure DevOps pipeline execution, not local apply.

Required in Azure DevOps before run:

- Service connection: `azure-devops-connection`
- Variable group: `epicbook-secrets` with secret `db_password`
- Secure file: `id_rsa.pub`

## Notes and Good Practices

- Never commit credentials into `terraform.tfvars`.
- Keep `db_password` only in secret storage.
- Keep output names stable (`vmPublicIp`, `db_host`) to avoid breaking Stage 2.
- Preserve remote backend configuration consistency to avoid state drift.