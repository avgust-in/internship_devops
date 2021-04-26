#---------------------------------------------------------------------
# AVG Terrafotm
#
# Build Web server
#---------------------------------------------------------------------


provider "aws" {
  region = "us-east-2"
}
# Create VPC
resource "aws_vpc" "AVG_Ubuntu_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "AVG Ubuntu VPC"
  }
}
# Create internet_gateway
resource "aws_internet_gateway" "AVG_Ubuntu_IG" {
  vpc_id = aws_vpc.AVG_Ubuntu_vpc.id

  tags = {
    Name = "AVG Ubuntu IG"
  }
}
# Create LAN
resource "aws_route_table" "AVG_Ubuntu_LAN" {
  vpc_id = aws_vpc.AVG_Ubuntu_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.AVG_Ubuntu_IG.id
  }

  tags = {
    Name = "AVG_Ubuntu_LAN"
  }
}
# Create Subnet
resource "aws_subnet" "AVG_Ubuntu_SN" {
  vpc_id                  = aws_vpc.AVG_Ubuntu_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-2a"
  map_public_ip_on_launch = "true"

  tags = {
    Name = "AVG Ubuntu SN"
  }
}

resource "aws_route_table_association" "AVG_Ubuntu_association" {
  subnet_id      = aws_subnet.AVG_Ubuntu_SN.id
  route_table_id = aws_route_table.AVG_Ubuntu_LAN.id
}

# Create security group
resource "aws_security_group" "AVG_Ubuntu_SG" {
  name        = "AVG_Ubuntu_SG"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.AVG_Ubuntu_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "AVG Ubuntu SG"
  }
}

# Create ec2 instance
resource "aws_instance" "AVG_Ubuntu" {
  #  count                  = 1
  ami                    = "ami-08962a4068733a2b6" # Ubuntu 20.04
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.AVG_Ubuntu_SN.id
  vpc_security_group_ids = [aws_security_group.AVG_Ubuntu_SG.id]
  key_name               = "avgustKey"

  tags = {
    Name = "AVG Ubuntu Instance"
  }
}


# wrote instance IP in hosts.txt
output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.AVG_Ubuntu.public_ip
}
resource "local_file" "AVG_Ubuntu" {
  content  = "[stage_server_avgust]\n ${aws_instance.AVG_Ubuntu.public_ip}"
  filename = "./deploy_nginx/hosts.txt"
}
# make playbook
resource "null_resource" "AVG_Ubuntu" {
  triggers = {
    content = "${local_file.AVG_Ubuntu.content}"
  }
  provisioner "local-exec" {
    command = "sleep 15 && cd deploy_nginx && ansible-playbook playbook.yml"
  }
}

# make s3 to save server state
resource "aws_s3_bucket" "AVG_Ubuntu_bucket" {
  bucket = "avg-server-state"
  acl    = "private"

  tags = {
    Name        = "AVG bucket"
    Environment = "Dev"
  }
}

# Lookup to server state
terraform {
  backend "s3" {
    bucket  = "avg-server-state"
    key     = "AVG/create_ec2+nginx/terraform.tfstate"
    region  = "us-east-2"
    encrypt = true
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}
