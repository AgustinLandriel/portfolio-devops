resource "aws_s3_bucket" "bucket-state" {
  bucket = "portfolio-devops-state"

  lifecycle {
    prevent_destroy = true
  }

}

resource "aws_s3_bucket_versioning" "bucket-state" {
  bucket = aws_s3_bucket.bucket-state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "bucket-state" {
  bucket = aws_s3_bucket.bucket-state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "bucket-state" {
  bucket = aws_s3_bucket.bucket-state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}


resource "aws_s3_bucket_lifecycle_configuration" "bucket-state" {
  bucket = aws_s3_bucket.bucket-state.id

  rule {
    id     = "Expire old versions"
    status = "Enabled"

    filter {}

    noncurrent_version_expiration {
      noncurrent_days           = 30
      newer_noncurrent_versions = 10
    }
  }
  depends_on = [aws_s3_bucket_versioning.bucket-state]
}
