terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.36.1"
    }
  }
  required_version = ">= 1.0.0"
}

provider "aws" {
  region = var.region
  access_key = var.access_key
  secret_key = var.secret_key
}

resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "terraform-vpc"
  }
}

resource "aws_internet_gateway" "gateway" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "terraform-internet-gateway"
  }
}

resource "aws_route" "route" {
  route_table_id = aws_vpc.vpc.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.gateway.id
}

resource "aws_subnet" "main" {
  count = length(data.aws_availability_zones.available.names)
  vpc_id = aws_vpc.vpc.id
  cidr_block = "10.0.${count.index}.0/24"
  map_public_ip_on_launch = true
  availability_zone = "${element(data.aws_availability_zones.available.names, count.index)}"

  tags = {
    Name = "public-${element(data.aws_availability_zones.available.names, count.index)}"
  }
}

resource "aws_security_group" "default" {
  name = "terraform_security_group"
  description = "Terraform example security group"
  vpc_id = aws_vpc.vpc.id

  # Inbound SSH
  ingress {
    from_port = 22
    protocol  = "tcp"
    to_port   = 22
    cidr_blocks = var.allowed_cidr_blocks
  }

  # Inbound ICMP echo traffic
  ingress {
    from_port = 8
    protocol  = "icmp"
    to_port   = 0
    cidr_blocks = var.allowed_cidr_blocks
  }

  # Inbound HTTP traffic only from load balancer
  ingress {
    from_port = 80
    protocol  = "tcp"
    to_port   = 80
    security_groups = [aws_security_group.alb.id]
  }

  # Allow outbound internet access
  egress {
    from_port = 0
    protocol  = "-1"
    to_port   = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "terraform-security-group"
  }
}



resource "aws_security_group" "alb" {
  name = "terraform_abl_security_group"
  description = "Terraform load balancer security group"
  vpc_id = aws_vpc.vpc.id

  ingress {
    from_port = 433
    protocol  = "tcp"
    to_port   = 433
    cidr_blocks = var.allowed_cidr_blocks
  }

  ingress {
    from_port = 80
    protocol  = "tcp"
    to_port   = 80
    cidr_blocks = var.allowed_cidr_blocks
  }

  # allow all outbound traffic
  egress {
    from_port = 0
    protocol  = "-1"
    to_port   = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "terraform-alb-security-group"
  }
}

resource "aws_alb" "alb" {
  name = "terraform-alb"
  security_groups = [aws_security_group.alb.id]
  subnets = [aws_subnet.main[0].id, aws_subnet.main[1].id, aws_subnet.main[2].id]

  tags = {
    Name = "terraform-alb-security-group"
  }
}

resource "aws_alb_target_group" "group" {
  name = "terraform-alb-target"
  port = 80
  protocol = "HTTP"
  vpc_id = aws_vpc.vpc.id

  stickiness {
    type = "lb_cookie"
  }

  health_check {
    path = "/docs"
    port = 80
  }
}

resource "aws_alb_listener" "listener_http" {
  load_balancer_arn = aws_alb.alb.arn
  port = "80"
  protocol = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port = "433"
      protocol = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_alb_listener" "listener_https" {
  load_balancer_arn = aws_alb.alb.arn
  port = "433"
  protocol = "HTTPS"
  ssl_policy = "ELBSecurityPolicy-2016-08"
  certificate_arn = var.certificate_arn

  default_action {
    target_group_arn = aws_alb_target_group.group.arn
    type = "forward"
  }
}

resource "aws_route53_record" "terraform" {
  zone_id = data.aws_route53_zone.zone.zone_id
  name = "${var.subdomain_name}.${var.route53_hosted_zone_name}"
  type = "A"

  alias {
    name                   = aws_alb.alb.dns_name
    zone_id                = aws_alb.alb.zone_id
    evaluate_target_health = true
  }
}