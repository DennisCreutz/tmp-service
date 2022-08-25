variable "user_id" {
  description = "User id of the user that requested this service."
  type        = string
}

variable "service_id" {
  description = "The id used for the temp. ECS service."
  type        = string
  validation {
    condition     = length(var.service_id) < 33
    error_message = "service_id must be shorter than 33 characters."
  }
}

variable "ecs_tf_backend_bucket" {
  type = string
}

variable "ecs_tf_backend_key" {
  type = string
}

variable "ecr_tf_backend_bucket" {
  type = string
}

variable "ecr_tf_backend_key" {
  type = string
}

locals {
  stage   = "prod"
  project = "ecs-tmp-services"
  prefix  = var.service_id

  tmp_service_container_name  = "${local.prefix}-tmp"
  tmp_service_efs_volume_name = "lib-dir"
  efs_mount_path              = "/mnt/libs/"

  default_tags = {
    stage        = local.stage
    project      = local.project
    tf_workspace = terraform.workspace
    user_id      = var.user_id
    service_id   = var.service_id
  }
}
