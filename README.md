### 1. Setting up main.tf

Adding the provider block to the main.tf file. The provider block is used to configure the named provider, in this case, AWS. The region is set to eu-north-1. 

Also adding the backend in S3 backet for storing the state file and a DynamoDB table for locking the state file.
```terraform
# main.tf
provider "aws" {
  region = "eu-north-1"
}

terraform {
  backend "s3" {
    bucket         = "my-terraform-state-bucket"
    key            = "terraform.tfstate"
    region         = "eu-north-1"
    dynamodb_table = "terraform-lock"
  }
}
```
### 2. Creating a modules/network directory with a main.tf file to define the VPC, subnets, and security groups.

```terraform
# modules/network/main.tf

resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "subnet" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
}

resource "aws_security_group" "sg" {
  name        = "allow_http"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["192.168.1.0/24"] # Replace with allowed IP range
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

output "subnet_id" {
  value = aws_subnet.subnet.id
}

output "sg_id" {
  value = aws_security_group.sg.id
}
```
### 3. Creating a modules/compute directory with a main.tf file to define the EC2 instance, AMI, Auto Scaling group, and Load Balancer.

```terraform

# modules/compute/main.tf
resource "aws_instance" "web" {
  ami                    = "ami-0c55b159cbfafe1f0" # Amazon Linux 2 AMI
  instance_type          = "t2.micro"
  subnet_id              = var.subnet_id
  security_groups        = [var.sg_id]
  key_name               = "my-key"  # Replace with your SSH key name

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

resource "aws_launch_configuration" "lc" {
  name          = "web-lc"
  image_id      = aws_ami_from_instance.web_ami.id
  instance_type = "t2.micro"
  key_name      = "my-key"

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "Hello from $(hostname)" > /var/www/html/index.html
              EOF

  security_groups = [var.sg_id]
}

resource "aws_autoscaling_group" "asg" {
  desired_capacity     = 3
  max_size             = 3
  min_size             = 3
  vpc_zone_identifier  = [var.subnet_id]
  launch_configuration = aws_launch_configuration.lc.id
  health_check_type    = "ELB"
  target_group_arns    = [aws_lb_target_group.tg.arn]
}

resource "aws_lb" "lb" {
  name               = "web-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.sg_id]
  subnets            = [var.subnet_id]
}

resource "aws_lb_target_group" "tg" {
  name     = "web-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.lb.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

output "lb_dns_name" {
  value = aws_lb.lb.dns_name
}

```

### 4. Calling modules in main main.tf

```terraform
# main.tf

module "network" {
  source = "./modules/network"
}

module "compute" {
  source        = "./modules/compute"
  subnet_id     = module.network.subnet_id
  sg_id         = module.network.sg_id
  vpc_id        = module.network.vpc_id
}
```

### 5. Running Terraform commands

```bash
terraform init
terraform plan
terraform apply
```











