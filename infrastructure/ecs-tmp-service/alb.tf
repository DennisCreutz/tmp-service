resource "aws_lb_listener_rule" "tmp_service" {
  listener_arn = data.terraform_remote_state.ecs.outputs.alb_listener_arn

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ecs_tmp_service.arn
  }

  condition {
    path_pattern {
      values = ["/tmp/${var.service_id}"]
    }
  }
}

resource "aws_lb_target_group" "ecs_tmp_service" {
  name = local.prefix

  target_type = "ip"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = data.terraform_remote_state.ecs.outputs.vpc_id

  deregistration_delay = "0"

  health_check {
    enabled             = true
    interval            = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 4
  }
}
