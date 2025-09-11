# aws-ecs-deployment-single

Single-node ReductStore deployment on AWS ECS with Terraform

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.6.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.12.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_backup_service"></a> [backup\_service](#module\_backup\_service) | ./modules/backup_service | n/a |
| <a name="module_ecs"></a> [ecs](#module\_ecs) | ./modules/ecs | n/a |
| <a name="module_load_balancer"></a> [load\_balancer](#module\_load\_balancer) | ./modules/load_balancer | n/a |
| <a name="module_networking"></a> [networking](#module\_networking) | ./modules/networking | n/a |
| <a name="module_s3"></a> [s3](#module\_s3) | ./modules/s3 | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_ecs_service.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service) | resource |
| [aws_ecs_task_definition.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_task_definition) | resource |
| [aws_service_discovery_private_dns_namespace.ns](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/service_discovery_private_dns_namespace) | resource |
| [aws_service_discovery_service.main_svc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/service_discovery_service) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Project name, used as prefix for resources | `string` | `"reduct"` | no |
| <a name="input_reduct_api_token"></a> [reduct\_api\_token](#input\_reduct\_api\_token) | ReductStore API token for admin access | `string` | n/a | yes |
| <a name="input_reduct_log_level"></a> [reduct\_log\_level](#input\_reduct\_log\_level) | ReductStore log level (e.g., DEBUG, INFO, WARNING, ERROR) | `string` | `"INFO"` | no |
| <a name="input_reduct_tag"></a> [reduct\_tag](#input\_reduct\_tag) | n/a | `string` | `"main"` | no |
| <a name="input_region"></a> [region](#input\_region) | AWS region | `string` | `"eu-central-1"` | no |
| <a name="input_resilient_model"></a> [resilient\_model](#input\_resilient\_model) | Resilient model for ReductStore (e.g., simple, hot-backup | `string` | `"simple"` | no |
| <a name="input_s3_region"></a> [s3\_region](#input\_s3\_region) | AWS region for the S3 bucket (if different from main region) | `string` | `""` | no |
| <a name="input_task_cpu"></a> [task\_cpu](#input\_task\_cpu) | Number of CPU units for the ECS task | `number` | `1024` | no |
| <a name="input_task_memory"></a> [task\_memory](#input\_task\_memory) | Amount of memory (in MiB) for the ECS task | `number` | `2048` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_alb_dns_name"></a> [alb\_dns\_name](#output\_alb\_dns\_name) | n/a |
| <a name="output_service_name"></a> [service\_name](#output\_service\_name) | n/a |
<!-- END_TF_DOCS -->
