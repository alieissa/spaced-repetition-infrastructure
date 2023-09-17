data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}
resource "aws_security_group" "x_ec2" {
  vpc_id = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol    = "TCP"
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "sp_auth" {
  key_name   = "sp-auth"
  public_key = file("/root/.aeissa/id_rsa_aws.pub")
}
data "aws_subnet" "eni_sb" {
  vpc_id     = var.vpc_id
  cidr_block = "10.0.1.0/24"
}

resource "aws_instance" "x_ec2" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t3.micro"
  key_name                    = aws_key_pair.sp_auth.key_name
  associate_public_ip_address = true
  subnet_id                   = data.aws_subnet.eni_sb.id

  vpc_security_group_ids = [aws_security_group.x_ec2.id]
}