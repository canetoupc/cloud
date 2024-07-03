provider "aws" {
  region = "us-east-1"
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "subred_publica01_cidr" {
  default = "10.0.1.0/24"
}

variable "subred_publica02_cidr"{
  default = "10.0.2.0/24"
}

variable "subred01_privada_cidr" {
  default = "10.0.3.0/24"
}

variable "subred02_privada_cidr" {
  default = "10.0.4.0/24"
}

variable "ami_id" {
  default = "ami-04b70fa74e45c3917"
}

resource "aws_vpc" "red_pirmaria" {
  cidr_block = var.vpc_cidr
  enable_dns_support = true
  enable_dns_hostnames = true

  tags = {
    Env = "Prod"
    Project = "Networking"
  }
}

resource "aws_subnet" "zona_publica_1" {
  vpc_id     = aws_vpc.red_pirmaria.id
  cidr_block = var.subred_publica01_cidr
  availability_zone = "us-east-1a"

  tags = {
    Env = "Prod"
    Zone = "PublicA"
  }
}

resource "aws_subnet" "zona_publica_2" {
  vpc_id     = aws_vpc.red_pirmaria.id
  cidr_block = var.subred_publica01_cidr

availability_zone = "us-east-1b"

tags = {
  Env = "Prod"
  Zone = "PublicB"
}
}

resource "aws_subnet" "zona_privada_1" {
vpc_id     = aws_vpc.red_pirmaria.id
cidr_block = var.subred01_privada_cidr
availability_zone = "us-east-1a"

tags = {
Env = "Prod"
Zone = "PrivateA"
}
}

resource "aws_subnet" "zona_privada_2" {
vpc_id     = aws_vpc.red_pirmaria.id
cidr_block = var.subred02_privada_cidr
availability_zone = "us-east-1b"

tags = {
Env = "Prod"
Zone = "PrivateB"
}
}

resource "aws_internet_gateway" "main_gateway" {
vpc_id = aws_vpc.red_pirmaria.id

tags = {
Env = "Prod"
Gateway = "MainIGW"
}
}

resource "aws_route_table" "tabla_rutas" {
vpc_id = aws_vpc.red_pirmaria.id

route {
cidr_block = "0.0.0.0/0"
gateway_id = aws_internet_gateway.main_gateway.id
}

tags = {
Env = "Prod"
Type = "Public"
}
}

resource "aws_route_table_association" "asociacion01" {
subnet_id      = aws_subnet.zona_publica_1.id
route_table_id = aws_route_table.tabla_rutas.id
}

resource "aws_route_table_association" "asociacion02" {
subnet_id      = aws_subnet.zona_publica_2.id
route_table_id = aws_route_table.tabla_rutas.id
}

resource "aws_security_group" "instance_security_group" {
name        = "ec2SecurityGroup"
description = "Security group for EC2 instances"
vpc_id      = aws_vpc.red_pirmaria.id

ingress {
from_port   = 0
to_port     = 65535
protocol    = "tcp"
cidr_blocks = ["0.0.0.0/0"]
}

egress {
from_port   = 0
to_port     = 0
protocol    = "-1"
cidr_blocks = ["0.0.0.0/0"]
}

tags = {
Env = "Prod"
Type = "SecurityGroup"
}
}

resource "aws_instance" "instance_1_primaria" {
ami           = var.ami_id
instance_type = "t2.micro"
subnet_id     = aws_subnet.zona_publica_1.id

vpc_security_group_ids = [
aws_security_group.instance_security_group.id
]

tags = {
Env = "Prod"
Instance = "Primary1"
}
}

resource "aws_instance" "instance_2_primaria" {
ami           = var.ami_id
instance_type = "t2.micro"
subnet_id     = aws_subnet.zona_publica_2.id

vpc_security_group_ids = [
aws_security_group.instance_security_group.id
]

tags = {
Env = "Prod"
Instance = "Primary2"
}
}