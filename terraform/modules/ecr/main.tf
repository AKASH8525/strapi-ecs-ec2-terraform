resource "aws_ecr_repository" "this" {
  name                 = "${var.project_name}-repo"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  force_delete = true   # helpful for personal account cleanup

  tags = {
    Name = "${var.project_name}-ecr"
  }
}