.PHONY: help init plan apply destroy drift-check lint test

ENVIRONMENT ?= dev
TF_DIR = terraform/environments/$(ENVIRONMENT)

help:
	@echo "GitOps Drift Shield — Available commands:"
	@echo "  make init        Init Terraform for environment (default: dev)"
	@echo "  make plan        Run terraform plan"
	@echo "  make apply       Run terraform apply"
	@echo "  make destroy     Destroy all AWS resources"
	@echo "  make drift-check Run drift detector manually"

init:
	cd $(TF_DIR) && terraform init

plan:
	cd $(TF_DIR) && terraform plan

apply:
	cd $(TF_DIR) && terraform apply -auto-approve

destroy:
	cd $(TF_DIR) && terraform destroy -auto-approve
