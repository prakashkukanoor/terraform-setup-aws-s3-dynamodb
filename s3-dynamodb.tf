# Create S3 bucket with delete protection, versioning, and encryption enabled
resource "aws_s3_bucket" "tf_statefile_bucket" {
  bucket = var.bucket_name
  acl    = "private"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  lifecycle_rule {
    id      = "prevent_delete"
    enabled = true
  }

  tags = local.comman_tags
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.tf_statefile_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 Bucket Policy to allow specific IAM role to create, read, and write access while denying delete
resource "aws_s3_bucket_policy" "tf_statefile_bucket_policy" {
  bucket = aws_s3_bucket.tf_statefile_bucket.id

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : "${aws_iam_role.restricted_admin_role.arn}"
        },
        "Action" : [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket",
          "s3:PutBucketPolicy",
          "s3:PutObjectAcl"
        ],
        "Resource" : [
          "arn:aws:s3:::${var.bucket_name}",
          "arn:aws:s3:::${var.bucket_name}/*"
        ]
      },
      {
        "Effect" : "Deny",
        "Principal" : "*",
        "Action" : [
          "s3:DeleteBucket",
          "s3:DeleteObject"
        ],
        "Resource" : [
          "arn:aws:s3:::${var.bucket_name}",
          "arn:aws:s3:::${var.bucket_name}/*"
        ]
      }
    ]
  })
}

# Create DynamoDB table with deletion protection enabled
resource "aws_dynamodb_table" "tf_state_lock_table" {
  name         = var.dynamodb_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  # Enable Point-in-Time Recovery (deletion protection)
  point_in_time_recovery {
    enabled = true
  }
}