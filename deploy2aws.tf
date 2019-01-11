provider "aws" {
  region="us-east-1"
}

resource "aws_instance" "wiki" {
  ami           = "ami-2757f631"
  instance_type = "t2.micro"
  key_name       = "awseast"
  vpc_security_group_ids = ["${aws_security_group.websg.id}"]
  subnet_id = "${aws_subnet.externalsub.id}"
  associate_public_ip_address = true
}

resource "aws_security_group" "websg" {
  name = "webserversg"
  vpc_id = "${aws_vpc.external.id}"
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}


resource "aws_vpc" "external" {
  cidr_block = "10.0.0.0/24"
  enable_dns_hostnames = true
}

resource "aws_subnet" "externalsub" {
  vpc_id     = "${aws_vpc.external.id}"
  cidr_block = "10.0.0.0/24"

}

resource "aws_internet_gateway" "exgw" {
  vpc_id = "${aws_vpc.external.id}"

}

resource "aws_route" "outsideroute" {
  route_table_id              = "${data.aws_route_table.rtable.id}"
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id      = "${aws_internet_gateway.exgw.id}"
}

data "aws_route_table" "rtable" {
  vpc_id = "${aws_vpc.external.id}"
}
