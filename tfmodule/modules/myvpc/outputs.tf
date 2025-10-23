output "vpc" {
  value       = aws_vpc.main
}
output "subnets" {
  value       = aws_subnet.subnet
}
output "private_subnets" {
  value       = local.private_subnets
}
output "public_subnets" {
  value       = local.public_subnets
}
