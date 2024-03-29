provider "aws" {
  region = "us-east-1"
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
resource "aws_s3_bucket" "vpc_flow_logs" {
  bucket = "my-vpc-flow"
  acl = "private"
  
  versioning {
    enabled = true
  }
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "aws:kms"  # Use AWS Key Management Service
        kms_master_key_id = "arn:aws:kms:<region>:<account-id>:key/<key-id>" 
      }
    }
  }
  lifecycle {
    prevent_destroy = true
    rule {
      id = "expire-old-logs"
      status = "Enabled"
      prefix = ""
      enabled = true
      transitions {
        days = 30
        storage_class = "GLACIER"
      }
      expiration {
        days = 90
      }
    }
  }
  logging {
    target_bucket = aws_s3_bucket.vpc_flow_logs.bucket
    target_prefix = "access-logs/"  
  }
}
resource "aws_s3_bucket_public_access_block" "block_access"{
  bucket = aws_s3_bucket.vpc_flow_logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
resource "aws_flow_log" "vpc_flow_logs" {
  iam_role_arn    = aws_iam_role.vpc_flow_logs.arn
  log_destination = aws_s3_bucket.vpc_flow_logs.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.example_vpc.id
}
resource "aws_iam_role" "vpc_flow_logs" {
  name = "vpc_flow_logs"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "vpc.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "vpc_flow_logs" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
  role       = aws_iam_role.vpc_flow_logs.name
}
resource "aws_vpc" "example_vpc" {
  cidr_block = var.allowed_cidr_blocks
}
resource "aws_flow_log" "example_flow_log" {
  name        = "example-flow-log"
  log_destination = "arn:aws:logs:us-east-1:123456789012:destination-arn"
  traffic_type = "ALL"
  resource_id = aws_vpc.example_vpc.id
}

resource "aws_subnet" "public_subnet" {
  count                   = 2
  vpc_id                  = aws_vpc.example_vpc.id
  cidr_block              = "10.0.${count.index + 1}.0/24"
  availability_zone       = "us-east-1${chr(97 + count.index)}"
  map_public_ip_on_launch = false
}
resource "aws_subnet" "internal_subnet" {
  count       = 1
  vpc_id      = aws_vpc.example_vpc.id
  cidr_block  = "10.0.1.0/24"
  availability_zone = element(var.availability_zones, count.index)

  tags = {
    Name = "Internal Subnet ${count.index + 1}"
  }
}

variable "availability_zones" {
  type    = list(string)
  default = ["us-east-1a", "us-east-1b"]  # Adjust with your preferred availability zones
}


resource "aws_security_group" "web_sg" {
  name_prefix = "web-"
  description = "Web Security Group"
}

resource "aws_security_group_rule" "web_ingress" {
  security_group_id = aws_security_group.web_sg.id
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks = var.allowed_cidr_blocks
  description = "HTTP Port"
}

resource "aws_instance" "example_instance" {
  count         = 2
  ami           = data.aws_ami.latest_ami.id
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public_subnet[count.index].id
  security_groups = [aws_security_group.web_sg.name]
  metadata_options {
    http_tokens = "required"
  }
  root_block_device {
    encrypted = true
  }
  lifecycle {
    precondition {
      condition = data.aws_ami.latest_ami.architecture == "x86_64"
      error_message = "The selected AMI must be for the x86_64 architecture."
    }
  }
}

resource "aws_elb" "example_elb" {
  name        = "example-elb"
  subnets     = aws_subnet.internal_subnet.*.id
  internal    = true  # Set the ELB to be internal
  security_groups = [aws_security_group.web_sg.id]

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }
}


resource "aws_launch_configuration" "example_lc" {
  name_prefix   = "example-lc-"
  image_id      = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"

  security_groups = [aws_security_group.web_sg.name]
  metadata_options {
    http_tokens = "required"
  }
  root_block_device {
    encrypted = true
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "example_asg" {
  desired_capacity = 2
  max_size         = 4
  min_size         = 2

  launch_configuration = aws_launch_configuration.example_lc.name
  vpc_zone_identifier = aws_subnet.public_subnet.*.id

  tag {
    key                 = "Name"
    value               = "example-instance"
    propagate_at_launch = true
  }
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.example_vpc.id
}

resource "aws_route" "public_route" {
  route_table_id         = aws_route_table.public_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.example_internet_gateway.id
}