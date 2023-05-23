resource "aws_vpc" "this" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "my-web-app-vpc"
  }
}

resource "aws_subnet" "this" {
  cidr_block = "10.0.1.0/24"
  vpc_id     = aws_vpc.this.id

  tags = {
    Name = "my-web-app-subnet"
  }
}
