
resource "aws_vpc" "sp" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  // Allows ECS agent to communicate with cluster
  // by name
  enable_dns_hostnames = true

  tags = {
    Name = "Spaced Reptition VPC"
  }
}

resource "aws_subnet" "sp_1" {
  vpc_id            = aws_vpc.sp.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
}

resource "aws_subnet" "sp_2" {
  vpc_id            = aws_vpc.sp.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"
}

resource "aws_subnet" "sp_3" {
  vpc_id            = aws_vpc.sp.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-1c"
}


resource "aws_internet_gateway" "sp" {
  vpc_id = aws_vpc.sp.id

  tags = {
    Name = "Spaced Repetition gateway"
  }
}

resource "aws_route_table" "sp" {
  vpc_id = aws_vpc.sp.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.sp.id
  }

  tags = {
    Name = "Spaced Reptition subnets route table"
  }
}

resource "aws_route_table_association" "sp_1" {
  subnet_id      = aws_subnet.sp_1.id
  route_table_id = aws_route_table.sp.id
}

resource "aws_route_table_association" "sp_2" {
  subnet_id      = aws_subnet.sp_2.id
  route_table_id = aws_route_table.sp.id
}

resource "aws_route_table_association" "sp_3" {
  subnet_id      = aws_subnet.sp_3.id
  route_table_id = aws_route_table.sp.id
}