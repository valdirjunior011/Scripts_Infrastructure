provider "aws" {
  region = "eu-central-1"
}

resource "aws_key_pair" "key" {
  key_name   = "id_rsa"
  public_key = file(var.public_key_path)
}

resource "aws_security_group" "ssh_sg" {
  name_prefix = "ssh-sg-"

  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Flask App Port"
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]   
  }

  egress {
    cidr_blocks    = ["0.0.0.0/0"]
    protocol      = "-1"
    from_port     = 0
    to_port       = 0
  }
}

data "aws_ami" "latest_ami" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"]
}

resource "aws_instance" "t2_instance" {
  count         = 15
  ami           = data.aws_ami.latest_ami.id
  instance_type = "t2.micro"
  key_name      = aws_key_pair.key.key_name
  security_groups = [aws_security_group.ssh_sg.name]  # Use the security group ID instead of name
  metadata_options {
    http_tokens = "required"
  }
  root_block_device {
    encrypted = true
  }
  tags = {
    Name = "Instance_t2-${count.index + 1}"
  }
}

resource "aws_instance" "t3_instance" {
  count         = 10
  ami           = data.aws_ami.latest_ami.id
  instance_type = "t3.micro"
  key_name      = aws_key_pair.key.key_name
  security_groups = [aws_security_group.ssh_sg.name]  # Use the security group ID instead of name
  metadata_options {
    http_tokens = "required"
  }
  root_block_device {
    encrypted = true
  }
  tags = {
    Name = "Instance_t3-${count.index + 1}"
  }
}
  
output "public_ip" {
  value = concat(
    aws_instance.t2_instance[*].public_ip,
    aws_instance.t3_instance[*].public_ip
  )
}