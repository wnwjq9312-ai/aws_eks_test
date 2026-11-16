terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region  = "ap-northeast-2"
  profile = "admin_user"
}

# AWS S3 Bucket 생성
resource "aws_s3_bucket" "terraform_state" {
  bucket = "myterraform-bucket-state-wnwjq9312-ai"

  tags = {
    Name = "terraform_state"
  }

  lifecycle {
    prevent_destroy = true
  }

  force_destroy = false
}

# AWS KMS Key 생성
resource "aws_kms_key" "terraform_state_kms" {
  description             = "terraform_state_kms"
  deletion_window_in_days = 7
}

# S3 서버 측 암호화 설정
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state_sec" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.terraform_state_kms.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

# S3 버전 관리 활성화
resource "aws_s3_bucket_versioning" "terraform_state_ver" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

# DynamoDB 상태 잠금 테이블
resource "aws_dynamodb_table" "terraform_locks" {
  name         = "myTerraform-bucket-lock-wnwjq9312-ai"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}