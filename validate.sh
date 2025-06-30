#!/bin/bash

# Terraform validation and formatting script

echo "🔍 Checking Terraform formatting..."
terraform fmt -check -recursive

if [ $? -ne 0 ]; then
    echo "❌ Terraform files are not properly formatted. Running terraform fmt..."
    terraform fmt -recursive
else
    echo "✅ All Terraform files are properly formatted"
fi

echo ""
echo "🔍 Validating Terraform configuration..."

# Validate main module
echo "Validating main module..."
terraform init -backend=false
terraform validate

if [ $? -eq 0 ]; then
    echo "✅ Main module validation passed"
else
    echo "❌ Main module validation failed"
    exit 1
fi

# Validate examples
for example_dir in examples/*/; do
    if [ -d "$example_dir" ]; then
        echo ""
        echo "Validating $example_dir..."
        cd "$example_dir"
        terraform init -backend=false
        terraform validate
        
        if [ $? -eq 0 ]; then
            echo "✅ $example_dir validation passed"
        else
            echo "❌ $example_dir validation failed"
            cd - > /dev/null
            exit 1
        fi
        cd - > /dev/null
    fi
done

echo ""
echo "🎉 All validations passed!"
