#!/bin/bash
echo "Creating ECR if none exists"
cd terraform;
terraform apply -auto-approve -target=aws_ecr_repository.revenue_nsw_ecr; 
cd ..;

echo "Build Lambda Docker Image and push to ECR"
docker build -t docker-image:test .