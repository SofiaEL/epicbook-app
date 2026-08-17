# 🚀 EpicBook — Full DevOps Deployment (Terraform + Ansible + App)
Déploiement complet de l’application EpicBook dans une architecture 3‑tier comprenant :

Infrastructure AWS provisionnée via Terraform

Configuration & déploiement automatisés via Ansible

Application EpicBook (Frontend React + Backend Node.js)

Base de données MySQL (RDS)

Reverse proxy Nginx

CI/CD GitHub Actions

Ce projet démontre un workflow DevOps complet : IaC + Configuration Management + App Deployment + Security + Automation + Documentation.

# 📌 Overview
Ce dépôt contient :

infra-epicbook-main/ → Infrastructure Terraform + Ansible

app-epicbook-main/ → Application EpicBook (frontend + backend)

README.md → Documentation DevOps complète

L’objectif est de déployer une architecture production‑ready sur AWS, entièrement automatisée.

# 🏗️ Architecture Globale

Code
User → Nginx (Port 80)
        ↓
Node.js API (Port 8080)
        ↓
RDS MySQL (Private Subnet)
🔹 3‑Tier Architecture
Tier 1 — Frontend : React + Nginx

Tier 2 — Backend : Node.js / Express

Tier 3 — Database : MySQL (AWS RDS)

# ⚙️ Tech Stack
Terraform (IaC)

Ansible (Configuration & App Deployment)

AWS : EC2, RDS, VPC, IGW, Route Tables, S3, DynamoDB

Node.js / PM2

React.js

Nginx

MySQL

GitHub Actions (CI/CD)

Linux (Ubuntu)

📁 Structure du Dépôt

```
epicbook-app/
├── infra-epicbook-main/
│   ├── backend.tf
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── terraform.tfvars
│   ├── ansible/
│   │   ├── inventory.ini
│   │   ├── site.yml
│   │   └── roles/
│   │       ├── common/
│   │       ├── frontend/
│   │       ├── backend/
│   │       └── mysql/
│   └── infra-pipelines.yml
│
├── app-epicbook-main/
│   ├── frontend/
│   │   ├── public/
│   │   ├── src/
│   │   ├── package.json
│   │   └── README.md
│   │
│   └── backend/
│       ├── src/
│       ├── config/
│       ├── package.json
│       └── README.md
│
└── README.md
```


# 🧱 1. Infrastructure — Terraform

🔹 Provisioning AWS
Terraform crée automatiquement :

VPC 10.0.0.0/16

Public subnet → EC2

Private subnets → RDS MySQL

Internet Gateway

Route tables

Security groups

Backend S3 + DynamoDB

🔹 Commandes
bash
terraform init
terraform plan
terraform apply -auto-approve
🔹 Outputs
Terraform expose :

IP publique EC2

Endpoint RDS

Ports ouverts

Credentials dynamiques

# ⚙️ 2. Configuration & Déploiement — Ansible
Une fois les VM provisionnées, Ansible configure les serveurs et déploie l’application.

🔹 Inventory
ini
[frontend]
<EC2_PUBLIC_IP> ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/id_rsa

[backend]
<EC2_PUBLIC_IP> ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/id_rsa

[mysql]
<RDS_ENDPOINT> ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/id_rsa
🔹 Playbook principal : site.yml
yaml
- hosts: mysql
  become: yes
  roles:
    - mysql

- hosts: backend
  become: yes
  roles:
    - common
    - backend

- hosts: frontend
  become: yes
  roles:
    - common
    - frontend
🔹 Roles Ansible
✔ Role mysql
Création DB

Import du schéma

Seed data

✔ Role backend
Installation Node.js

Installation dépendances

Configuration config.json

Service PM2

Connexion à RDS

✔ Role frontend
Installation Nginx

Build React

Reverse proxy vers backend

Gestion des erreurs

# ⚡ 3. Automatisation EC2 — user_data.sh
Le script automatise :

Installation Node.js, Nginx, MySQL client

Clone du repo GitHub

Configuration DB

Attente de disponibilité RDS

Import du schéma

Démarrage Node.js via PM2

Configuration Nginx reverse proxy

# 🔄 4. CI/CD — GitHub Actions
Le pipeline infra-pipelines.yml automatise :

✔ Terraform
fmt

init

validate

plan

apply

✔ Ansible
Vérification SSH

Déploiement complet

✔ Logs & Notifications
Logs détaillés

Statut du déploiement

# 🧠 Challenges & Fixes
| Issue | Fix |
| --- | --- |
| AMI not found | Utilisation du bon owner ID |
| RDS AZ error | Création de subnets Multi‑AZ |
| 403 Nginx | Correction du reverse proxy |
| DB connection refused | Mise à jour de ``config.json`` |
| Dynamic IP issue | Utilisation du data source HTTP |
| State management | Backend S3 + DynamoDB |


# 🎯 Outcome

✔ Infrastructure automatisée

✔ Architecture sécurisée

✔ Déploiement applicatif complet

✔ Setup DB automatisé

✔ Environnement production‑ready

✔ Documentation DevOps claire

# 🚀 Future Improvements

Load Balancer (ALB)

HTTPS (ACM)

Auto Scaling Group

CI/CD complet App + Infra

AWS Secrets Manager

🔗 Repository

https://github.com/SofiaEL/epicbook-app
