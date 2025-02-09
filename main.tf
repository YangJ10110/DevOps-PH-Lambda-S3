terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.70"
    }
  }
}

provider "aws" {
    region = "us-east-1"
}

# lambda module

resource "aws_lambda_function" "lambda" {
    function_name = "rag-lambda"
    filename = "lambda.zip"
    handler       = "lambda_function.lambda_handler"
    runtime       = "python3.12"
    role          = aws_iam_role.iam_for_lambda.arn

    environment {
        variables = {
            S3_BUCKET = module.s3_bucket.s3_bucket_id
        }
    }
}

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

resource "aws_iam_role" "iam_for_lambda" {
  name               = "iam_for_lambda"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
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