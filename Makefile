SHELL := /bin/bash

ansible-playbook: ## Run Ansible playbook
	@ansible-playbook --inventory ansible/hosts.yml ansible/site.yml

packer-k8s-control-plane-build: ## Build K8s Control Plane Packer image
	@cd packer/k8s/control-plane && make build

packer-k8s-etcd-build: ## Build K8s Etcd Packer image
	@cd packer/k8s/etcd && make build

packer-k8s-load-balancer-build: ## Build K8s Load Balancer Packer image
	@cd packer/k8s/load-balancer && make build

packer-k8s-worker-build: ## Build K8s Worker Packer image
	@cd packer/k8s/worker && make build

terraform-k8s-apply: ## Plan K8s Terraform
	@cd terraform/k8s && terraform apply

terraform-k8s-fmt: ## Format K8s Terraform code
	@cd terraform/k8s && terraform fmt -recursive .

terraform-k8s-init: ## Initialize K8s Terraform
	@cd terraform/k8s && terraform init

terraform-k8s-plan: ## Plan K8s Terraform
	@cd terraform/k8s && terraform plan

.PHONY: ansible-playbook terraform-fmt

.DEFAULT_GOAL := help
help: Makefile
	@grep -E '(^[a-zA-Z_-]+:.*?##.*$$)|(^##)' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[32m%-30s\033[0m %s\n", $$1, $$2}' | sed -e 's/\[32m## /[33m/'
