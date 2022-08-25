data "aws_iam_policy" "ecs_task_execution_role_policy" {
  name = "AmazonECSTaskExecutionRolePolicy"
}

data "aws_iam_policy" "cloudwatch_agent_policy" {
  name = "CloudWatchAgentServerPolicy"
}

// Random postfix to prevent ECS agent role caching issue
resource "random_string" "postfix" {
  length  = 6
  special = false
  lower   = true
  upper   = true
  numeric = false
}

resource "aws_iam_role" "ecs_task_role" {
  name = "${local.prefix}-tr-${random_string.postfix.result}"

  assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": "sts:AssumeRole",
     "Principal": {
       "Service": "ecs-tasks.amazonaws.com"
     },
     "Effect": "Allow",
     "Sid": ""
   }
 ]
}
EOF
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${local.prefix}-er-${random_string.postfix.result}"

  assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": "sts:AssumeRole",
     "Principal": {
       "Service": "ecs-tasks.amazonaws.com"
     },
     "Effect": "Allow",
     "Sid": ""
   }
 ]
}
EOF
}


resource "aws_iam_policy" "cloudwatch" {
  name        = "${local.prefix}--cloudwatch"
  description = "Policy that allows access to CloudWatch"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents",
                "logs:DescribeLogStreams"
            ],
            "Resource": [
                "arn:aws:logs:*:*:*"
            ]
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ecs_task_role_cw" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.cloudwatch.arn
}

resource "aws_iam_role_policy_attachment" "ecs_task_role_cw_agent" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = data.aws_iam_policy.cloudwatch_agent_policy.arn
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = data.aws_iam_policy.ecs_task_execution_role_policy.arn
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_cw_agent" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = data.aws_iam_policy.cloudwatch_agent_policy.arn
}
