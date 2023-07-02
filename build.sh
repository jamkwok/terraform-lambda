#!/bin/bash
echo "Creating ECR if none exists"
cd terraform;
terraform apply -auto-approve -target=aws_ecr_repository.revenue_nsw_ecr; 
cd ..;

echo "Build Lambda Docker Image and push to ECR"
docker build -t revenue_nsw_ecr .
docker tag revenue_nsw_ecr:latest 589079287501.dkr.ecr.ap-southeast-2.amazonaws.com/revenue_nsw_ecr:latest
aws ecr get-login-password --region ap-southeast-2 | docker login --username AWS --password-stdin 589079287501.dkr.ecr.ap-southeast-2.amazonaws.com
docker push 589079287501.dkr.ecr.ap-southeast-2.amazonaws.com/revenue_nsw_ecr:latest