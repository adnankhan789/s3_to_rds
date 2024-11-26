provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "bucket" {
  bucket = "s3-to-rds-bucket-jarvis"
}

resource "aws_ecr_repository" "repo" {
  name = "s3-to-rds"
}

resource "aws_db_instance" "database" {
  allocated_storage    = 20
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t3.micro"
  db_name              = "profession_db"
  username             = "admin"
  password             = "admin123"
  parameter_group_name = "default.mysql8.0"
  skip_final_snapshot  = true
}

resource "aws_lambda_function" "s3_to_rds_function" {
  function_name = "s3_to_rds_lambda"
  role          = aws_iam_role.lambda_exec.arn
  package_type  = "Image"
  image_uri     = "654654486191.dkr.ecr.us-east-1.amazonaws.com/s3-to-rds:latest"

  environment {
    variables = {
      S3_BUCKET    = "s3-to-rds-bucket-jarvis"
      S3_KEY       = "database.csv"
      RDS_HOST     = "terraform-20241124065435848200000001.cvwgs6g8gke4.us-east-1.rds.amazonaws.com"
      RDS_USER     = "admin"
      RDS_PASSWORD = "admin123"
      RDS_DB       = "profession_db"
    }
  }
}

resource "aws_iam_role" "lambda_exec" {
  name = "lambda_exec_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_policy" "lambda_policy" {
  name   = "lambda_policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "rds:*"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}


