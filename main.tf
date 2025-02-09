terraform {
    required_providers {
        aws = {
        source  = "hashicorp/aws"
        version = "~> 3.0"
        }
    }
}

provider "aws" {
    region = "us-west-2"
}

# lambda module
module "lambda" {
    source = "https://github.com/devkinetics/devops-lambda/tree/lambda-mod-test"
    function_name = "lambda-mod-test"
    handler       = "index.lambda_handler"
    lambda_enabled = false
    runtime = "python3.12"
    create_role = true
    source_path = "lambda" # Path to the lambda function code


}

# s3 bucket using community module