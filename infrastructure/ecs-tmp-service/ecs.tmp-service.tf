data "aws_ecs_task_definition" "tmp_service" {
  task_definition = aws_ecs_task_definition.tmp_service.family
}

data "aws_ecr_repository" "tmp_service" {
  name = data.terraform_remote_state.ecr_tmp_service.outputs.tmp_service_repo_name
}

data "aws_ecr_image" "tmp_service" {
  repository_name = data.aws_ecr_repository.tmp_service.name
  image_tag       = "latest"
}

resource "aws_ecs_task_definition" "tmp_service" {
  family = "${local.prefix}-tmp-service"

  network_mode             = "awsvpc"
  requires_compatibilities = ["EC2"]

  cpu                = 256
  memory             = 512
  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn      = aws_iam_role.ecs_task_role.arn

  volume {
    name = local.tmp_service_efs_volume_name
    efs_volume_configuration {
      transit_encryption = "ENABLED"
      file_system_id     = data.terraform_remote_state.ecs.outputs.efs_id
      authorization_config {
        access_point_id = aws_efs_access_point.service_dir.id
      }
    }
  }

  container_definitions = jsonencode([
    {
      name      = local.tmp_service_container_name
      image     = "${data.aws_ecr_repository.tmp_service.repository_url}:latest@${data.aws_ecr_image.tmp_service.image_digest}"
      essential = true
      portMappings = [
        {
          containerPort = 3000
          hostPort      = 3000
        }
      ]
      environment = [
        {
          name  = "LIB_FOLDER",
          value = local.efs_mount_path
        },
        {
          name  = "SERVICE_ID",
          value = var.service_id
        }
      ]
      mountPoints : [
        {
          "containerPath" : local.efs_mount_path,
          "sourceVolume" : local.tmp_service_efs_volume_name
          "readOnly" = true
        }
      ]
      logConfiguration : {
        logDriver : "awslogs",
        options : {
          "awslogs-group" : "/ecs/tmp/${var.user_id}-${local.prefix}",
          "awslogs-region" : "eu-central-1",
          "awslogs-stream-prefix" : "tmp-service"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "tmp_service" {
  name            = "${local.prefix}-tmp-service"
  cluster         = data.terraform_remote_state.ecs.outputs.ecs_cluster_id
  task_definition = "${aws_ecs_task_definition.tmp_service.family}:${max(aws_ecs_task_definition.tmp_service.revision, data.aws_ecs_task_definition.tmp_service.revision)}"

  desired_count                      = 1
  deployment_minimum_healthy_percent = 0
  deployment_maximum_percent         = 200
  launch_type                        = "EC2"
  scheduling_strategy                = "REPLICA"
  force_new_deployment               = true

  load_balancer {
    target_group_arn = aws_lb_target_group.ecs_tmp_service.arn
    container_name   = local.tmp_service_container_name
    container_port   = 3000
  }

  network_configuration {
    subnets = data.terraform_remote_state.ecs.outputs.private_subnets
    security_groups = [
      aws_security_group.tmp_service.id,
      data.terraform_remote_state.ecs.outputs.efs_sg_access_id
    ]
  }

  lifecycle {
    ignore_changes = [desired_count]
  }
}

resource "aws_security_group" "tmp_service" {
  name   = "${local.prefix}-ecs-tmp-service"
  vpc_id = data.terraform_remote_state.ecs.outputs.vpc_id

  ingress {
    protocol        = "tcp"
    from_port       = 3000
    to_port         = 3000
    security_groups = [data.terraform_remote_state.ecs.outputs.alb_sg_id]
  }

  egress {
    protocol         = "-1"
    from_port        = 0
    to_port          = 0
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_cloudwatch_log_group" "tmp_service" {
  name = "/ecs/tmp/${var.user_id}-${local.prefix}"

  retention_in_days = 1
}
