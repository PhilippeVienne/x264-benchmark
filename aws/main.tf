terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "eu-west-3"

  default_tags {
    tags = {
      Terraform = "true"
      Project   = "ffmpeg-benchmark"
    }

  }
}

variable "name" {
  default = "benchmark"
}

variable "instance_type" {
  #default = "t3.xlarge"
  default = "c7i-flex.4xlarge"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.9.0"
  name    = var.name
  cidr    = "192.168.2.0/24"

  azs            = ["eu-west-3a"]
  public_subnets = ["192.168.2.0/26"]

  enable_nat_gateway = false
  enable_vpn_gateway = false
}

locals {
  subnet = module.vpc.public_subnets[0]
}

module "efs" {
  source  = "terraform-aws-modules/efs/aws"
  version = "1.6.3"
  name    = var.name
  mount_targets = {
    "eu-west-3a" : {
      subnet_id : module.vpc.public_subnets[0]
    }
  }

  security_group_description = "EFS security group"
  security_group_vpc_id      = module.vpc.vpc_id
  security_group_rules = {
    vpc = {
      # relying on the defaults provdied for EFS/NFS (2049/TCP + ingress)
      description = "NFS ingress from VPC private subnets"
      cidr_blocks = ["192.168.2.0/24"]
    }
  }

}

resource "aws_security_group" "instance" {
  name        = "instance"
  description = "Allow inbound traffic"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    ipv6_cidr_blocks = ["::/0"]
  }
}

module "ec2" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "5.6.1"
  name    = var.name

  instance_type = var.instance_type
  monitoring    = false
  vpc_security_group_ids = [
    aws_security_group.instance.id
  ]
  subnet_id = module.vpc.public_subnets[0]

  associate_public_ip_address = true

  create_iam_instance_profile = true
  iam_role_name               = "${var.name}-role"
  iam_role_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }

  user_data_replace_on_change = true
  user_data                   = <<EOF
#!/bin/bash
yum update -y
yum install -y amazon-efs-utils
amazon-linux-extras install docker 
service docker start
# Mount EFS
mkdir /mnt/efs
sudo mount -t efs -o tls ${module.efs.id}:/ /mnt/efs
sudo chmod 777 /mnt/efs
EOF

  depends_on = [module.efs, module.vpc]

  tags = {
    Name = var.name
  }
}