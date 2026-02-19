output "db_endpoint" {
  value = aws_db_instance.this.endpoint
}

output "db_id" {
  value = aws_db_instance.this.id
}

output "db_security_group_id" {
  value = aws_security_group.rds_sg.id
}
