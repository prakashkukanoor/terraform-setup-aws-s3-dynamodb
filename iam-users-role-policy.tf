# IAM policy to allow Get and Update access to S3 bucket and DynamoDB table
resource "aws_iam_policy" "read_update_policy_users" {
  name        = "s3-dynamodb-read-update-policy"
  path        = "${var.iam_path_users}"
  tags = local.comman_tags
  description = "Policy to allow Get and Update access to S3 bucket and DynamoDB table"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ],
        "Resource" : [
          "arn:aws:s3:::${var.bucket_name}",
          "arn:aws:s3:::${var.bucket_name}/*"
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:Query",
          "dynamodb:UpdateItem",
          "dynamodb:Scan"
        ],
        "Resource" : "arn:aws:dynamodb:*:*:table/${var.dynamodb_table_name}"
      }
    ]
  })
}

# IAM role that users can assume
resource "aws_iam_role" "user_role" {
  name = "s3-dynamodb-user-role"
  path = "${var.iam_path_users}"
  tags = local.comman_tags
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : { "Service" : "ec2.amazonaws.com" },
        "Action" : "sts:AssumeRole"
      }
    ]
  })
}

# Attach policy to the IAM role
resource "aws_iam_role_policy_attachment" "attach_users_policy_to_role" {
  role       = aws_iam_role.user_role.name
  policy_arn = aws_iam_policy.read_update_policy_users.arn
}

# IAM group for users needing S3 and DynamoDB read/update access
resource "aws_iam_group" "user_group" {
  name = "s3-dynamodb-user-group"
  path = "${var.iam_path_users}"
  
}

# Attach the read-update policy to the IAM group
resource "aws_iam_group_policy_attachment" "attach_users_policy_to_group" {
  group      = aws_iam_group.user_group.name
  policy_arn = aws_iam_policy.read_update_policy_users.arn
}

# Create IAM users and add them to the group
resource "aws_iam_user" "users" {
  for_each = toset(var.users)
  name     = each.key
  path     = "${var.iam_path_users}"
  tags = local.comman_tags
}

# Add users to the IAM group
resource "aws_iam_user_group_membership" "user_group_list" {
  for_each = aws_iam_user.users
  user     = each.value.name
  groups   = [aws_iam_group.user_group.name]
}

# Optional: Create access keys for each user (ensure secure storage)
resource "aws_iam_access_key" "user_keys" {
  for_each = aws_iam_user.users
  user     = each.key
}

# Output access keys and secrets (sensitive output for security)
output "user_access_keys" {
  value = {
    for user, key in aws_iam_access_key.user_keys : user => {
      access_key_id     = key.id
      secret_access_key = key.secret
    }
  }
  sensitive = true
}

# Generate CSV file with user access keys
resource "local_file" "user_keys_csv" {
  content = <<-EOF
    UserName,AccessKeyId,SecretAccessKey
    %{ for user, key in aws_iam_access_key.user_keys }
    ${user},${key.id},${key.secret}
    %{ endfor }
  EOF

  filename = "${path.module}/user_access_keys.csv"
}