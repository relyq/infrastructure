output "api-public_ip" {
  value = aws_instance.api_server.public_ip

  lifecycle {
    replace_triggered_by = [ aws_instance.api_server.public_ip ]
  }
}

output "frontend-public_ip" {
  value = aws_instance.frontend_server.public_ip

  lifecycle {
    replace_triggered_by = [ aws_instance.frontend_server.public_ip ]
  }
}