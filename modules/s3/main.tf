
resource "aws_s3_bucket" "this" {
  bucket = "${var.project_name}-${var.region}" # e.g. reductstore-reductstore-eu-central-1

  tags = {
    Name = "reductstore-data"
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket                  = aws_s3_bucket.this.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}


data "aws_iam_policy_document" "s3_policy" {
  statement {
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject"
    ]
    resources = ["${aws_s3_bucket.this.arn}/*"]
  }
}

resource "aws_iam_role_policy" "s3_access" {
  name   = "${var.project_name}_s3_access"
  role   = var.aws_iam_role_name
  policy = data.aws_iam_policy_document.s3_policy.json
}


resource "aws_iam_user" "s3_user" {
  name = "${var.project_name}_reductstore_user"
  tags = {
    Name = "ReductStore S3 User"
  }
}

resource "aws_iam_user_policy" "s3_access" {
  name = "reductstore_s3_access"
  user = aws_iam_user.s3_user.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:ListBucket"]
        Resource = aws_s3_bucket.this.arn
      },
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
        Resource = "${aws_s3_bucket.this.arn}/*"
      }
    ]
  })
}

resource "aws_iam_access_key" "s3_user_key" {
  user = aws_iam_user.s3_user.name
}
