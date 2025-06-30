.PHONY: help validate format init plan apply destroy clean examples

# Default target
help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-15s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

validate: ## Validate Terraform configuration
	@echo "🔍 Validating Terraform configuration..."
	@terraform fmt -check -recursive || (echo "❌ Please run 'make format' first" && exit 1)
	@terraform init -backend=false
	@terraform validate
	@echo "✅ Validation successful"

format: ## Format Terraform files
	@echo "🔧 Formatting Terraform files..."
	@terraform fmt -recursive
	@echo "✅ Formatting complete"

init: ## Initialize Terraform
	@echo "🚀 Initializing Terraform..."
	@terraform init

plan: ## Create Terraform plan
	@echo "📋 Creating Terraform plan..."
	@terraform plan

apply: ## Apply Terraform configuration
	@echo "🚀 Applying Terraform configuration..."
	@terraform apply

destroy: ## Destroy Terraform resources
	@echo "💥 Destroying Terraform resources..."
	@terraform destroy

clean: ## Clean Terraform files
	@echo "🧹 Cleaning Terraform files..."
	@rm -rf .terraform/
	@rm -f .terraform.lock.hcl
	@rm -f terraform.tfstate
	@rm -f terraform.tfstate.backup
	@rm -f *.tfplan
	@echo "✅ Cleanup complete"

examples: ## Validate all examples
	@echo "🔍 Validating examples..."
	@for dir in examples/*/; do \
		if [ -d "$$dir" ]; then \
			echo "Validating $$dir..."; \
			cd "$$dir"; \
			terraform init -backend=false; \
			terraform validate; \
			if [ $$? -ne 0 ]; then \
				echo "❌ $$dir validation failed"; \
				exit 1; \
			fi; \
			cd ../..; \
		fi; \
	done
	@echo "✅ All examples validated successfully"

docs: ## Generate documentation
	@echo "📚 Generating documentation..."
	@if command -v terraform-docs >/dev/null 2>&1; then \
		terraform-docs markdown table --output-file README.md .; \
		echo "✅ Documentation generated"; \
	else \
		echo "❌ terraform-docs not found. Install it from: https://terraform-docs.io/"; \
	fi
