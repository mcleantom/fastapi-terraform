resource "aws_iam_policy" "web_policy" {
  name              = "web_policy"
  path              = "/"
  description = "Policy to provide permission to web"
  policy = jsonencode({
      "Version": "2012-10-17",
      "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ecr:*",
                "cloudtrail:LookupEvents"
            ],
            "Resource": "*"
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "s3:Get*",
            "s3:List*",
            "s3-object-lambda:Get*",
            "s3-object-lambda:List*"
          ],
          "Resource" : "*"
        }
      ]
    })
}

resource "aws_iam_role" "ec2_role" {
  name = "ec2_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy_attachment" "ec2_policy_role" {
  name = "ec2_attachment"
  roles = [aws_iam_role.ec2_role.name]
  policy_arn = aws_iam_policy.web_policy.arn
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name_prefix = "ec2_profile"
  role = aws_iam_role.ec2_role.name
}

data "aws_ami" "ubuntu" {
    most_recent = true
    filter {
        name   = "name"
        values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
    }
    filter {
        name = "virtualization-type"
        values = ["hvm"]
    }
    owners = ["099720109477"]
}

data "aws_ecr_image" "service_image" {
  repository_name = var.ecr_repository
  image_tag       = "latest"
}

resource "aws_launch_configuration" "grib_manager_launch_configuration" {
  name_prefix = "grib_manager_launch_configuration"
  image_id = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  security_groups = [aws_security_group.default.id]
  associate_public_ip_address = true
  user_data = base64encode(templatefile("${path.module}/user_data.tpl", {
    docker_image_digest=data.aws_ecr_image.service_image.image_digest
  }))
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.id

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "autoscaling_group" {
  launch_configuration = aws_launch_configuration.grib_manager_launch_configuration.id
  min_size = var.autoscaling_group_min_size
  max_size = var.autoscaling_group_max_size
  target_group_arns = [aws_alb_target_group.group.arn]
  vpc_zone_identifier = [aws_subnet.main[0].id, aws_subnet.main[1].id, aws_subnet.main[2].id]

  tag {
    key                 = "Name"
    value               = "terraform-example-autoscaling-group"
    propagate_at_launch = true
  }
}
