# Required variables
variable "name_prefix" {
  description = "Name prefix for all resources"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs where instances will be launched"
  type        = list(string)
}

variable "security_group_ids" {
  description = "List of security group IDs to associate with instances"
  type        = list(string)
}

# Optional variables with defaults
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "ami_id" {
  description = "AMI ID to use for instances. If not provided, latest Amazon Linux 2 will be used"
  type        = string
  default     = ""
}

variable "key_name" {
  description = "Name of the AWS key pair to use for instances"
  type        = string
  default     = null
}

variable "iam_instance_profile_name" {
  description = "Name of the IAM instance profile to associate with instances"
  type        = string
  default     = ""
}

variable "user_data" {
  description = "User data script to run when instances start"
  type        = string
  default     = ""
}

# Auto Scaling Group configuration
variable "min_size" {
  description = "Minimum number of instances in the Auto Scaling Group"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum number of instances in the Auto Scaling Group"
  type        = number
  default     = 3
}

variable "desired_capacity" {
  description = "Desired number of instances in the Auto Scaling Group"
  type        = number
  default     = 2
}

variable "health_check_type" {
  description = "Type of health check (EC2 or ELB)"
  type        = string
  default     = "EC2"

  validation {
    condition     = contains(["EC2", "ELB"], var.health_check_type)
    error_message = "Health check type must be either EC2 or ELB."
  }
}

variable "health_check_grace_period" {
  description = "Time after instance launch before health checks start"
  type        = number
  default     = 300
}

variable "target_group_arns" {
  description = "List of target group ARNs to associate with the Auto Scaling Group"
  type        = list(string)
  default     = []
}

variable "termination_policies" {
  description = "List of termination policies for the Auto Scaling Group"
  type        = list(string)
  default     = ["Default"]
}

variable "protect_from_scale_in" {
  description = "Whether instances should be protected from scale-in events"
  type        = bool
  default     = false
}

variable "wait_for_capacity_timeout" {
  description = "Maximum time to wait for the desired capacity to be reached"
  type        = string
  default     = "10m"
}

variable "instance_refresh_min_healthy_percentage" {
  description = "Minimum percentage of instances that must remain healthy during instance refresh"
  type        = number
  default     = 90
}

# Scaling policies
variable "enable_scaling_policies" {
  description = "Whether to create scaling policies and CloudWatch alarms"
  type        = bool
  default     = true
}

variable "scale_up_adjustment" {
  description = "Number of instances to add when scaling up"
  type        = number
  default     = 1
}

variable "scale_down_adjustment" {
  description = "Number of instances to remove when scaling down"
  type        = number
  default     = -1
}

variable "scale_up_cooldown" {
  description = "Cooldown period after scaling up (seconds)"
  type        = number
  default     = 300
}

variable "scale_down_cooldown" {
  description = "Cooldown period after scaling down (seconds)"
  type        = number
  default     = 300
}

variable "cpu_high_threshold" {
  description = "CPU utilization threshold for scaling up"
  type        = number
  default     = 80
}

variable "cpu_low_threshold" {
  description = "CPU utilization threshold for scaling down"
  type        = number
  default     = 20
}

# Block device mappings
variable "block_device_mappings" {
  description = "List of block device mappings for the launch template"
  type = list(object({
    device_name           = string
    volume_size           = number
    volume_type           = string
    delete_on_termination = bool
    encrypted             = bool
  }))
  default = [
    {
      device_name           = "/dev/xvda"
      volume_size           = 20
      volume_type           = "gp3"
      delete_on_termination = true
      encrypted             = true
    }
  ]
}

# Tags
variable "tags" {
  description = "Map of tags to apply to all resources"
  type        = map(string)
  default     = {}
}
