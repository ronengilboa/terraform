provider "aws" {
  region="us-east-1"
}

######  wiki server

resource "aws_instance" "wiki" {
  ami           = "ami-0ed540f0f2098339b"
  instance_type = "t2.micro"
#  iam_instance_profile = "grafana-server-role"
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



################ grafana server

resource "aws_instance" "grafana" {
  ami           = "ami-2757f631"
  instance_type = "t2.micro"
  iam_instance_profile = "grafana-server-role"
  key_name       = "awseast"
  vpc_security_group_ids = ["${aws_security_group.insg.id}"]
  subnet_id = "${aws_subnet.internalsub.id}"
  associate_public_ip_address = true
  connection {
    type = "ssh"
    user = "ubuntu"
    private_key = "${file("awseast.pem")}"
  }
  provisioner "remote-exec" {
    inline = [
	"sudo apt-get update -y",
	"sudo apt-get install -y adduser libfontconfig",
	"curl -O https://dl.grafana.com/oss/release/grafana_5.4.2_amd64.deb",
	"sudo dpkg -i grafana_5.4.2_amd64.deb",
	"sudo service grafana-server start",
	"sudo update-rc.d grafana-server defaults",
	"sudo iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 3000",
    ]
  }
}

resource "aws_security_group" "insg" {
  name = "internalserversg"
  vpc_id = "${aws_vpc.internal.id}"
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


resource "aws_vpc" "internal" {
  cidr_block = "192.168.0.0/24"
  enable_dns_hostnames = true
}

resource "aws_subnet" "internalsub" {
  vpc_id     = "${aws_vpc.internal.id}"
  cidr_block = "192.168.0.0/24"

}

resource "aws_internet_gateway" "ingw" {
  vpc_id = "${aws_vpc.internal.id}"

}

resource "aws_route" "insideroute" {
  route_table_id              = "${data.aws_route_table.rintable.id}"
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id      = "${aws_internet_gateway.ingw.id}"
}

data "aws_route_table" "rintable" {
  vpc_id = "${aws_vpc.internal.id}"
}

##grafana conf
provider "grafana" {
  url  = "http://${aws_instance.grafana.public_dns}"
  auth = "admin:admin"
}

resource "grafana_data_source" "awswatch" {
  type = "cloudwatch"
  name = "awswatch"
  json_data {
    default_region = "us-east-1"
    auth_type      = "keys"
  }
}

resource "grafana_dashboard" "dash" {
  depends_on = ["grafana_data_source.awswatch"]
  config_json = "${data.template_file.grafanafile.rendered}"
  
}

data "template_file" "grafanafile" {
    template = "${file("grafana.tpl")}"
    vars {
        instid = "${aws_instance.wiki.id}"
    }
}
