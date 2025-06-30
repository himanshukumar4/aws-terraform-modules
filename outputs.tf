output "autoscaling_group_id" {
  description = "ID of the Auto Scaling Group"
  value       = aws_autoscaling_group.this.id
}

output "autoscaling_group_arn" {
  description = "ARN of the Auto Scaling Group"
  value       = aws_autoscaling_group.this.arn
}

output "autoscaling_group_name" {
  description = "Name of the Auto Scaling Group"
  value       = aws_autoscaling_group.this.name
}

output "launch_template_id" {
  description = "ID of the Launch Template"
  value       = aws_launch_template.this.id
}

output "launch_template_arn" {
  description = "ARN of the Launch Template"
  value       = aws_launch_template.this.arn
}

output "launch_template_name" {
  description = "Name of the Launch Template"
  value       = aws_launch_template.this.name
}

output "launch_template_latest_version" {
  description = "Latest version of the Launch Template"
  value       = aws_launch_template.this.latest_version
}

output "scale_up_policy_arn" {
  description = "ARN of the scale up policy"
  value       = var.enable_scaling_policies ? aws_autoscaling_policy.scale_up[0].arn : null
}

output "scale_down_policy_arn" {
  description = "ARN of the scale down policy"
  value       = var.enable_scaling_policies ? aws_autoscaling_policy.scale_down[0].arn : null
}

output "cpu_high_alarm_arn" {
  description = "ARN of the CPU high utilization alarm"
  value       = var.enable_scaling_policies ? aws_cloudwatch_metric_alarm.cpu_high[0].arn : null
}

output "cpu_low_alarm_arn" {
  description = "ARN of the CPU low utilization alarm"
  value       = var.enable_scaling_policies ? aws_cloudwatch_metric_alarm.cpu_low[0].arn : null
}
