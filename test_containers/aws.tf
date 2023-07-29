# Set up AWS provider
provider "aws" {
  region = "us-east-1"  # Replace with your desired region
}

# Create 10 EC2 instances
resource "aws_instance" "example_ec2_instance" {
  count         = 10
  ami           = "ami-0c55b159cbfafe1f0"  # Replace with your desired AMI ID
  instance_type = "t2.micro"  # Replace with your desired instance type

  # Additional configuration for each instance (Optional)
  tags = {
    Name = "ExampleInstance-${count.index + 1}"
  }
}
