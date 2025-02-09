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
    handler       = "lambda.lambda_handler"
    runtime       = "python3.12"
    role          = aws_iam_role.iam_for_lambda.arn
    timeout = 20

    environment {
        variables = {
            S3_BUCKET = module.s3_bucket.s3_bucket_id
        }
    }
}

data "archive_file" "lambda" {
  type        = "zip"
  source_file = "lambda.py"
  output_path = "lambda.zip"
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

data "aws_iam_policy_document" "s3_access" {
    statement {
        actions   = ["s3:GetObject", "s3:PutObject"]
        resources = ["*"]
    }
}

resource "aws_iam_policy" "lambda_s3_policy" {
    name        = "lambda_s3_policy"
    description = "Allow lambda to access s3"
    policy      = data.aws_iam_policy_document.s3_access.json
  
}

resource "aws_iam_role_policy_attachment" "lambda_s3_attach" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.lambda_s3_policy.arn
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