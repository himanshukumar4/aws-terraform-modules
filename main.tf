# AWS EC2 Auto Scaling Group Terraform Module

# Data source for the latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Launch Template
resource "aws_launch_template" "this" {
  name_prefix   = "${var.name_prefix}-"
  image_id      = var.ami_id != "" ? var.ami_id : data.aws_ami.amazon_linux.id
  instance_type = var.instance_type
  key_name      = var.key_name

  vpc_security_group_ids = var.security_group_ids

  user_data = var.user_data != "" ? base64encode(var.user_data) : null

  dynamic "iam_instance_profile" {
    for_each = var.iam_instance_profile_name != "" ? [1] : []
    content {
      name = var.iam_instance_profile_name
    }
  }

  dynamic "block_device_mappings" {
    for_each = var.block_device_mappings
    content {
      device_name = block_device_mappings.value.device_name
      ebs {
        volume_size           = block_device_mappings.value.volume_size
        volume_type           = block_device_mappings.value.volume_type
        delete_on_termination = block_device_mappings.value.delete_on_termination
        encrypted             = block_device_mappings.value.encrypted
      }
    }
  }

  tag_specifications {
    resource_type = "instance"
    tags = merge(
      var.tags,
      {
        Name = "${var.name_prefix}-instance"
      }
    )
  }

  tag_specifications {
    resource_type = "volume"
    tags = merge(
      var.tags,
      {
        Name = "${var.name_prefix}-volume"
      }
    )
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-launch-template"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "this" {
  name                = "${var.name_prefix}-asg"
  vpc_zone_identifier = var.subnet_ids
  target_group_arns   = var.target_group_arns
  health_check_type   = var.health_check_type
  health_check_grace_period = var.health_check_grace_period

  min_size         = var.min_size
  max_size         = var.max_size
  desired_capacity = var.desired_capacity

  launch_template {
    id      = aws_launch_template.this.id
    version = "$Latest"
  }

  # Instance refresh configuration
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = var.instance_refresh_min_healthy_percentage
    }
  }

  # Termination policies
  termination_policies = var.termination_policies

  # Enable instance protection
  protect_from_scale_in = var.protect_from_scale_in

  # Wait for capacity timeout
  wait_for_capacity_timeout = var.wait_for_capacity_timeout

  dynamic "tag" {
    for_each = var.tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  tag {
    key                 = "Name"
    value               = "${var.name_prefix}-asg"
    propagate_at_launch = false
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes       = [desired_capacity]
  }
}

# Auto Scaling Policies
resource "aws_autoscaling_policy" "scale_up" {
  count                  = var.enable_scaling_policies ? 1 : 0
  name                   = "${var.name_prefix}-scale-up"
  scaling_adjustment     = var.scale_up_adjustment
  adjustment_type        = "ChangeInCapacity"
  cooldown              = var.scale_up_cooldown
  autoscaling_group_name = aws_autoscaling_group.this.name
}

resource "aws_autoscaling_policy" "scale_down" {
  count                  = var.enable_scaling_policies ? 1 : 0
  name                   = "${var.name_prefix}-scale-down"
  scaling_adjustment     = var.scale_down_adjustment
  adjustment_type        = "ChangeInCapacity"
  cooldown              = var.scale_down_cooldown
  autoscaling_group_name = aws_autoscaling_group.this.name
}

# CloudWatch Alarms
resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  count               = var.enable_scaling_policies ? 1 : 0
  alarm_name          = "${var.name_prefix}-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = var.cpu_high_threshold
  alarm_description   = "This metric monitors ec2 cpu utilization"
  alarm_actions       = [aws_autoscaling_policy.scale_up[0].arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.this.name
  }

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "cpu_low" {
  count               = var.enable_scaling_policies ? 1 : 0
  alarm_name          = "${var.name_prefix}-cpu-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = var.cpu_low_threshold
  alarm_description   = "This metric monitors ec2 cpu utilization"
  alarm_actions       = [aws_autoscaling_policy.scale_down[0].arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.this.name
  }

  tags = var.tags
}
