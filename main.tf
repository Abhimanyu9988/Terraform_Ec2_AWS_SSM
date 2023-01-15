terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
      ##### Adding parameters
    }
  }

  required_version = ">= 0.13"
}


provider "aws" {
  region              = "us-east-1"
  profile             = "XXXXXX"
  shared_config_files = ["/Users/XXXXXX/.aws/config"]
}

resource "aws_instance" "AbhiBajajLinux" {
  ami                    = "ami-06878d265978313ca"
  instance_type          = "t2.medium"
  key_name               = "XXXXXXX"
  iam_instance_profile   = aws_iam_instance_profile.dev-resources-iam-profile.name
  vpc_security_group_ids = [aws_security_group.allow_web.id]
  root_block_device {
    delete_on_termination = true
    volume_type           = "gp2"
    volume_size           = 20
  }
  tags = {
    Name  = "Ec2-With-SessionManager-test"
    owner = "Abhi Bajaj"

  }
  user_data = data.template_file.startup.rendered

}


####IAM ROLE For SSM Agent
resource "aws_iam_instance_profile" "dev-resources-iam-profile" {
  name = "ec2_profile"
  role = aws_iam_role.dev-resources-iam-role.name
}

resource "aws_iam_role" "dev-resources-iam-role" {
  name               = "dev-ssm-role"
  description        = "The role for the developer resources EC2"
  assume_role_policy = <<EOF
{
"Version": "2012-10-17",
"Statement": {
"Effect": "Allow",
"Principal": {"Service": "ec2.amazonaws.com"},
"Action": "sts:AssumeRole"
}
}
EOF
  tags = {
    stack = "test"
  }
}
resource "aws_iam_role_policy_attachment" "dev-resources-ssm-policy" {
  role       = aws_iam_role.dev-resources-iam-role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}


###COMMENT: File for getting SSM Agent
data "template_file" "startup" {
  template = file("ssm-agent-installer.sh")
}

####COMMENT: File for getting Machine Agent

####COMMENT: Security Group for SSM Agent

resource "aws_security_group" "allow_web" {
  name        = "webserver"
  description = "Allows access to Web Port"

  #allow http

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # allow https

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # allow SSH

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  #all outbound

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Owner = "Abhi Bajaj"
  }
  lifecycle {
    create_before_destroy = true
  }

}
