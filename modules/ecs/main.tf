# -------------------------
# ECS: Cluster, Roles, Task, Service
# -------------------------
resource "aws_ecs_cluster" "this" {
  name = "${var.name}-cluster"
}

data "aws_iam_policy_document" "task_execution_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "task_execution" {
  name               = "${var.name}-task-exec"
  assume_role_policy = data.aws_iam_policy_document.task_execution_assume.json
}

# Allow pulling from ECR/Public and writing logs
resource "aws_iam_role_policy_attachment" "task_exec_policy" {
  role       = aws_iam_role.task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# S3 access when S3 backend is enabled
data "aws_iam_policy_document" "task_extra" {
  statement {
    sid     = "AllowS3"
    effect  = "Allow"
    actions = ["s3:GetObject", "s3:PutObject", "s3:ListBucket", "s3:DeleteObject"]
    resources = [
      "arn:aws:s3:::${var.s3_bucket}",
      "arn:aws:s3:::${var.s3_bucket}/*"
    ]
  }
}

resource "aws_iam_role" "task_role" {
  name               = "${var.name}-task"
  assume_role_policy = data.aws_iam_policy_document.task_execution_assume.json
}

resource "aws_iam_role_policy" "task_extra" {
  name   = "${var.name}-task-extra"
  role   = aws_iam_role.task_role.id
  policy = data.aws_iam_policy_document.task_extra.json
}

# CloudWatch Logs
resource "aws_cloudwatch_log_group" "this" {
  name              = "/ecs/${var.name}"
  retention_in_days = 14
}
