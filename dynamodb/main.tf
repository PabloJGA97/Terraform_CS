provider "aws" {
  region = "us-east-1"
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name = "name"
    #values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
    values = ["*24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  owners = ["099720109477"] # Canonical official
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "my-vpc"
  cidr = "10.52.0.0/16"

  azs             = ["us-east-1a", "us-east-1b"]
  private_subnets = ["10.52.1.0/24", "10.52.2.0/24", "10.52.3.0/24", "10.52.4.0/24"]
  public_subnets  = ["10.52.101.0/24", "10.52.102.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = false
  one_nat_gateway_per_az = true

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Environment = "dev"
    Project     = "academy-lab"
  }
}

resource "aws_security_group" "ec2_sg" {
  name        = "ec2-security-group"
  description = "Allow SSH inbound traffic"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "SSH from anywhere"
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
    Name = "EC2-SG"
  }
}


resource "aws_instance" "public_instance" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.micro"
  subnet_id              = module.vpc.public_subnets[0]
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  key_name               = "vockey"  # AWS Academy default key pair
  associate_public_ip_address = true  # Assign public IP

  
  # Uncomment if needed for AWS Academy
  # iam_instance_profile = "LabRole"
  
  tags = {
    Name = "PublicInstance"
  }
}

resource "aws_dynamodb_table" "test_table" {
  name           = "TestTable"
  billing_mode   = "PROVISIONED"
  read_capacity  = 5
  write_capacity = 5
  hash_key       = "ID"
  range_key      = "Timestamp"

  attribute {
    name = "ID"
    type = "S"
  }

  attribute {
    name = "Timestamp"
    type = "N"
  }

  tags = {
    Name = "test-dynamodb-table"
  }
}

output "public_instance_ip" {
  value = aws_instance.public_instance.public_ip
}

output "dynamodb_table_name" {
  value = aws_dynamodb_table.test_table.name
}