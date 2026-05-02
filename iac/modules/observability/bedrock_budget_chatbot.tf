# Routes Bedrock budget SNS notifications to a Slack channel via AWS Chatbot (Amazon Q in chat apps).
#
# Prerequisite (once per AWS account): authorize your Slack workspace in the AWS console —
# https://docs.aws.amazon.com/chatbot/latest/adminguide/slack-setup.html — then invite the app
# to the target Slack channel.

locals {
  bedrock_budget_slack_chatbot_enabled = (
    var.enable_bedrock_cost_budget &&
    var.enable_bedrock_budget_slack_chatbot &&
    length(var.bedrock_budget_slack_team_id) > 0 &&
    length(var.bedrock_budget_slack_channel_id) > 0
  )
}

check "bedrock_budget_slack_requires_budget" {
  assert {
    condition     = !var.enable_bedrock_budget_slack_chatbot || var.enable_bedrock_cost_budget
    error_message = "enable_bedrock_budget_slack_chatbot requires enable_bedrock_cost_budget = true."
  }
}

check "bedrock_budget_slack_requires_ids" {
  assert {
    condition = (
      !var.enable_bedrock_budget_slack_chatbot ||
      (length(var.bedrock_budget_slack_team_id) > 0 && length(var.bedrock_budget_slack_channel_id) > 0)
    )
    error_message = "When enable_bedrock_budget_slack_chatbot is true, set bedrock_budget_slack_team_id (T…) and bedrock_budget_slack_channel_id (C…)."
  }
}

data "aws_iam_policy_document" "bedrock_budget_chatbot_assume" {
  count = local.bedrock_budget_slack_chatbot_enabled ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["chatbot.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "bedrock_budget_chatbot" {
  count = local.bedrock_budget_slack_chatbot_enabled ? 1 : 0

  name               = "${var.name_prefix}-bedrock-budget-chatbot"
  assume_role_policy = data.aws_iam_policy_document.bedrock_budget_chatbot_assume[0].json
}

resource "aws_iam_role_policy_attachment" "bedrock_budget_chatbot_readonly" {
  count = local.bedrock_budget_slack_chatbot_enabled ? 1 : 0

  role       = aws_iam_role.bedrock_budget_chatbot[0].name
  policy_arn = "arn:aws:iam::aws:policy/AWSResourceExplorerReadOnlyAccess"
}

resource "aws_chatbot_slack_channel_configuration" "bedrock_budget" {
  count = local.bedrock_budget_slack_chatbot_enabled ? 1 : 0

  configuration_name = "${var.name_prefix}-bedrock-budget-alerts"
  iam_role_arn       = aws_iam_role.bedrock_budget_chatbot[0].arn
  slack_channel_id   = var.bedrock_budget_slack_channel_id
  slack_team_id      = var.bedrock_budget_slack_team_id
  sns_topic_arns     = [aws_sns_topic.bedrock_budget_alerts[0].arn]

  # Avoid provider default of AdministratorAccess for in-channel actions.
  guardrail_policy_arns = ["arn:aws:iam::aws:policy/AWSResourceExplorerReadOnlyAccess"]
  logging_level         = "ERROR"

  depends_on = [
    aws_sns_topic_policy.bedrock_budget_alerts,
    aws_iam_role_policy_attachment.bedrock_budget_chatbot_readonly,
  ]
}
