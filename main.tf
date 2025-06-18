provider "aws" {
  region     = "us-east-1"
  access_key = "AKIA3H6DFMAQYASSEKOC"
  secret_key = "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"
}


# Create S3 Bucket
resource "aws_s3_bucket" "reports" {
  bucket = "reports-${random_id.bucket_id.hex}"
  force_destroy = true
}

resource "random_id" "bucket_id" {
  byte_length = 4
}

# Create ECR Repository
resource "aws_ecr_repository" "appimages" {
  name = "appimages"
}

# Create Security Group to allow all ports
resource "aws_security_group" "allow_all" {
  name        = "allow_all"
  description = "Allow all inbound traffic"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Get default VPC
data "aws_vpc" "default" {
  default = true
}

# Get default subnet
data "aws_subnet_ids" "default" {
  vpc_id = data.aws_vpc.default.id
}

# Create EC2 instance with Ubuntu
resource "aws_instance" "devops" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.large" # 8GB RAM

  subnet_id              = data.aws_subnet_ids.default.ids[0]
  security_groups        = [aws_security_group.allow_all.name]
  associate_public_ip_address = true
  key_name               = "mykey"

  root_block_device {
    volume_size = 75
    volume_type = "gp2"
  }

  tags = {
    Name = "Devops"
  }
}

# Get Ubuntu AMI
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
