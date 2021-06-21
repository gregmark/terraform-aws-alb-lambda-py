# ./s3.txt

resource "random_pet" "pet" {
  length = 1
}

resource "random_uuid" "uuid" {}

locals {
  s3_random = "${random_pet.pet.id}-${random_uuid.uuid.result}"
}

resource "aws_s3_bucket" "alp_s3" {
  bucket        = var.s3_access_logs != null ? var.s3_access_logs : local.s3_random
  force_destroy = true
  acl           = "log-delivery-write"
  tags          = var.tags
}

resource "aws_s3_bucket_policy" "alp_s3_policy" {
  bucket = aws_s3_bucket.alp_s3.id
  policy = templatefile("${path.module}/files/alb-access-logs-s3-policy.json.tmpl", {
    account = data.aws_caller_identity.current.account_id,
    s3      = aws_s3_bucket.alp_s3.bucket,
    elb_id  = data.aws_elb_service_account.main.id
  })
}

data "aws_caller_identity" "current" {
}

data "aws_elb_service_account" "main" {
  region = var.region
}
