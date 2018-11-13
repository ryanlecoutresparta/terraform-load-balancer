provider "aws" {
  region                  = "eu-west-1"
}
resource "aws_instance" "app_ryan2" {
  ami                     = "${var.app_ami_id}"
  subnet_id               = "${aws_subnet.subnet_ryan2.id}"
  instance_type           = "t2.micro"
  vpc_security_group_ids  = ["${aws_security_group.security_group_ryan2.id}"]
  user_data               = "${data.template_file.app_init2.rendered}"
  key_name                = "DevOpsStudents"
  tags {
    Name                  = "app_${var.name}2"
  }
}
resource "aws_subnet" "subnet_ryan2" {
  vpc_id                  = "${var.vpc_id}"
  cidr_block              = "10.0.98.0/24"
  map_public_ip_on_launch = true
  tags {
    Name                  = "subnet_${var.name}2"
  }
}
resource "aws_security_group" "security_group_ryan2" {
  name                    = "security_group_${var.name}2"
  description             = "Inbound and outbound rules for the VPC of Kash"
  vpc_id                  = "${var.vpc_id}"
  ingress {
    from_port             = 80
    to_port               = 80
    protocol              = "tcp"
    cidr_blocks           = ["0.0.0.0/0"]
  }
  ingress {
    from_port             = 22
    to_port               = 22
    protocol              = "tcp"
    cidr_blocks           = ["0.0.0.0/0"]
  }
  egress {
    from_port             = 0
    to_port               = 0
    protocol              = "-1"
    cidr_blocks           = ["0.0.0.0/0"]
  }
  tags {
    Name                  = "security_group_${var.name}2"
  }
}
resource "aws_route_table" "ryan_route_table2" {
  vpc_id                  = "${var.vpc_id}"
  route {
    cidr_block            = "0.0.0.0/0"
    gateway_id            = "${data.aws_internet_gateway.default2.id}"
  }
  tags {
    Name                  = "route_table_${var.name}2"
  }
}
resource "aws_route_table_association" "ryan-public-association2" {
  subnet_id               = "${aws_subnet.subnet_ryan2.id}"
  route_table_id          = "${aws_route_table.ryan_route_table2.id}"
}
data "aws_internet_gateway" "default2" {
  filter {
    name                  = "attachment.vpc-id"
    values                = ["${var.vpc_id}"]
  }
}
data "template_file" "app_init2" {
  template                = "${file("./scripts/app/init.sh.tpl")}"
  vars {
    db_host               = "mongod://${aws_instance.db_ryan2.private_ip}:27017/posts"
  }
}


resource "aws_instance" "db_ryan2" {
  ami                     = "${var.db_ami_id}"
  subnet_id               = "${aws_subnet.ryan_private2.id}"
  instance_type           = "t2.micro"
  vpc_security_group_ids  = ["${aws_security_group.ryan_db2.id}"]
  user_data               = "${data.template_file.db_init2.rendered}"
  key_name                = "DevOpsStudents"
  tags {
    Name                  = "db_${var.name}2"
  }
}
resource "aws_subnet" "ryan_private2" {
  vpc_id                  = "${var.vpc_id}"
  cidr_block              = "10.0.99.0/24"
  map_public_ip_on_launch = true
  tags {
    Name                  = "${var.name}_private2"
  }
}
resource "aws_security_group" "ryan_db2" {
  name                    = "${var.name}_db2"
  description             = "Inbound and outbound rules for the VPC of Kash"
  vpc_id                  = "${var.vpc_id}"
  ingress {
    from_port             = 27017
    to_port               = 27017
    protocol              = "tcp"
    cidr_blocks           = ["10.0.98.0/24"]
  }
  egress {
    from_port             = 0
    to_port               = 0
    protocol              = "-1"
    cidr_blocks           = ["0.0.0.0/0"]
  }
  tags {
    Name                  = "${var.name}_db2"
  }
}
resource "aws_route_table_association" "ryan-private-association2" {
  subnet_id               = "${aws_subnet.ryan_private2.id}"
  route_table_id          = "${aws_route_table.ryan_route_table2.id}"
}
data "template_file" "db_init2" {
  template                = "${file("./scripts/db/init.sh.tpl")}"
}

resource "aws_lb" "ryan-lb" {
  name                    = "ryan-lb"
  internal                = false
  load_balancer_type      = "network"
  subnets                 = ["${aws_subnet.subnet_ryan2.id}"]

  enable_deletion_protection = false

  tags {
    Environment           = "production"
  }
}
resource "aws_launch_configuration" "ryan_launch_config" {
  name                    = "ryan_launch_config"
  image_id                = "${var.app_ami_id}"
  instance_type           = "t2.micro"
  user_data               = "${data.template_file.app_init2.rendered}"
}
resource "aws_launch_template" "ryan_launch_template" {
  name_prefix             = "ryan_launch_template"
  image_id                = "${var.app_ami_id}"
  instance_type           = "t2.micro"
}
resource "aws_autoscaling_group" "ryan_autoscaling_group" {
  # load_balancers          = ["${aws_lb.ryan-lb.id}"] NOTE: THIS IS ONLY FOR ELASTIC LOAD BALANCERS
  name                    = "ryan_autoscaling_group"
  availability_zones      = ["eu-west-1a"]
  desired_capacity        = 1
  max_size                = 1
  min_size                = 1

  launch_template = {
    id                    = "${aws_launch_template.ryan_launch_template.id}"
    version               = "$$Latest"
  }
  tags = [{
    key                   = "Name"
    value                 = "ryan-instance"
    propagate_at_launch   = true
  }]
}
