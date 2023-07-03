# terraform-lambda
Terraform for Lambda + ApiGateway 

Step 1: Install Terraform
Terraform v1.5.2
https://developer.hashicorp.com/terraform/downloads

Step 2: Set up AWS credentials and aws CLI.
https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html#getting-started-install-instructions

```bash
# Add AWS keys into the CLI.
aws configure
```

Step 3: Initialise Terraform
```bash
cd terraform
terraform init
```

Step 4: Build Docker and test
```bash
# If you build on an Arm (m1/m2) Mac make sure to docker build using the platform option. Alternatively you can change Lambda to use the arm architecture
docker build -t revenue_nsw_ecr:test .
docker run -p 9000:8080 revenue_nsw_ecr:test
# Curl
curl -XPOST "http://localhost:9000/2015-03-31/functions/function/invocations" -d '{}'
```

Step 5: Run terraform to deploy infrastructure
```bash
cd terraform
terraform apply
# Test using image from ecr 
docker run -p 9000:8080 589079287501.dkr.ecr.ap-southeast-2.amazonaws.com/revenue_nsw_ecr:latest
```

Step 6: Test endpoint. Get this from Apigateway >> API name >> Stage Name >> Invoke URL
```bash
# Example
curl https://amtvoosafi.execute-api.ap-southeast-2.amazonaws.com/test
```