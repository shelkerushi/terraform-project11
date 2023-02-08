#vpc

resource "aws_vpc" "wolf-vpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "wolf-vpc"
  }
}

#vpc wb subnet

resource "aws_subnet" "wolf-wb-subnet" {
  vpc_id     = aws_vpc.wolf-vpc.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "wolf-wb-subnet"
  }
}

#vpc db subnet

resource "aws_subnet" "wolf-db-subnet" {
  vpc_id     = aws_vpc.wolf-vpc.id
  cidr_block = "10.0.2.0/24"

  tags = {
    Name = "wolf-db-subnet"
  }
}

#Provides a security group resource.

resource "aws_security_group" "wolf-sg" {
  name        = "wolf-sg"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.wolf-vpc.id

  ingress {
    description      = "TLS from VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "wolf-sg"
  }
}

#Provides a resource to create a VPC Internet Gateway.

resource "aws_internet_gateway" "wolf-gw" {
  vpc_id = aws_vpc.wolf-vpc.id

  tags = {
    Name = "wolf-gw"
  }
}

# Provides a resource to create a VPC routing table.

resource "aws_route_table" "wolf-wb-rt" {
  vpc_id = aws_vpc.wolf-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.wolf-gw.id
  }

  tags = {
    Name = "wolf-wb-rt"
  }
}

# Provides a resource to create a VPC routing table.

resource "aws_route_table" "wolf-db-rt" {
  vpc_id = aws_vpc.wolf-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.wolf-natgateway.id
  }

  tags = {
    Name = "wolf-db-rt"
  }
}

# Provides a resource to create an association between a route table and a subnet or a route table and an internet gateway or virtual private gateway.

resource "aws_route_table_association" "wolf-wb-asso" {
  subnet_id      = aws_subnet.wolf-wb-subnet.id
  route_table_id = aws_route_table.wolf-wb-rt.id
}

resource "aws_route_table_association" "wolf-db-asso" {
  subnet_id      = aws_subnet.wolf-db-subnet.id
  route_table_id = aws_route_table.wolf-db-rt.id
}

#Provides an EC2 key pair resource. A key pair is used to control login access to EC2 instances.

resource "aws_key_pair" "wolfkey" {
  key_name   = "wolfkey"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQD5r/om/DoO8W4PoW+03XuSgwIXNiNqZzqa/x6bZ0IRs6N5ihgorpT9iPP6M55sXDOo7JRZzNQGznNxPHmXAURNtUMPPEw/nkimDxihKirfcJL+JufFz4eN4rHdI8oOnUFCC1XJqthbeZfekX+YmpbkHF6jpo8zsocju8eNOT35dzVVzdbYhohFQHBivz87J3h5VFmX8uBbk0S1GvEpq7BgF6UXOSSshRC59ifm6w4YnxwQEnt7MWW25j8GorOjrw9A8RonSIimW7AmRzzsmspIWo/uvbUZe4+LR8HcDcUT1l5F2cpHlGBeEw9MQyoYZryAiQ0213li3rNq9/BHkuX5ZnOTPDKbd7RWUga6AOr/MzXhTQAVozNZHUZfJSWlmzQSoLgQO/HIUNJi0FKpXiovSk/YCJo5TbY2+2OjD0ETaYp7kfv61moKxbpbjOM/YevlKFKjI3mH2vDcaYlLilagMI5015G3SV1gvVjt/sF+AZJw3GNEzpuPBAHM1flIxv0= akki@Akshay"
}

#Provides an EC2 instance resource.

resource "aws_instance" "wolf-web-server" {
  ami           = "ami-00874d747dde814fa"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.wolf-wb-subnet.id
  vpc_security_group_ids = [aws_security_group.wolf-sg.id]
  key_name = "wolfkey"

  tags = {
    Name = "wolf-web-server"
  }
}

resource "aws_instance" "wolf-db-server" {
  ami           = "ami-00874d747dde814fa"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.wolf-db-subnet.id
  vpc_security_group_ids = [aws_security_group.wolf-sg.id]
  key_name = "wolfkey"

  tags = {
    Name = "wolf-db-server"
  }
}

# Provides an Elastic IP resource.

resource "aws_eip" "wolf-ip" {
  instance = aws_instance.wolf-web-server.id
  vpc      = true
}

resource "aws_eip" "wolf-nat-ip" {
  vpc      = true
}

# Provides a resource to create a VPC NAT Gateway.

resource "aws_nat_gateway" "wolf-natgateway" {
  allocation_id = aws_eip.wolf-nat-ip.id
  subnet_id     = aws_subnet.wolf-wb-subnet.id

  tags = {
    Name = "wolf-natgateway"
  }
}

