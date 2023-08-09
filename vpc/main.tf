
resource "aws_vpc" "sp" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  // Allows ECS agent to communicate with cluster
  // by name
  enable_dns_hostnames = true

  tags = {
    Name        = "sp-vpc"
    description = "Spaced repetition VPC"
    owner       = "terraform"
  }
}

resource "aws_subnet" "sp" {
  for_each = {
    us-east-1a = "10.0.1.0/24"
    us-east-1b = "10.0.2.0/24"
    us-east-1c = "10.0.3.0/24"
  }

  vpc_id            = aws_vpc.sp.id
  cidr_block        = each.value
  availability_zone = each.key

  tags = {
    Name  = "sp-subnet"
    owner = "terraform"
  }
}

resource "aws_internet_gateway" "sp" {
  vpc_id = aws_vpc.sp.id

  tags = {
    Name        = "sp-igw"
    owner       = "terraform"
    description = "Internet gateway to allow resources in Spaced Repetition VPC to connect to the public internet."
  }
}

resource "aws_route_table" "sp" {
  vpc_id = aws_vpc.sp.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.sp.id
  }

  tags = {
    Name        = "sp-rtbl"
    description = "Spaced repetitions route table for public subnets"
    owner       = "terraform"
  }
}

resource "aws_route_table_association" "sp" {
  for_each = aws_subnet.sp

  subnet_id      = each.value.id
  route_table_id = aws_route_table.sp.id
}