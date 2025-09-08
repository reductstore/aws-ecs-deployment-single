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
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.11.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_ecs"></a> [ecs](#module\_ecs) | ./modules/ecs | n/a |
| <a name="module_load_balancer"></a> [load\_balancer](#module\_load\_balancer) | ./modules/load_balancer | n/a |
| <a name="module_networking"></a> [networking](#module\_networking) | ./modules/networking | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_ecs_service.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service) | resource |
| [aws_ecs_task_definition.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_task_definition) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_private_subnet_ids"></a> [private\_subnet\_ids](#input\_private\_subnet\_ids) | n/a | `list(string)` | n/a | yes |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | n/a | `string` | `"reduct"` | no |
| <a name="input_public_subnet_ids"></a> [public\_subnet\_ids](#input\_public\_subnet\_ids) | n/a | `list(string)` | n/a | yes |
| <a name="input_reduct_api_token"></a> [reduct\_api\_token](#input\_reduct\_api\_token) | n/a | `string` | n/a | yes |
| <a name="input_reduct_image"></a> [reduct\_image](#input\_reduct\_image) | n/a | `string` | `"reductstore/reductstore:latest"` | no |
| <a name="input_reduct_log_level"></a> [reduct\_log\_level](#input\_reduct\_log\_level) | n/a | `string` | `"info"` | no |
| <a name="input_region"></a> [region](#input\_region) | n/a | `string` | `"eu-central-1"` | no |
| <a name="input_s3_access_key"></a> [s3\_access\_key](#input\_s3\_access\_key) | n/a | `string` | n/a | yes |
| <a name="input_s3_bucket"></a> [s3\_bucket](#input\_s3\_bucket) | n/a | `string` | n/a | yes |
| <a name="input_s3_region"></a> [s3\_region](#input\_s3\_region) | n/a | `string` | n/a | yes |
| <a name="input_s3_secret_key"></a> [s3\_secret\_key](#input\_s3\_secret\_key) | n/a | `string` | n/a | yes |
| <a name="input_task_cpu"></a> [task\_cpu](#input\_task\_cpu) | n/a | `number` | `2` | no |
| <a name="input_task_memory"></a> [task\_memory](#input\_task\_memory) | n/a | `number` | `1024` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | n/a | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_alb_dns_name"></a> [alb\_dns\_name](#output\_alb\_dns\_name) | n/a |
| <a name="output_service_name"></a> [service\_name](#output\_service\_name) | n/a |
<!-- END_TF_DOCS -->
