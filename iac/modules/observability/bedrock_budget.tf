# Monthly AWS Budget filtered to Amazon Bedrock service spend. Notifications go to SNS;
# subscribe humans via email/SMS/Slack on the topic as needed.

resource "aws_sns_topic" "bedrock_budget_alerts" {
  count = var.enable_bedrock_cost_budget ? 1 : 0
  name  = "${var.name_prefix}-bedrock-budget-alerts"
}

data "aws_iam_policy_document" "bedrock_budget_sns" {
  count = var.enable_bedrock_cost_budget ? 1 : 0

  statement {
    sid    = "AllowAwsBudgetsPublish"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["budgets.amazonaws.com"]
    }

    actions   = ["sns:Publish"]
    resources = [aws_sns_topic.bedrock_budget_alerts[0].arn]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = ["arn:${data.aws_partition.current.partition}:budgets::${data.aws_caller_identity.current.account_id}:budget/*"]
    }
  }

  dynamic "statement" {
    for_each = local.bedrock_budget_slack_chatbot_enabled ? [1] : []
    content {
      sid    = "AllowAwsChatbotSubscribe"
      effect = "Allow"

      principals {
        type        = "Service"
        identifiers = ["chatbot.amazonaws.com"]
      }

      actions = [
        "sns:Subscribe",
        "sns:Receive",
      ]

      resources = [aws_sns_topic.bedrock_budget_alerts[0].arn]
    }
  }
}

resource "aws_sns_topic_policy" "bedrock_budget_alerts" {
  count = var.enable_bedrock_cost_budget ? 1 : 0

  arn    = aws_sns_topic.bedrock_budget_alerts[0].arn
  policy = data.aws_iam_policy_document.bedrock_budget_sns[0].json
}

resource "aws_budgets_budget" "bedrock_monthly" {
  count = var.enable_bedrock_cost_budget ? 1 : 0

  name         = "${var.name_prefix}-bedrock-monthly-cap"
  budget_type  = "COST"
  limit_amount = var.bedrock_monthly_budget_limit_usd
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  cost_filter {
    name   = "Service"
    values = ["Amazon Bedrock"]
  }

  # Low-dollar litmus: fires when actual Bedrock spend exceeds this USD amount (not % of budget cap).
  notification {
    comparison_operator       = "GREATER_THAN"
    threshold                 = 50
    threshold_type            = "ABSOLUTE_VALUE"
    notification_type         = "ACTUAL"
    subscriber_sns_topic_arns = [aws_sns_topic.bedrock_budget_alerts[0].arn]
  }

  notification {
    comparison_operator       = "GREATER_THAN"
    threshold                 = 50
    threshold_type            = "PERCENTAGE"
    notification_type         = "ACTUAL"
    subscriber_sns_topic_arns = [aws_sns_topic.bedrock_budget_alerts[0].arn]
  }

  notification {
    comparison_operator       = "GREATER_THAN"
    threshold                 = 75
    threshold_type            = "PERCENTAGE"
    notification_type         = "ACTUAL"
    subscriber_sns_topic_arns = [aws_sns_topic.bedrock_budget_alerts[0].arn]
  }

  notification {
    comparison_operator       = "GREATER_THAN"
    threshold                 = 100
    threshold_type            = "PERCENTAGE"
    notification_type         = "FORECASTED"
    subscriber_sns_topic_arns = [aws_sns_topic.bedrock_budget_alerts[0].arn]
  }

  depends_on = [aws_sns_topic_policy.bedrock_budget_alerts]
}
