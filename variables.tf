variable "environment" {
  type        = string
  description = "nASG environment"
  default     = "prd"
  validation {
    condition     = can(regex("(dev|uat|ua2|prd)", var.environment))
    error_message = "Environment must be one of: dev, uat, ua2, prd."
  }
}

variable "auto_update" {
  type        = string
  description = "Whether to update the stack automatically when a new version is released or not"
  default     = "false"
  validation {
    condition     = can(regex("(true|false)", var.auto_update))
    error_message = "AutoUpdate must be either true or false."
  }
}

variable "exclude_regions" {
  type        = string
  description = "Comma-separated list of AWS region codes to exclude from deployment (e.g., us-west-1,eu-west-3)."
  default     = ""
  validation {
    condition     = can(regex("^$|((us|af|ap|ca|cn|eu|il|me|sa)-(northwest|east|west|north|south|central|northeast|southeast)-[0-9])(,((us|af|ap|ca|cn|eu|il|me|sa)-(northwest|east|west|north|south|central|northeast|southeast)-[0-9]))*$", var.exclude_regions))
    error_message = "Must be a comma-separated list of valid AWS region codes (e.g., us-east-1,eu-central-1,ap-southeast-1) or left blank for no exclusions."
  }
}

variable "memory_size" {
  type        = number
  description = "Lambda function total memory in MB"
  default     = 2048
  validation {
    condition     = var.memory_size >= 512 && var.memory_size <= 10240
    error_message = "Memory size must be between 512 and 10240 MB."
  }
}

variable "token" {
  type        = string
  description = "Nops Client Token"
  sensitive   = true
}

variable "timeout" {
  type        = number
  description = "Lambda function timeout in seconds"
  default     = 900
  validation {
    condition     = var.timeout >= 240 && var.timeout <= 900
    error_message = "Timeout must be between 240 and 900 seconds."
  }
}
