resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
}


resource "aws_nat_gateway" "natgw" {
  for_each = local.private_subnets
  #  allocation_id = aws_eip.example.id
  subnet_id     = aws_subnet.subnet[each.key].id

  depends_on = [aws_internet_gateway.gw]
}
