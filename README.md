# Terraform Lambda Deployment with S3 Backend

## GitHub Actions Workflow

### Steps to Deploy Changes
This repository is integrated with GitHub Actions to automate Lambda deployment. Follow these steps to make changes and trigger the deployment:

1. **Modify the Python Lambda function** (`lambda.py`).
2. **Commit the changes** using Git:
   ```sh
   git add lambda.py
   git commit -m "Updated Lambda function"
   git push origin test
   ```
3. Once pushed to the `test` branch, the GitHub Actions workflow will:
   - Zip the `lambda.py` file.
   - Initialize Terraform.
   - Taint the Lambda function (forcing an update).
   - Apply the Terraform changes.
   
## Setting Up Terraform Backend and Local Deployment

### 1. Creating the Backend
Terraform uses an S3 backend to store the state file. The following resource defines the backend:
```hcl
backend "s3" {
    bucket = "rag-terraform-state-1"
    key    = "terraform.tfstate"
    region = "us-west-1"
}
```

### 2. Provisioning Locally
Before using the backend, initialize Terraform locally:
```sh
tf init
terraform apply -auto-approve
```
This provisions the necessary AWS resources, including S3, IAM roles, and Lambda.

### 3. Migrating to the Remote Backend
Once everything is set up locally, uncomment the backend configuration and migrate the state:
```sh
tf init -migrate-state
```
This transfers the local state to the S3 bucket.

## Lambda with S3 Integration
### 1. Creating and Archiving the Lambda Code
Before deploying, the Lambda function needs to be zipped. Terraform will handle this using the `archive_file` data source:
```hcl
data "archive_file" "lambda" {
  type        = "zip"
  source_file = "lambda.py"
  output_path = "lambda.zip"
}
```

### 2. Defining the Lambda Function
The Lambda function is configured to access an S3 bucket via environment variables:
```hcl
resource "aws_lambda_function" "lambda" {
    function_name = "rag-lambda"
    filename      = "lambda.zip"
    handler       = "lambda.lambda_handler"
    runtime       = "python3.12"
    role          = aws_iam_role.iam_for_lambda.arn
    timeout       = 20
    source_code_hash = filebase64sha256("lambda.zip")

    environment {
        variables = {
            S3_BUCKET = module.s3_bucket.s3_bucket_id
        }
    }
}
```

### 3. IAM Role for Lambda
Lambda requires an IAM role with appropriate permissions.

#### **Assume Role Policy**
The assume role policy allows AWS services (like Lambda) to assume this IAM role:
```hcl
data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}
```
> **Explanation:** This policy allows the AWS Security Token Service (STS) to grant Lambda temporary credentials to execute actions.

#### **S3 Access Policy**
The Lambda function needs permission to interact with S3:
```hcl
data "aws_iam_policy_document" "s3_access" {
    statement {
        actions   = ["s3:GetObject", "s3:PutObject", "s3:ListBucket"]
        resources = ["*"]
    }
}
```

#### **Attaching Policy to Role**
The access policy is then attached to the IAM role:
```hcl
resource "aws_iam_role_policy_attachment" "lambda_s3_attach" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.lambda_s3_policy.arn
}
```

By following these steps, the Lambda function will be deployed with the appropriate permissions to interact with an S3 bucket. 🚀

### Debugging AWS Resources After Provisioning
To verify successful provisioning, run the following AWS CLI commands:

- **IAM Role Verification**
  ```sh
  aws iam get-role --role-name rag-lambda-role
  ```
- **S3 Bucket Verification**
  ```sh
  aws s3 ls s3://rag-terraform-state-1
  ```
- **Lambda Function Verification**
  ```sh
  aws lambda get-function --function-name rag-lambda
  ```

