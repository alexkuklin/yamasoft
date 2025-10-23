resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route" "public_internet_gateway" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gw.id
}

resource "aws_route_table_association" "public" {
  for_each       = local.public_subnets
  subnet_id      = aws_subnet.subnet[each.key].id
  route_table_id = aws_route_table.public.id
}

resource "aws_eip" "nat" {
  for_each   = local.public_subnets
}

resource "aws_nat_gateway" "main" {
  for_each      = local.public_subnets
  allocation_id = aws_eip.nat[each.key].allocation_id
  subnet_id     = aws_subnet.subnet[each.key].id
  depends_on    = [aws_internet_gateway.gw, aws_eip.nat]
}

resource "aws_route_table" "private" {
  for_each = local.private_subnets
  vpc_id   = aws_vpc.main.id
}

resource "aws_route" "private_nat_gateway" {
  for_each               = aws_route_table.private
  route_table_id         = each.value.id
  destination_cidr_block = "0.0.0.0/0"
  # The NAT GW is selected based on the subnet index/key
  nat_gateway_id         = aws_nat_gateway.main[tonumber(each.key)-2].id
}
#
#resource "aws_route_table_association" "private" {
#  for_each       = local.private_subnets
#    subnet_id      = each.value.id
#  route_table_id = aws_route_table.private[each.key].id
#}
