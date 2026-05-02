output "bedrock_logs_bucket_id" {
  value = aws_s3_bucket.bedrock_logs.id
}

output "bedrock_logs_bucket_arn" {
  value = aws_s3_bucket.bedrock_logs.arn
}

output "bedrock_logs_kms_key_arn" {
  value = var.create_kms_key ? aws_kms_key.bedrock_logs[0].arn : null
}

output "dashboard_name" {
  description = "CloudWatch dashboard name."
  value       = aws_cloudwatch_dashboard.bedrock.dashboard_name
}

output "bedrock_budget_sns_topic_arn" {
  description = "SNS topic ARN for Bedrock budget alerts when enable_bedrock_cost_budget is true."
  value       = try(aws_sns_topic.bedrock_budget_alerts[0].arn, null)
}

output "bedrock_budget_id" {
  description = "AWS Budget ID when enable_bedrock_cost_budget is true."
  value       = try(aws_budgets_budget.bedrock_monthly[0].id, null)
}

output "bedrock_budget_chatbot_configuration_arn" {
  description = "AWS Chatbot Slack configuration ARN when Slack delivery is enabled."
  value       = try(aws_chatbot_slack_channel_configuration.bedrock_budget[0].chat_configuration_arn, null)
}
