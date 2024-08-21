# modules/compute/main.tf
resource "aws_instance" "web" {
  ami             = "ami-090abff6ae1141d7d"
  instance_type   = "t3.micro"
  subnet_id       = var.subnets[0]                 # Use the first subnet
  security_groups = var.security_groups            # Pass the security groups list directly
  key_name        = "my-key"

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "Hello from $(hostname)" > /var/www/html/index.html
              EOF

  tags = {
    Name = "TempWebServer"
  }
}

resource "aws_ami_from_instance" "web_ami" {
  name               = "web-server-ami"
  source_instance_id = aws_instance.web.id
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb" "web_lb" {
  name               = "web-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = var.security_groups
  subnets            = var.subnets
  enable_deletion_protection     = false
  enable_cross_zone_load_balancing = true

  tags = {
    Name = "web-lb"
  }
}

resource "aws_lb_target_group" "web_tg" {
  name     = "web-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "web_listener" {
  load_balancer_arn = aws_lb.web_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_tg.arn
  }
}
