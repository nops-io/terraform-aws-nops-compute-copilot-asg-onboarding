resource "aws_iam_role" "nasg_eventbus_role" {
  name = "NASGEventRuleInstanceChangeRole-${data.aws_region.current.id}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "nasg_eventbus_policy" {
  name = "NASGEventbusPolicy=${data.aws_region.current.id}"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "events:PutEvents"
        ]
        Resource = [
          local.nasg_eventbus_arn
        ]
    }]
  })
}
