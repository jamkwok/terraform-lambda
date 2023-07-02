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
docker build -t revenue_nsw_ecr:test .
docker run -p 9000:8080 revenue_nsw_ecr:test
curl -XPOST "http://localhost:9000/2015-03-31/functions/function/invocations" -d '{}'
```
