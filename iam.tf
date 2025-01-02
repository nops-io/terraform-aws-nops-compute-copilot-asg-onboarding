# Cross account
resource "aws_iam_role" "nops_cross_account_role" {
  name = "nopsCrossAccountStackSetRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "sts.amazonaws.com"
          AWS     = "arn:aws:iam::202279780353:root"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "nops_cross_account_policy" {
  name        = "nOpsCrossAccountPolicy"
  description = "Policy for cross-account role for nOps ASG operations"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "lambda:Update*",
          "lambda:Delete*",
          "lambda:GetFunction",
          "lambda:AddPermission",
          "lambda:RemovePermission",
          "lambda:ListTags",
          "lambda:InvokeFunction"
        ]
        Resource = [
          aws_lambda_function.nops_nasg_lambda.arn,
          aws_lambda_function.nops_regions_checker_lambda.arn,
          aws_lambda_function.nops_self_test_lambda.arn,
          aws_lambda_function.nops_regions_checker_lambda.arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "events:DeleteRule",
          "events:DescribeRule",
          "events:PutRule",
          "events:PutTargets",
          "events:RemoveTargets"
        ]
        Resource = [
          aws_cloudwatch_event_rule.asg_ec2_spot_termination_warning.arn,
          aws_cloudwatch_event_rule.ec2_instance_launch_unsuccessful.arn,
          aws_cloudwatch_event_rule.scheduled_check.arn,
          "arn:aws:events:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:rule/nops-asg-ec2-instance-state-change/nops-asg-ec2-spot-termination-warning",
          "arn:aws:events:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:rule/nops-asg-reconsideration-scheduled-check",
          "arn:aws:events:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:rule/nops-asg-ec2-instance-state-change/nops-asg-ec2-instance-state-change",
          "arn:aws:events:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:rule/nops-asg-ec2-instance-state-change/nops-asg-ec2-instance-launch-unsuccessful"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "iam:GetRole",
          "iam:PassRole",
          "iam:CreateRole",
          "iam:DeleteRole",
          "iam:AttachRolePolicy",
          "iam:DetachRolePolicy",
          "iam:UpdateRole",
          "iam:GetRolePolicy",
          "iam:PutRolePolicy",
          "iam:DeleteRolePolicy"
        ]
        Resource = [
          aws_iam_role.nasg_role_checker_role.arn,
          aws_iam_role.nasg_regions_checker_role.arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "lambda:Update*",
          "lambda:Delete*",
          "lambda:CreateFunction",
          "lambda:GetFunction",
          "lambda:InvokeFunction"
        ]
        Resource = [
          "arn:aws:lambda:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:function:nOps-ASG-role-checker-${data.aws_region.current.id}",
          "arn:aws:lambda:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:function:nOps-ASG-regions-checker-${data.aws_region.current.id}",
          "arn:aws:lambda:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:function:nOps-ASG-self-test-${data.aws_region.current.id}"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "iam:GetRole",
          "iam:PassRole",
          "iam:DeleteRole",
          "iam:UpdateRole",
          "iam:GetRolePolicy",
          "iam:PutRolePolicy",
          "iam:DeleteRolePolicy"
        ]
        Resource = [
          aws_iam_role.nasg_function_role.arn,
          aws_iam_role.nops_cross_account_role.arn
        ]
      },
      {
        Effect = "Allow"
        Action = ["s3:GetObject"]
        Resource = [
          "arn:aws:s3:::nops-${var.environment}-asg-lambda-${data.aws_region.current.id}/*"
        ]
      },
      {
        Effect   = "Allow"
        Action   = ["cloudformation:GetTemplateSummary"]
        Resource = ["*"]
        Condition = {
          StringLike = {
            "cloudformation:TemplateUrl" = [
              "https://nops-???-asg-lambda*.amazonaws.com/??????/cloudformation/lambda-??????.yaml",
              "https://nops-???-asg-lambda*.amazonaws.com/??????/cloudformation/forwarder-??????.yaml"
            ]
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "nops_cross_account_policy_attachment" {
  role       = aws_iam_role.nops_cross_account_role.name
  policy_arn = aws_iam_policy.nops_cross_account_policy.arn
}


# Lambda
resource "aws_iam_role" "nasg_function_role" {
  name = "NASGFunctionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "nasg_function_policy" {
  name        = "NASGFunctionPolicy"
  description = "Policy for the NASG function to manage SQS messages and EC2 events."

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:SendMessage",
          "sqs:GetQueueAttributes",
          "sqs:DeleteMessage"
        ]
        Resource = [
          "arn:aws:sqs:*:*:nops-*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "autoscaling:AttachInstances",
          "autoscaling:CancelInstanceRefresh",
          "autoscaling:CompleteLifecycleAction",
          "autoscaling:CreateOrUpdateTags",
          "autoscaling:DeleteTags",
          "autoscaling:DescribeScalingActivities",
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeAutoScalingInstances",
          "autoscaling:DescribeLaunchConfigurations",
          "autoscaling:DescribeLifecycleHooks",
          "autoscaling:ResumeProcesses",
          "autoscaling:SetInstanceProtection",
          "autoscaling:SuspendProcesses",
          "autoscaling:StartInstanceRefresh",
          "autoscaling:TerminateInstanceInAutoScalingGroup",
          "autoscaling:UpdateAutoScalingGroup",
          "autoscaling:DescribeInstanceRefreshes",
          "ec2:CreateFleet",
          "ec2:CreateLaunchTemplate",
          "ec2:CreateLaunchTemplateVersion",
          "ec2:CreateTags",
          "ec2:DeleteLaunchTemplate",
          "ec2:DeleteTags",
          "ec2:DescribeAvailabilityZones",
          "ec2:DescribeSubnets",
          "ec2:DescribeImages",
          "ec2:DescribeInstanceAttribute",
          "ec2:DescribeInstances",
          "ec2:DescribeLaunchTemplates",
          "ec2:DescribeLaunchTemplateVersions",
          "ec2:DescribeRegions",
          "ec2:DescribeSpotPriceHistory",
          "ec2:GetLaunchTemplateData",
          "ec2:GetInstanceTypesFromInstanceRequirements",
          "ec2:ModifyLaunchTemplate",
          "ec2:RunInstances",
          "ec2:TerminateInstances",
          "events:PutEvents",
          "events:ListRules",
          "events:DisableRule",
          "events:EnableRule",
          "iam:CreateServiceLinkedRole",
          "iam:PassRole",
          "lambda:InvokeFunction",
          "pricing:GetProducts"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "nasg_function_policy_attachment" {
  role       = aws_iam_role.nasg_function_role.name
  policy_arn = aws_iam_policy.nasg_function_policy.arn
}

resource "aws_iam_role_policy_attachment" "nasg_function_role_aws_lambda_basic_execution" {
  role       = aws_iam_role.nasg_function_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role" "nasg_regions_checker_role" {
  name = "nopsRegionsCheckerRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "nasg_regions_checker_policy" {
  name        = "Nops-ASG-Regions-Checker-Policy"
  description = "Policy for EC2 region checking"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["ec2:DescribeRegions"]
        Resource = ["*"]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "nasg_regions_checker_policy_attachment" {
  role       = aws_iam_role.nasg_regions_checker_role.name
  policy_arn = aws_iam_policy.nasg_regions_checker_policy.arn
}

resource "aws_iam_role_policy_attachment" "nasg_regions_checker_aws_lambda_basic_execution" {
  role       = aws_iam_role.nasg_regions_checker_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role" "nasg_role_checker_role" {
  name = "nopsRoleCheckerRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "nasg_role_checker_policy" {
  name        = "Nops-ASG-Role-Checker-Policy"
  description = "Policy for IAM role checking and creation"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "iam:GetRole",
          "iam:GetRolePolicy",
          "iam:ListAttachedRolePolicies",
          "iam:CreateRole",
          "iam:PutRolePolicy",
          "iam:AttachRolePolicy",
          "ec2:DescribeRegions"
        ]
        Resource = ["*"]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "nasg_role_checker_policy_attachment" {
  role       = aws_iam_role.nasg_role_checker_role.name
  policy_arn = aws_iam_policy.nasg_role_checker_policy.arn
}

resource "aws_iam_role_policy_attachment" "aws_lambda_basic_execution" {
  role       = aws_iam_role.nasg_role_checker_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
