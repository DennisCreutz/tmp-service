resource "aws_efs_access_point" "service_dir" {
  file_system_id = data.terraform_remote_state.ecs.outputs.efs_id

  posix_user {
    gid = 1000
    uid = 1000
  }

  root_directory {
    path = "/${var.service_id}"
  }
}
