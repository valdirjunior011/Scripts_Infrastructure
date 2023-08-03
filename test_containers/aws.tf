provider "aws" {
  region = "eu-central-1"  # Replace with your desired region
}

# Create an AWS Key pair
resource "aws_key_pair" "key" {
  key_name = "id_rsa"
  public_key = file(var.public_key_path)
  
}

data "aws_ami" "latest_ami" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*"]  # You can specify your desired AMI naming pattern here
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["amazon"]  # Replace with the AWS account ID that owns the AMI (Amazon Linux 2 is owned by Amazon)
}

# Create a security group that allows inbound SSH traffic on port 22
resource "aws_security_group" "ssh_sg" {
  name_prefix = "ssh-sg-"

  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Replace with a more restrictive IP range if desired
  }
}

# Create 5 Free Tier eligible EC2 instances t2
resource "aws_instance" "example_t2_instance" {
  count         = 5
  ami           = data.aws_ami.latest_ami.id
  instance_type = "t2.micro"  # Replace with "t3.micro" for a Free Tier eligible instance of the current generation
  key_name  = aws_key_pair.key.key_name  # Specify the key name to associate with the instance
  security_groups = [aws_security_group.ssh_sg.name]  # Associate the instance with the security group

  # Additional configuration for each instance (Optional)
  tags = {
    Name = "Instances_t2-${count.index + 1}"
  }
}
# Create 5 Free Tier eligible EC2 instances t3
resource "aws_instance" "example_t3_instance" {
  count         = 5
  ami           = data.aws_ami.latest_ami.id
  instance_type = "t3.micro"  # Replace with "t3.micro" for a Free Tier eligible instance of the current generation
  key_name  = aws_key_pair.key.key_name  # Specify the key name to associate with the instance
  security_groups = [aws_security_group.ssh_sg.name]  # Associate the instance with the security group

  # Additional configuration for each instance (Optional)
  tags = {
    Name = "Instance_t3-${count.index + 1}"
  }
}

output "public_dns_names" {
  value = concat(
    aws_instance.example_t2_instance[*].public_dns,
    aws_instance.example_t3_instance[*].public_dns
  )
}