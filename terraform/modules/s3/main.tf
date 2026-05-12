resource "aws_s3_bucket" "audit_log" {
  bucket = "${var.project_name}-audit-log-${var.suffix}"

  tags = merge(var.common_tags, {
    Name    = "${var.project_name}-audit-log"
    Purpose = "drift-audit"
  })
}

resource "aws_s3_bucket_versioning" "audit_log" {
  bucket = aws_s3_bucket.audit_log.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "audit_log" {
  bucket = aws_s3_bucket.audit_log.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
