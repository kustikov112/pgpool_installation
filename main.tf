provider "aws" {
  region = "eu-central-1"
}

# VPC
resource "aws_vpc" "main_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "main_vpc"
  }
}

# Subnet
resource "aws_subnet" "main_subnet" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "main_subnet"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "main_igw"
  }
}

# Route Table
resource "aws_route_table" "main_rtb" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main_igw.id
  }

  tags = {
    Name = "main_route_table"
  }
}

# Route Table Association
resource "aws_route_table_association" "main_assoc" {
  subnet_id      = aws_subnet.main_subnet.id
  route_table_id = aws_route_table.main_rtb.id
}

# Security Group
resource "aws_security_group" "main_sg" {
  vpc_id = aws_vpc.main_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 5432
    to_port     = 9999
    protocol    = "tcp"
    cidr_blocks = ["10.0.1.0/24"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "main_sg"
  }
}

# EC2 Instance
resource "aws_instance" "my_instance" {
  ami                    = "ami-08ec94f928cf25a9d"  # Be sure to replace this with the latest AMI ID for Amazon Linux 2 in the eu-central-1 region.
  instance_type          = "t3.small"
  subnet_id              = aws_subnet.main_subnet.id
  security_groups        = [aws_security_group.main_sg.name]
  # associate_public_ip_address = true
  key_name = "main_kustikov"

  tags = {
    Name = "MyExampleInstance"
  }

  user_data = <<-EOF
              #!/bin/bash
              sed -i 's/#TCPKeepAlive yes/TCPKeepAlive yes/' /etc/ssh/sshd_config
              sed -i 's/#ClientAliveInterval 0/ClientAliveInterval 120/' /etc/ssh/sshd_config
              systemctl restart sshd
              yum install git tree vim
              
              

              EOF
}
resource "aws_instance" "my_instance_2" {
  ami                    = "ami-08ec94f928cf25a9d"  # Be sure to replace this with the latest AMI ID for Amazon Linux 2 in the eu-central-1 region.
  instance_type          = "t3.small"
  subnet_id              = aws_subnet.main_subnet.id
  security_groups        = [aws_security_group.main_sg.name]
  # associate_public_ip_address = true
  key_name = "main_kustikov"

  tags = {
    Name = "MyExampleInstance_2"
  }

  user_data = <<-EOF
              #!/bin/bash
              sed -i 's/#TCPKeepAlive yes/TCPKeepAlive yes/' /etc/ssh/sshd_config
              sed -i 's/#ClientAliveInterval 0/ClientAliveInterval 120/' /etc/ssh/sshd_config
              systemctl restart sshd
              yum install git tree vim
              
              
              
              EOF
}

resource "aws_instance" "my_instance_3" {
  ami                    = "ami-08ec94f928cf25a9d"  # Be sure to replace this with the latest AMI ID for Amazon Linux 2 in the eu-central-1 region.
  instance_type          = "t3.small"
  subnet_id              = aws_subnet.main_subnet.id
  security_groups        = [aws_security_group.main_sg.name]
  # associate_public_ip_address = true
  key_name = "main_kustikov"

  tags = {
    Name = "MyExampleInstance_3"
  }

  user_data = <<-EOF
              #!/bin/bash
              sed -i 's/#TCPKeepAlive yes/TCPKeepAlive yes/' /etc/ssh/sshd_config
              sed -i 's/#ClientAliveInterval 0/ClientAliveInterval 120/' /etc/ssh/sshd_config
              systemctl restart sshd
              yum install git tree vim
              
              
              
              EOF
}

# output "instance_public_ip" {
#   value = aws_instance.my_instance.public_ip
# }
# output "instance_public_ip_2" {
#   value = aws_instance.my_instance_2.public_ip
# }
# output "instance_public_ip_3" {
#   value = aws_instance.my_instance_3.public_ip
# }