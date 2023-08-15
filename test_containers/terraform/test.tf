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

resource "aws_vpc" "example_vpc" {
  cidr_block = "10.0.0.0/16"
}
resource "aws_flow_log" "example_flow_log" {
  name           = "example-flow-log"
  log_group_name = "/aws/vpc/example-vpc-flow-log"
  traffic_type   = "ALL"
  resource_id    = aws_vpc.example_vpc.id
}

resource "aws_subnet" "public_subnet" {
  count                   = 2
  vpc_id                  = aws_vpc.example_vpc.id
  cidr_block              = "10.0.${count.index + 1}.0/24"
  availability_zone       = "us-east-1${chr(97 + count.index)}"
  map_public_ip_on_launch = false
}

resource "aws_security_group" "web_sg" {
  name_prefix = "web-"
}

resource "aws_security_group_rule" "web_ingress" {
  security_group_id = aws_security_group.web_sg.id
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks = var.allowed_cidr_blocks
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
  name               = "example-elb"
  subnets            = aws_subnet.public_subnet.*.id
  security_groups   = [aws_security_group.web_sg.id]

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