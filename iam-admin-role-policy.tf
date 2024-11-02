# Define IAM policy to allow create, read, and write but deny delete on S3 and DynamoDB
resource "aws_iam_policy" "restricted_admin_policy" {
  name        = "${var.resource_name}-policy"
  path        = "${var.iam_path_admins}"
  description = "Allows create, read, and write access to specific S3 and DynamoDB resources but denies delete actions"
  tags = local.comman_tags

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:CreateBucket",
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:PutBucketPolicy",
          "s3:PutBucketAcl",
          "s3:GetBucketPolicy",
          "s3:GetBucketAcl"
        ],
        "Resource" : [
          "arn:aws:s3:::${var.bucket_name}",
          "arn:aws:s3:::${var.bucket_name}/*"
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "dynamodb:CreateTable",
          "dynamodb:UpdateTable",
          "dynamodb:DescribeTable",
          "dynamodb:Query",
          "dynamodb:Scan",
          "dynamodb:GetItem",
          "dynamodb:PutItem"
        ],
        "Resource" : "arn:aws:dynamodb:*:*:table/${var.dynamodb_table_name}"
      },
      {
        "Effect" : "Deny",
        "Action" : [
          "s3:DeleteBucket",
          "s3:DeleteObject"
        ],
        "Resource" : [
          "arn:aws:s3:::${var.bucket_name}",
          "arn:aws:s3:::${var.bucket_name}/*"
        ]
      },
      {
        "Effect" : "Deny",
        "Action" : [
          "dynamodb:DeleteTable",
          "dynamodb:DeleteItem"
        ],
        "Resource" : "arn:aws:dynamodb:*:*:table/${var.dynamodb_table_name}"
      }
    ]
  })
}

# Define IAM Role with the restricted policy and specific path
resource "aws_iam_role" "restricted_admin_role" {
  name = "${var.resource_name}-role"
  path = "${var.iam_path_admins}"
  tags = local.comman_tags

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "ec2.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })
}

# Attach restricted policy to IAM role
resource "aws_iam_role_policy_attachment" "attach_policy_to_role" {
  role       = aws_iam_role.restricted_admin_role.name
  policy_arn = aws_iam_policy.restricted_admin_policy.arn
}

# Define IAM group for users who need the restricted role access
resource "aws_iam_group" "restricted_admin_group" {
  name = "${var.resource_name}-admins-group"
  path = "${var.iam_path_admins}"
}

# Attach the restricted policy to the IAM group
resource "aws_iam_group_policy_attachment" "attach_admins_policy_to_group" {
  group      = aws_iam_group.restricted_admin_group.name
  policy_arn = aws_iam_policy.restricted_admin_policy.arn
}

# Create IAM users and add them to the restricted admin group
resource "aws_iam_user" "admins" {
  for_each = toset(var.admin_users)
  name     = each.key
  path     = "${var.iam_path_admins}"
  tags = local.comman_tags
}

# Attach each user to the IAM group
resource "aws_iam_user_group_membership" "user_group_membership" {
  for_each = aws_iam_user.admins
  user     = each.value.name
  groups   = [aws_iam_group.restricted_admin_group.name]
}

# Create access keys for each user
resource "aws_iam_access_key" "admin_keys" {
  for_each = aws_iam_user.admins
  user     = each.key
}

# Output access keys and secrets for each user (store securely!)
output "admin_user_access_keys" {
  value = {
    for user, key in aws_iam_access_key.admin_keys : user => {
      access_key_id     = key.id
      secret_access_key = key.secret
    }
  }
  sensitive = true
}

# Generate CSV file with user access keys
resource "local_file" "admin_keys_csv" {
  content = <<-EOF
    UserName,AccessKeyId,SecretAccessKey
    %{ for user, key in aws_iam_access_key.admin_keys }
    ${user},${key.id},${key.secret}
    %{ endfor }
  EOF

  filename = "${path.module}/admin_access_keys.csv"
}
