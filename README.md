# AWS EC2 Auto Scaling Group Terraform Module

This Terraform module creates an AWS EC2 Auto Scaling Group with associated Launch Template, scaling policies, and CloudWatch alarms.

## Features

- **Launch Template**: Configurable EC2 launch template with support for:
  - Custom AMI or latest Amazon Linux 2
  - Security groups and key pairs
  - IAM instance profiles
  - User data scripts
  - EBS block device mappings
  - Instance and volume tagging

- **Auto Scaling Group**: Fully configurable ASG with:
  - Multi-AZ deployment across specified subnets
  - Health checks (EC2 or ELB)
  - Target group integration for load balancers
  - Instance refresh capabilities
  - Termination policies
  - Scale-in protection

- **Auto Scaling Policies**: CPU-based scaling with:
  - Scale up/down policies
  - CloudWatch alarms for CPU utilization
  - Configurable thresholds and cooldown periods

## Usage

### Basic Example

```hcl
module "asg" {
  source = "./aws-modules"

  name_prefix        = "my-app"
  subnet_ids         = ["subnet-12345", "subnet-67890"]
  security_group_ids = ["sg-abcdef"]

  min_size         = 1
  max_size         = 5
  desired_capacity = 2

  tags = {
    Environment = "production"
    Project     = "my-project"
  }
}
```

### Advanced Example

```hcl
module "asg" {
  source = "./aws-modules"

  name_prefix        = "web-app"
  subnet_ids         = ["subnet-12345", "subnet-67890"]
  security_group_ids = ["sg-abcdef"]

  instance_type = "t3.medium"
  key_name      = "my-key-pair"
  
  # Custom AMI
  ami_id = "ami-12345678"
  
  # IAM instance profile
  iam_instance_profile_name = "my-instance-profile"

  # User data script
  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y httpd
    systemctl start httpd
    systemctl enable httpd
  EOF

  # Auto Scaling configuration
  min_size         = 2
  max_size         = 10
  desired_capacity = 4

  # Health check configuration
  health_check_type         = "ELB"
  health_check_grace_period = 300
  target_group_arns         = ["arn:aws:elasticloadbalancing:..."]

  # Custom block device mapping
  block_device_mappings = [
    {
      device_name           = "/dev/xvda"
      volume_size           = 30
      volume_type           = "gp3"
      delete_on_termination = true
      encrypted             = true
    }
  ]

  # Scaling policies configuration
  enable_scaling_policies = true
  cpu_high_threshold     = 75
  cpu_low_threshold      = 25
  scale_up_adjustment    = 2
  scale_down_adjustment  = -1

  tags = {
    Environment = "production"
    Project     = "web-application"
    Team        = "platform"
  }
}
```

### With Load Balancer Integration

```hcl
# Application Load Balancer
resource "aws_lb" "app" {
  name               = "my-app-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb.id]
  subnets            = var.public_subnet_ids
}

resource "aws_lb_target_group" "app" {
  name     = "my-app-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = "/"
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

# Auto Scaling Group with target group
module "asg" {
  source = "./aws-modules"

  name_prefix        = "my-app"
  subnet_ids         = var.private_subnet_ids
  security_group_ids = [aws_security_group.app.id]

  health_check_type = "ELB"
  target_group_arns = [aws_lb_target_group.app.arn]

  min_size         = 2
  max_size         = 8
  desired_capacity = 4

  tags = {
    Environment = "production"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| aws | ~> 5.0 |

## Providers

| Name | Version |
|------|---------|
| aws | ~> 5.0 |

## Resources

| Name | Type |
|------|------|
| aws_ami.amazon_linux | data source |
| aws_autoscaling_group.this | resource |
| aws_autoscaling_policy.scale_down | resource |
| aws_autoscaling_policy.scale_up | resource |
| aws_cloudwatch_metric_alarm.cpu_high | resource |
| aws_cloudwatch_metric_alarm.cpu_low | resource |
| aws_launch_template.this | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| name_prefix | Name prefix for all resources | `string` | n/a | yes |
| subnet_ids | List of subnet IDs where instances will be launched | `list(string)` | n/a | yes |
| security_group_ids | List of security group IDs to associate with instances | `list(string)` | n/a | yes |
| instance_type | EC2 instance type | `string` | `"t3.micro"` | no |
| ami_id | AMI ID to use for instances. If not provided, latest Amazon Linux 2 will be used | `string` | `""` | no |
| key_name | Name of the AWS key pair to use for instances | `string` | `null` | no |
| iam_instance_profile_name | Name of the IAM instance profile to associate with instances | `string` | `""` | no |
| user_data | User data script to run when instances start | `string` | `""` | no |
| min_size | Minimum number of instances in the Auto Scaling Group | `number` | `1` | no |
| max_size | Maximum number of instances in the Auto Scaling Group | `number` | `3` | no |
| desired_capacity | Desired number of instances in the Auto Scaling Group | `number` | `2` | no |
| health_check_type | Type of health check (EC2 or ELB) | `string` | `"EC2"` | no |
| health_check_grace_period | Time after instance launch before health checks start | `number` | `300` | no |
| target_group_arns | List of target group ARNs to associate with the Auto Scaling Group | `list(string)` | `[]` | no |
| termination_policies | List of termination policies for the Auto Scaling Group | `list(string)` | `["Default"]` | no |
| protect_from_scale_in | Whether instances should be protected from scale-in events | `bool` | `false` | no |
| wait_for_capacity_timeout | Maximum time to wait for the desired capacity to be reached | `string` | `"10m"` | no |
| instance_refresh_min_healthy_percentage | Minimum percentage of instances that must remain healthy during instance refresh | `number` | `90` | no |
| enable_scaling_policies | Whether to create scaling policies and CloudWatch alarms | `bool` | `true` | no |
| scale_up_adjustment | Number of instances to add when scaling up | `number` | `1` | no |
| scale_down_adjustment | Number of instances to remove when scaling down | `number` | `-1` | no |
| scale_up_cooldown | Cooldown period after scaling up (seconds) | `number` | `300` | no |
| scale_down_cooldown | Cooldown period after scaling down (seconds) | `number` | `300` | no |
| cpu_high_threshold | CPU utilization threshold for scaling up | `number` | `80` | no |
| cpu_low_threshold | CPU utilization threshold for scaling down | `number` | `20` | no |
| block_device_mappings | List of block device mappings for the launch template | `list(object)` | See variables.tf | no |
| tags | Map of tags to apply to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| autoscaling_group_id | ID of the Auto Scaling Group |
| autoscaling_group_arn | ARN of the Auto Scaling Group |
| autoscaling_group_name | Name of the Auto Scaling Group |
| launch_template_id | ID of the Launch Template |
| launch_template_arn | ARN of the Launch Template |
| launch_template_name | Name of the Launch Template |
| launch_template_latest_version | Latest version of the Launch Template |
| scale_up_policy_arn | ARN of the scale up policy |
| scale_down_policy_arn | ARN of the scale down policy |
| cpu_high_alarm_arn | ARN of the CPU high utilization alarm |
| cpu_low_alarm_arn | ARN of the CPU low utilization alarm |

## Best Practices

1. **Security**: Always use security groups to control access to your instances
2. **Monitoring**: Enable CloudWatch detailed monitoring for better visibility
3. **Health Checks**: Use ELB health checks when instances are behind a load balancer
4. **Instance Refresh**: The module includes instance refresh configuration for zero-downtime deployments
5. **Tagging**: Use consistent tagging for cost allocation and resource management
6. **Multi-AZ**: Deploy across multiple availability zones for high availability

## License

This module is released under the MIT License.
