####################################################
# PROVIDERS
####################################################

provider "aws" {
  access_key = ""
  secret_key = ""
  region     = "us-east-1"
}
##################################################################################
# VARIABLES
##################################################################################


variable "private_key_path" {
  default = "/home/bilal/Desktop/DMSKEY.pem"
}
variable "key_name" {
  default = "DMSKEY"
}

####################################################
# DATA
####################################################

data "aws_ami" "aws-linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn-ami-hvm*"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
####################################################
# RESOURCES
####################################################

resource "aws_vpc" "kpmg" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = "true"
  tags = {
    Name = "kpmg"
  }
}

resource "aws_subnet" "pub_sub_1" {
  vpc_id     = aws_vpc.kpmg.id
  cidr_block = "10.0.1.0/24"
  depends_on = [aws_vpc.kpmg]
  tags = {
    Name = "Pub_Sub_1"
  }
}
resource "aws_subnet" "pub_sub_2" {
  vpc_id     = aws_vpc.kpmg.id
  cidr_block = "10.0.2.0/24"
  depends_on = [aws_vpc.kpmg]
  tags = {
    Name = "Pub_Sub_2"
  }
}
resource "aws_subnet" "pri_sub_1" {
  vpc_id     = aws_vpc.kpmg.id
  cidr_block = "10.0.3.0/24"
  depends_on = [aws_vpc.kpmg]
  tags = {
    Name = "Pri_Sub_1"
  }
}
resource "aws_subnet" "pri_sub_2" {
  vpc_id     = aws_vpc.kpmg.id
  cidr_block = "10.0.4.0/24"
  depends_on = [aws_vpc.kpmg]
  tags = {
    Name = "Pri_Sub_2"
  }
}
resource "aws_subnet" "pri_sub_3" {
  vpc_id     = aws_vpc.kpmg.id
  cidr_block = "10.0.5.0/24"
  depends_on = [aws_vpc.kpmg]
  tags = {
    Name = "Pri_Sub_3"
  }
}
resource "aws_internet_gateway" "kpmg_igw" {
  vpc_id = aws_vpc.kpmg.id

  tags = { Name = "kpmg-igw" }

}
# ROUTING #
resource "aws_route_table" "pubrtb" {
  vpc_id = aws_vpc.kpmg.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.kpmg_igw.id
  }
}
resource "aws_route_table_association" "pubrtaassoc" {
  
  subnet_id      = aws_subnet.pub_sub_1.id
  route_table_id = aws_route_table.pubrtb.id
  depends_on = [aws_subnet.pub_sub_1]
}
resource "aws_route_table_association" "pubrtaassoc1" {
  
  subnet_id      = aws_subnet.pub_sub_1.id
  route_table_id = aws_route_table.pubrtb.id
  depends_on = [aws_subnet.pub_sub_1]
}
# SECURITY GROUPS #
resource "aws_security_group" "elb-sg" {
  name   = "nginx_elb_sg"
  vpc_id = aws_vpc.kpmg.id

  #Allow HTTP from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  #allow all outbound
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "elb-sg" }
}
resource "aws_security_group" "nginx-sg" {
  name   = "nginx_sg"
  vpc_id = aws_vpc.kpmg.id

  # SSH access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP access from the VPC
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "nginx-sg" }
}
# LOAD BALANCER #
resource "aws_elb" "web" {
  name = "nginx-elb"

  subnets         = [aws_subnet.pub_sub_1.id,aws_subnet.pub_sub_1.id]
  security_groups = [aws_security_group.elb-sg.id]
  instances       = aws_instance.nginx[*].id

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  tags = { Name = "nginx-elb" }
}

######################################################################

resource "aws_instance" "nginx" {
  
  ami                    = data.aws_ami.aws-linux.id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.pri_sub_1.id
  vpc_security_group_ids = [aws_security_group.nginx-sg.id]
  key_name               = var.key_name
  
  depends_on             = [aws_vpc.kpmg]

  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = "ec2-user"
    private_key = file(var.private_key_path)

  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum install nginx -y",
      "sudo service nginx start",
    ]
  }

  tags = { Name = "web-server"}
}

resource "aws_db_subnet_group" "education" {  
  name       = "education"  
  subnet_ids = [aws_subnet.pub_sub_1.id,aws_subnet.pub_sub_2.id]
  tags = {    Name = "Education"  }
  }

resource "aws_db_instance" "nginxdb" {
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t3.micro"
  name                 = "nginxdb"
  username             = "admin"
  password             = "Abcd_1234"
  skip_final_snapshot  = true
  allocated_storage     = 20
  max_allocated_storage = 25
  db_subnet_group_name   = aws_db_subnet_group.education.name
}

  ##################################################################################
  # OUTPUT
  ##################################################################################

  output "aws_elb_public_dns" {
    value = aws_elb.web.dns_name
  }