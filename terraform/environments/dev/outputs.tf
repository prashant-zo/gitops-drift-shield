output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_ips" {
  value = module.ec2.public_ips
}

output "audit_bucket" {
  value = module.s3.bucket_name
}

output "security_group_id" {
  value = module.ec2.security_group_id
}
