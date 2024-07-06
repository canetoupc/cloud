provider "aws" {
  region = "us-east-1"
}
resource "aws_vpc" "vpcPrimaria" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true

  tags = {
    Name = "vpcPrimaria"
  }
}
resource "aws_subnet" "subRedPublica1" {
  vpc_id     = aws_vpc.vpcPrimaria.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "subRedPublica1"
  }
}
resource "aws_subnet" "subRedPublica2" {
  vpc_id     = aws_vpc.vpcPrimaria.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-east-1b"  # Zona de disponibilidad B

  tags = {
    Name = "subRedPublica2"
  }
}

resource "aws_subnet" "subRedPrivada1" {
  vpc_id     = aws_vpc.vpcPrimaria.id
  cidr_block = "10.0.3.0/24"
  availability_zone = "us-east-1a"  # Zona de disponibilidad A

  tags = {
    Name = "privateSubnet1"
  }
}

resource "aws_subnet" "subRedPrivada2" {
  vpc_id     = aws_vpc.vpcPrimaria.id
  cidr_block = "10.0.4.0/24"
  availability_zone = "us-east-1b"  # Zona de disponibilidad B

  tags = {
    Name = "privateSubnet2"
  }
}

resource "aws_internet_gateway" "internetGateway" {
  vpc_id = aws_vpc.vpcPrimaria.id

  tags = {
    Name = "internetGateway"
  }
}

resource "aws_route_table" "tablaRutasPublicas" {
  vpc_id = aws_vpc.vpcPrimaria.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internetGateway.id
  }

  tags = {
    Name = "tablaRutasPublicas"
  }
}

resource "aws_route_table_association" "subRedPublica1_asociacionn" {
  subnet_id      = aws_subnet.subRedPublica1.id
  route_table_id = aws_route_table.tablaRutasPublicas.id
}

resource "aws_route_table_association" "subRedPublica2_asociacion" {
  subnet_id      = aws_subnet.subRedPublica2.id
  route_table_id = aws_route_table.tablaRutasPublicas.id
}
resource "aws_security_group" "grupoSeguridad" {


  name        = "grupoSeguridad_instancia"
  description = "Instancia del grupo de seguridad"

  vpc_id = aws_vpc.vpcPrimaria.id

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
}

resource "aws_lb_target_group" "grupoTarget" {
  name     = "grupoTarget"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.vpcPrimaria.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    port                = 80
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 4
    interval            = 5
  }
}

resource "aws_lb" "balanceadorCarga" {
  name               = "balanceadorCarga"
  internal           = false  # Configúralo como "true" si deseas un ALB interno
  load_balancer_type = "application"
  security_groups    = [aws_security_group.grupoSeguridad.id]
  subnets            = [aws_subnet.subRedPublica1.id, aws_subnet.subRedPublica2.id]

  tags = {
    Name = "balanceadorCarga"
  }
}

resource "aws_instance" "InstanciaEC2" {
  ami           = "ami-04b70fa74e45c3917"  # ID de la AMI de Amazon Linux 2, por ejemplo
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.subRedPublica1.id
  associate_public_ip_address = true
  key_name = "KeyPair"  # Nombre de la clave SSH que se utilizará para conectarse a la instancia

  vpc_security_group_ids = [
    aws_security_group.grupoSeguridad.id  # Asocia la instancia al grupo de seguridad definido arriba
  ]
  tags = {
    Name = "InstanciaEc2_1"
  }

  depends_on = [aws_lb_target_group.grupoTarget]

}

resource "aws_instance" "InstanciaEC2_2" {
  ami           = "ami-04b70fa74e45c3917"  # ID de la AMI de Amazon Linux 2, por ejemplo
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.subRedPublica2.id
  associate_public_ip_address = true
  key_name = "KeyPair2"  # Nombre de la clave SSH que se utilizará para conectarse a la instancia

  vpc_security_group_ids = [
    aws_security_group.grupoSeguridad.id  # Asocia la instancia al grupo de seguridad definido arriba
  ]
  tags = {
    Name = "InstanciaEc2_2"
  }

  depends_on = [aws_lb_target_group.grupoTarget]

}

resource "aws_lb_target_group_attachment" "InstanciaEC2_attachment" {
  target_group_arn = aws_lb_target_group.grupoTarget.arn
  target_id        = aws_instance.InstanciaEC2.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "InstanciaEC2_2_attachment" {
  target_group_arn = aws_lb_target_group.grupoTarget.arn
  target_id        = aws_instance.InstanciaEC2_2.id
  port             = 80
}

resource "aws_lb_listener" "listenerBalanceadorCarga" {
  load_balancer_arn = aws_lb.balanceadorCarga.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.grupoTarget.arn
  }
}
