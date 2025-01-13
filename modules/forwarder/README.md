# nOps AWS Compute Copilot Onboarding Forwarder Terraform Module

## Description
This submodule creates the event listeners and rules to send events to the nOps ASG lambda on the central region

## Prerequisites

- Terraform v1.0+
- AWS CLI configured with appropriate permissions
- nOps API key

## Usage

```hcl
terraform {
  required_providers {
    nops = {
      source = "nops-io/nops"
    }
    aws = {
      source  = "hashicorp/aws"
    }
  }
}

provider "nops" {
  nops_api_key = "XXXX.XXXXXX"
}

module "cc_asg_forwarder" {
  source = "nops-io/nops-compute-copilot-asg-onboarding/aws//modules/forwarder"
  # Region where the main module was deployed, either us-east-1 or us-west-2
  nasg_central_region = "us-east-1"
}
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 4.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_event_rule.asg_ec2_spot_termination_warning](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_rule) | resource |
| [aws_cloudwatch_event_rule.ec2_instance_instance_state_change](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_rule) | resource |
| [aws_cloudwatch_event_rule.ec2_instance_launch_unsuccessful](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_rule) | resource |
| [aws_cloudwatch_event_target.asg_ec2_spot_termination_target](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target) | resource |
| [aws_cloudwatch_event_target.ec2_instance_launch_unsuccessful_target](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target) | resource |
| [aws_cloudwatch_event_target.ec2_instance_state_change_target](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target) | resource |
| [aws_iam_policy.nasg_eventbus_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.nasg_eventbus_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_nasg_central_region"></a> [nasg\_central\_region](#input\_nasg\_central\_region) | Region where ASG Lambda Function has been deployed | `string` | `"us-east-1"` | no |
| <a name="input_nasg_eventbus_name"></a> [nasg\_eventbus\_name](#input\_nasg\_eventbus\_name) | nOps ASG Event Bus Name | `string` | `"nops-asg-ec2-instance-state-change"` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
