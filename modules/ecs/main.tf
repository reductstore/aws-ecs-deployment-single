# -------------------------
# ECS: Cluster, Roles, Task, Service
# -------------------------
resource "aws_ecs_cluster" "this" {
  name = "${var.project_name}_cluster"
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
  name               = "${var.project_name}_task_exec"
  assume_role_policy = data.aws_iam_policy_document.task_execution_assume.json
}

# Allow pulling from ECR/Public and writing logs
resource "aws_iam_role_policy_attachment" "task_exec_policy" {
  role       = aws_iam_role.task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "task_role" {
  name               = "${var.project_name}_task"
  assume_role_policy = data.aws_iam_policy_document.task_execution_assume.json
}


# CloudWatch Logs
resource "aws_cloudwatch_log_group" "this" {
  name              = "/ecs/${var.project_name}"
  retention_in_days = 14
}
