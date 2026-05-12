output "instance_ids" { value = aws_instance.app[*].id }
output "public_ips" { value = aws_instance.app[*].public_ip }
output "security_group_id" { value = aws_security_group.app.id }
