variable "name_prefix" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "log_bucket_sse" {
  description = "Enable default server-side encryption on the logs bucket."
  type        = bool
  default     = true
}

variable "create_kms_key" {
  description = "Create a customer-managed KMS key for Bedrock log encryption."
  type        = bool
  default     = true
}

variable "log_group_name" {
  description = "CloudWatch log group receiving Bedrock invocation logs. Used in Log Insights dashboard widgets."
  type        = string
  default     = "/aws/bedrock/model-invocations"
}

variable "enable_bedrock_cost_budget" {
  description = "Create an AWS Budget (monthly COST) scoped to Amazon Bedrock plus SNS notifications."
  type        = bool
  default     = false
}

variable "bedrock_monthly_budget_limit_usd" {
  description = "Monthly Bedrock budget limit in USD (string per aws_budgets_budget.limit_amount)."
  type        = string
  default     = "2000"

  validation {
    condition     = can(regex("^[0-9]+(\\.[0-9]{1,2})?$", var.bedrock_monthly_budget_limit_usd))
    error_message = "bedrock_monthly_budget_limit_usd must be a positive decimal string (e.g. \"2000\" or \"500.50\")."
  }
}

variable "enable_bedrock_budget_slack_chatbot" {
  description = "Deliver Bedrock budget SNS alerts to Slack via aws_chatbot_slack_channel_configuration. Requires one-time Slack workspace authorization in the AWS console for this account."
  type        = bool
  default     = false
}

variable "bedrock_budget_slack_team_id" {
  description = "Slack workspace ID (prefix T…) after connecting Slack to AWS Chatbot."
  type        = string
  default     = ""
}

variable "bedrock_budget_slack_channel_id" {
  description = "Slack channel ID (prefix C…). Add the AWS / Amazon Q chat app to this channel."
  type        = string
  default     = ""
}

