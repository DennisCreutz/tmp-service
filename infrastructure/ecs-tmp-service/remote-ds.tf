data "terraform_remote_state" "ecs" {
  backend = "s3"

  config = {
    bucket = var.ecs_tf_backend_bucket
    region = "eu-central-1"
    key    = var.ecs_tf_backend_key
  }
}

data "terraform_remote_state" "ecr_tmp_service" {
  backend = "s3"

  config = {
    bucket = var.ecr_tf_backend_bucket
    region = "eu-central-1"
    key    = var.ecr_tf_backend_key
  }
}
