terraform {
    required_providers {
        aws = {
        source  = "hashicorp/aws"
        version = "~> 3.0"
        }
    }
}

provider "aws" {
    region = "us-east-1"
}

# lambda module
module "lambda" {
    source = "https://github.com/devkinetics/devops-lambda/tree/lambda-mod-test"
    function_name = "lambda-mod-test"
    handler       = "index.lambda_handler"
    lambda_enabled = false
    runtime = "python3.12"
    create_role = true
    source_path = "lambda.zip" # Path to the lambda function code
    environment = {
        variables = {
            S3_BUCKET_NAME = module.rag-s3-bd.bucket_name
            S3_ARN = module.rag-s3-bd.bucket_arn
        }
    }

}

output "s3_bucket_name" {
    value = module.s3_bucket.bucket_name
}

output "s3_bucket_arn" {
    value = module.s3_bucket.bucket_arn
}
#s3 key
output "s3_bucket_key" {
    value = module.s3_bucket.bucket_key
}


# s3 bucket using community module
# private bucket with versioning enabled
module "s3_bucket" {
  source = "terraform-aws-modules/s3-bucket/aws"

  bucket = "rag-s3-bd"
  acl    = "private"

  control_object_ownership = true
  object_ownership         = "ObjectWriter"

  versioning = {
    enabled = true
  }
}