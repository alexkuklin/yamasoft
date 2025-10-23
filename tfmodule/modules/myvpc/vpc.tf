locals {
 subnets = {
    0 = {
      az = var.az[0]
      public = true,
      octet = 0
    },
    1 = {
      az = var.az[0],
      public = true,
      octet = 1
    },
    2 = {
      az = var.az[0],
      public = false,
      octet = 2
    },
    3 = {
      az = var.az[0],
      public = false,
      octet = 3
    },
    4 = {
      az = var.az[1],
      public = true,
      octet = 4
    },
    5 = {
      az = var.az[1],
      public = true,
      octet = 5
    },
    6 = {
      az = var.az[1],
      public = false,
      octet = 6
    },
    7 = {
      az = var.az[1],
      public = false,
      octet = 7
    },
  }


}

resource "aws_vpc" "main" {
  cidr_block = "172.16.0.0/16"

  enable_dns_support = true
  enable_dns_hostnames = true
}

resource "aws_subnet" "subnet" {
  for_each = local.subnets

  vpc_id            = aws_vpc.main.id
  availability_zone = "${var.region}${each.value.az}" 
  #data.aws_availability_zone.az[each.value.az].name

  cidr_block        = "172.16.${each.value.octet}.0/24"
  map_public_ip_on_launch = each.value.public

}

