
#_____________________________________AWS Info__________________________________#

provider "aws" {
  region = "us-west-2"
}

#________________________________Internet gateway_______________________________#

resource "aws_internet_gateway" "gw" {
  vpc_id = "${var.vpc_id}"

  tags = {
    Name = "Internet Gateway"
  }
}

#_______________________________Public Route Table______________________________# 

resource "aws_route_table" "public_routing_table" {
  vpc_id = "${var.vpc_id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gw.id}"
  }

  tags {
    Name = "public_routing_table"
  }
}

#_______________________________Private Route Table_____________________________#

resource "aws_route_table" "private_routing_table" {
  vpc_id = "${var.vpc_id}"

  tags {
    Name = "private_routing_table"
  }
}

resource "aws_route" "private_route" {
  route_table_id  = "${aws_route_table.private_routing_table.id}"
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = "${aws_nat_gateway.nat.id}"
}

#___________________________________Nat Gateway_________________________________# 

resource "aws_nat_gateway" "nat" {
    allocation_id = "${aws_eip.elastic_eip.id}"
    subnet_id = "${aws_subnet.private_subnet_a.id}"  
}

#___________________________________Elastic IP___________________________________#

resource "aws_eip" "elastic_eip" {
  vpc      = true
}

#_______________________________3 Public subnet_________________________________#

resource "aws_subnet" "public_subnet_a" {
    vpc_id = "${var.vpc_id}"
    #cidr_block = "172.31.0.0/24"
    cidr_block = "172.31.0.0/24"
    availability_zone = "us-west-2a"

    tags {
        Name = "public_a"
    }
}

resource "aws_subnet" "public_subnet_b" {
    vpc_id = "${var.vpc_id}"
    cidr_block = "172.31.1.0/24"
    availability_zone = "us-west-2b"

    tags {
        Name = "public_b"
    }
}

resource "aws_subnet" "public_subnet_c" {
    vpc_id = "${var.vpc_id}"
    cidr_block = "172.31.2.0/24"
    availability_zone = "us-west-2c"

    tags {
        Name = "public_c"
    }
}

#_______________________________3 Private subnet________________________________#

resource "aws_subnet" "private_subnet_a" {
    vpc_id = "${var.vpc_id}"
    cidr_block = "172.31.4.0/22"
    availability_zone = "us-west-2a"

    tags {
        Name = "private_a"
  }
}

resource "aws_subnet" "private_subnet_b" {
    vpc_id = "${var.vpc_id}"
    cidr_block = "172.31.8.0/22"
    availability_zone = "us-west-2b"

    tags {
        Name = "private_b"
  }
}

resource "aws_subnet" "private_subnet_c" {
    vpc_id = "${var.vpc_id}"
    cidr_block = "172.31.12.0/22"
    availability_zone = "us-west-2c"

    tags {
        Name = "private_c"
  }
}

#_________________________________Subnet Group__________________________________#
resource "aws_db_subnet_group" "subnet_group" {
    name = "main"
    subnet_ids = ["${aws_subnet.private_subnet_a.id}", "${aws_subnet.private_subnet_b.id}"]

    tags {
      Name = "subnet_group"
  }
}

#_________________Route Table Associations for private subnet___________________#
resource "aws_route_table_association" "private_subnet_a_rt_association" {
    subnet_id = "${aws_subnet.private_subnet_a.id}"
    route_table_id = "${aws_route_table.private_routing_table.id}"
}

resource "aws_route_table_association" "private_subnet_b_rt_association" {
    subnet_id = "${aws_subnet.private_subnet_b.id}"
    route_table_id = "${aws_route_table.private_routing_table.id}"
}

resource "aws_route_table_association" "private_subnet_c_rt_association" {
    subnet_id = "${aws_subnet.private_subnet_c.id}"
    route_table_id = "${aws_route_table.private_routing_table.id}"
}

#________________Route Table Associations for public subnet_____________________#
resource "aws_route_table_association" "public_subnet_a_rt_assoc" {
    subnet_id = "${aws_subnet.public_subnet_a.id}"
    route_table_id = "${aws_route_table.public_routing_table.id}"
}

resource "aws_route_table_association" "public_subnet_b_rt_assoc" {
    subnet_id = "${aws_subnet.public_subnet_b.id}"
    route_table_id = "${aws_route_table.public_routing_table.id}"
}

resource "aws_route_table_association" "public_subnet_c_rt_assoc" {
    subnet_id = "${aws_subnet.public_subnet_c.id}"
    route_table_id = "${aws_route_table.public_routing_table.id}"
}

#__________________________________Security Groups_______________________________#

#Allow SSH 
resource "aws_security_group" "allow_SSH" {
  name = "allow_all"
  description = "Allow current public IP address to an Instance"

  ingress {
      from_port = 22
      to_port = 22
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "allow_SSH"
  }
}

#Allow RDS
resource "aws_security_group" "allow_RDS" {
    ingress {
      from_port = 3306
      to_port = 3306
      protocol = "tcp"
      cidr_blocks = ["172.31.0.0/16"]
  }
    egress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = ["0.0.0.0/0"]
  }
  tags {
    Name = "allow_RDS"
  }
}

#Allow Leaving Traffic Instances
resource "aws_security_group" "allow_LTI" {
    name = "allow_LTI"
    ingress {
          from_port = 80
          to_port = 80
          protocol = "tcp"
          cidr_blocks = ["172.31.0.0/16"]
  }

    ingress {
          from_port = 22
          to_port = 22
          protocol = "tcp"
          cidr_blocks = ["172.31.0.0/16"]
  }
     egress {
         from_port = 0
         to_port = 0
         protocol = "-1"
         cidr_blocks = ["0.0.0.0/0"]
  }
}

#Allow ELB
resource "aws_security_group" "allow_ELB" {
    name = "allow_ELB"

    ingress {
          from_port = 80
          to_port = 80
          protocol = "tcp"
          cidr_blocks = ["0.0.0.0/0"]
  }
    egress {
         from_port = 0
         to_port = 0
         protocol = "-1"
         cidr_blocks = ["0.0.0.0/0"]
  }
}

#______________________________Elastic Load Balancer_____________________________#

resource "aws_elb" "webserver-ELB" {
    subnets = ["${aws_subnet.public_subnet_b.id}", "${aws_subnet.public_subnet_c.id}"]
 
  listener {
    instance_port = 80
    instance_protocol = "http"
    lb_port = 80
    lb_protocol = "http"
  } 

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 5
    target = "HTTP:80/"
    interval = 30
  } 

  instances = ["${aws_instance.webserver-b.id}", "${aws_instance.webserver-c.id}"]
  security_groups = ["${aws_security_group.allow_ELB.id}"]
  connection_draining = true
  connection_draining_timeout = 60
  cross_zone_load_balancing = true
  idle_timeout = 60

  tags {
    Name = "Elastic Load Balancer"
  }
}

#_______________________________________Instance_________________________________#

#Bastion Instance 
resource "aws_instance" "bastion" {
    ami = "ami-5ec1673e"
    associate_public_ip_address = true
    subnet_id = "${aws_subnet.public_subnet_a.id}"
    instance_type = "t2.micro"
    security_groups = ["${aws_security_group.allow_SSH.id}"]
    key_name = "cit360"
    tags {
        Name = "Bastion Instance"
    }
}

#Webserver-b Instance
resource "aws_instance" "webserver-b" {
    ami = "ami-5ec1673e"
    instance_type = "t2.micro"
    subnet_id = "${aws_subnet.private_subnet_b.id}"
    key_name = "cit360"
    associate_public_ip_address = "false"
    vpc_security_group_ids = ["${aws_security_group.allow_LTI.id}"]
    tags {
        Name = "Webserver-b Instance"
        Service = "curriculum"
  }
}

#Webserver-c Instance
resource "aws_instance" "webserver-c" {
    ami = "ami-5ec1673e"
    instance_type = "t2.micro"
    subnet_id = "${aws_subnet.private_subnet_c.id}"
    key_name = "cit360"
    associate_public_ip_address = "false"
    vpc_security_group_ids = ["${aws_security_group.allow_LTI.id}"]
    tags {
        Name = "Webserver-c Instance"
        Service = "curriculum"
  }
}

#___________________________________RDS Instance_________________________________#

resource "aws_db_instance" "RDS_instance" {
    identifier           = "rds-instance"
    engine               = "mariadb"
    engine_version       = "10.0.24"
    instance_class       = "db.t2.micro"
    multi_az             = "false"
    storage_type         = "gp2"
    allocated_storage    = 5
    username             = "csantos" 
    password             = "${var.db_password}"
    db_subnet_group_name = "${aws_db_subnet_group.subnet_group.id}"
    vpc_security_group_ids = ["${aws_security_group.allow_RDS.id}"]

    tags {
       Name = "RDS_instance" 
 }
}





