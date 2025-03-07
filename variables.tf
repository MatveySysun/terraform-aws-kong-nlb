# Network settings
variable "vpc_name" {
  description = "VPC Name for the AWS account and region specified"
  type        = string
}

variable "vpc_id" {
  description = "VPC Id for the AWS account and region specified"
  type        = string
}

variable "vpc_cidr_block" {
  description = "VPC cidr block for the AWS account and region specified"
  type        = string
}

variable "aws_private_subnet_ids" {
  description = "Private subnet Ids"
  type        = list(string)
}

variable "aws_public_subnet_ids" {
  description = "Private subnet Ids"
  type        = list(string)
}


variable "subnet_tag" {
  description = "Tag used on subnets to define Tier"
  type        = string

  default = "Tier"
}

variable "private_subnets" {
  description = "Subnet tag on private subnets"
  type        = string

  default = "private"
}

variable "public_subnets" {
  description = "Subnet tag on public subnets for external load balancers"
  type        = string

  default = "public"
}

variable "default_security_group_name" {
  description = "Name of the default VPC security group for EC2 access"
  type        = string

  default = "default"
}

variable "default_security_group_id" {
  description = "Id of the default VPC security group for EC2 access"
  type        = string

  default = "default"
}


# Access control
variable "bastion_cidr_blocks" {
  description = "Bastion hosts allowed access to PostgreSQL and Kong Admin"
  type        = list(string)

  default = [
    "127.0.0.1/32",
  ]
}

variable "external_cidr_blocks" {
  description = "External ingress access to Kong Proxy via the load balancer"
  type        = list(string)

  default = [
    "0.0.0.0/0",
  ]
}

variable "internal_http_cidr_blocks" {
  description = "Internal ingress access to Kong Proxy via the load balancer (HTTP)"
  type        = list(string)

  default = [
    "0.0.0.0/0",
  ]
}

variable "internal_https_cidr_blocks" {
  description = "Internal ingress access to Kong Proxy via the load balancer (HTTPS)"
  type        = list(string)

  default = [
    "0.0.0.0/0",
  ]
}

variable "admin_cidr_blocks" {
  description = "Access to Kong Admin API (Enterprise Edition only)"
  type        = list(string)

  default = [
    "0.0.0.0/0",
  ]
}

variable "manager_cidr_blocks" {
  description = "Access to Kong Manager (Enterprise Edition only)"
  type        = list(string)

  default = [
    "0.0.0.0/0",
  ]
}

variable "portal_cidr_blocks" {
  description = "Access to Portal (Enterprise Edition only)"
  type        = list(string)

  default = [
    "0.0.0.0/0",
  ]
}

variable "manager_host" {
  description = "Hostname to access Kong Manager (Enterprise Edition only)"
  type        = string

  default = "default"
}

variable "portal_host" {
  description = "Hostname to access Portal (Enterprise Edition only)"
  type        = string

  default = "default"
}

variable "orch_host" {
  description = "Orchestrator hostname"
  type        = string

  default = "default"
}


# Required tags
variable "description" {
  description = "Resource description tag"
  type        = string

  default = "Kong API Gateway"
}

variable "environment" {
  description = "Resource environment tag (i.e. dev, stage, prod)"
  type        = string
}

variable "service" {
  description = "Resource service tag"
  type        = string

  default = "kong"
}

# Additional tags
variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)

  default = {}
}

# Enterprise Edition
variable "enable_ee" {
  description = "Boolean to enable Kong Enterprise Edition settings"
  type        = string

  default = false
}

variable "ee_bintray_auth" {
  description = "Bintray authentication for the Enterprise Edition download (Format: username:apikey)"
  type        = string

  default = "placeholder"
}

variable "ee_license" {
  description = "Enterprise Edition license key (JSON format)"
  type        = string

  default = "placeholder"
}

# EC2 settings

# https://wiki.ubuntu.com/Minimal
variable "ec2_ami" {
  description = "Map of Ubuntu Minimal AMIs by region"
  type        = map(string)

  default = {
    # Image information:
    # ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-20210325 - ami-04cc2b0ad9e30a9c8
    # Canonical, Ubuntu, 20.04 LTS, amd64 focal image build on 2021-03-25
    # Root device type: ebs Virtualization type: hvm ENA Enabled: Yes
    us-east-1 = "ami-04cc2b0ad9e30a9c8"
  }
}

variable "ec2_instance_type" {
  description = "EC2 instance type"
  type        = string

  default = "t2.micro"
}

variable "ec2_root_volume_size" {
  description = "Size of the root volume (in Gigabytes)"
  type        = string

  default = 8
}

variable "ec2_root_volume_type" {
  description = "Type of the root volume (standard, gp2, or io)"
  type        = string

  default = "gp2"
}

variable "ec2_root_volume_encryption" {
  description = "Should encrypt ec2 root volume"
  type        = bool

  default = true
}

variable "ec2_key_name" {
  description = "AWS SSH Key"
  type        = string

  default = ""
}

variable "asg_max_size" {
  description = "The maximum size of the auto scale group"
  type        = string

  default = 3
}

variable "asg_min_size" {
  description = "The minimum size of the auto scale group"
  type        = string

  default = 1
}

variable "asg_desired_capacity" {
  description = "The number of instances that should be running in the group"
  type        = string

  default = 2
}

variable "asg_health_check_grace_period" {
  description = "Time in seconds after instance comes into service before checking health"
  type        = string

  # Terraform default is 300
  default = 300
}

# Kong packages
variable "ee_pkg" {
  description = "Url for Enterprise Edition package matching the OS distro"
  type        = string

  default = "https://download.konghq.com/gateway-2.x-ubuntu-focal/pool/all/k/kong-enterprise-edition/kong-enterprise-edition_2.3.3.0_all.deb"
}

variable "ce_pkg" {
  description = "Url for Community Edition package matching the OS distro"
  type        = string

  # default = "https://download.konghq.com/gateway-2.x-ubuntu-focal/pool/all/k/kong/kong_2.3.3_amd64.deb"
  default = "https://download.konghq.com/gateway-2.x-ubuntu-focal/pool/all/k/kong/kong_2.8.0_amd64.deb"
}

# Load Balancer settings
variable "enable_external_lb" {
  description = "Boolean to enable/create the external load balancer, exposing Kong to the Internet"
  type        = string

  default = true
}

variable "enable_internal_lb" {
  description = "Boolean to enable/create the internal load balancer for the forward proxy"
  type        = string

  default = true
}

variable "enable_external_lb_alarms" {
  description = "Boolean to enable/create the external load balancer alarms"
  type        = string

  default = true
}

variable "enable_internal_lb_alarms" {
  description = "Boolean to enable/create the internal load balancer alarms"
  type        = string

  default = true
}

variable "lb_creation_timeout" {
  description = "Timeout for creating load balancers"
  type        = string

  default = "20m"
}

variable "lb_deletion_timeout" {
  description = "Timeout for deleting load balancers"
  type        = string

  default = "20m"
}

variable "deregistration_delay" {
  description = "Seconds to wait before changing the state of a deregistering target from draining to unused"
  type        = string

  # Terraform default is 300
  default = 300
}

variable "enable_deletion_protection" {
  description = "Boolean to enable delete protection on the ALB"
  type        = string

  # Terraform default is false
  default = true
}

variable "health_check_healthy_threshold" {
  description = "Number of consecutives checks before a unhealthy target is considered healthy"
  type        = string

  # Terraform default is 5
  default = 3
}

variable "health_check_interval" {
  description = "Seconds between health checks"
  type        = string

  # Terraform default is 30
  default = 30
}

variable "health_check_matcher" {
  description = "HTTP Code(s) that result in a successful response from a target (comma delimited)"
  type        = string

  default = 200
}

variable "health_check_timeout" {
  description = "Seconds waited before a health check fails"
  type        = string

  # Terraform default is 5
  default = 6
}

variable "health_check_unhealthy_threshold" {
  description = "Number of consecutive checks before considering a target unhealthy"
  type        = string

  # Terraform default is 2
  default = 3
}

variable "idle_timeout" {
  description = "Seconds a connection can idle before being disconnected"
  type        = string

  # Terraform default is 60
  default = 60
}

variable "ssl_cert_external_arn" {
  description = "SSL certificate ARN for the external Kong Proxy HTTPS listener"
  type        = string
}

variable "ssl_cert_internal_arn" {
  description = "SSL certificate ARN for the internal Kong Proxy HTTPS listener"
  type        = string
}

variable "ssl_cert_admin_domain" {
  description = "SSL certificate domain name for the Kong Admin API HTTPS listener"
  type        = string
}

variable "ssl_policy" {
  description = "SSL Policy for HTTPS Listeners"
  type        = string

  default = "ELBSecurityPolicy-TLS-1-2-2017-01"
}

# Cloudwatch alarms
variable "cloudwatch_actions" {
  description = "List of cloudwatch actions for Alert/Ok"
  type        = list(string)

  default = []
}

variable "http_4xx_count" {
  description = "HTTP Code 4xx count threshhold"
  type        = string

  default = 50
}

variable "http_5xx_count" {
  description = "HTTP Code 5xx count threshhold"
  type        = string

  default = 50
}

variable "response_time_avg" {
  description = "Response time average threshhold in milliseconds"
  type        = string

  default = 1000
}



# Datastore settings
variable "enable_rds" {
  description = "Boolean to enable rds"
  type        = string

  default = "true"
}

variable "enable_aurora" {
  description = "Boolean to enable Aurora"
  type        = string

  default = "false"
}

variable "db_engine_version" {
  description = "Database engine version"
  type        = string

  default = "11.4"
}

variable "db_engine_mode" {
  description = "Engine mode for Aurora"
  type        = string

  default = "provisioned"
}

variable "db_family" {
  description = "Database parameter group family"
  type        = string

  default = "postgres11"
}

variable "db_instance_class" {
  description = "Database instance class"
  type        = string

  default = "db.t2.micro"
}

variable "db_instance_count" {
  description = "Number of database instances (0 to leverage an existing db)"
  type        = string

  default = 1
}

variable "db_storage_size" {
  description = "Size of the database storage in Gigabytes"
  type        = string

  # 100 is the recommended AWS minimum
  default = 100
}

variable "db_storage_type" {
  description = "Type of the database storage"
  type        = string

  default = "gp2"
}

variable "db_storage_encrypted" {
  description = "Specifies whether the database instance is encrypted"
  type        = string

  default = true
}

variable "db_kms_key_id" {
  description = "The ARN for the KMS encryption key. If creating an encrypted replica, set this to the destination KMS ARN. If db_storage_encrypted is set to true and kms_key_id is not specified the default KMS key created in your account will be used"
  type        = string

  default = ""
}

variable "db_username" {
  description = "Database master username"
  type        = string

  default = "root"
}

variable "db_subnets" {
  description = "Database instance subnet group name"
  type        = string

  default = "db-subnets"
}

variable "db_multi_az" {
  description = "Boolean to specify if RDS is multi-AZ"
  type        = string

  default = false
}

variable "db_backup_retention_period" {
  description = "The number of days to retain backups"
  type        = string

  default = 7
}

# Redis settings (for rate_limiting only)
variable "enable_redis" {
  description = "Boolean to enable redis AWS resource"
  type        = string

  default = false
}

variable "redis_instance_type" {
  description = "Redis node instance type"
  type        = string

  default = "cache.t2.small"
}

variable "redis_engine_version" {
  description = "Redis engine version"
  type        = string

  default = "5.0.5"
}

variable "redis_family" {
  description = "Redis parameter group family"
  type        = string

  default = "redis5.0"
}

variable "redis_instance_count" {
  description = "Number of redis nodes"
  type        = string

  default = 2
}

variable "redis_subnets" {
  description = "Redis cluster subnet group name"
  type        = string

  default = "cache-subnets"
}

variable "deck_version" {
  description = "Version of decK to install"
  type        = string

  default = "1.5.1"
}

variable "db_final_snapshot_identifier" {
  description = "The final snapshot name of the RDS instance when it gets destroyed"
  type        = string
  default     = ""
}

# Module dependencies
variable "module_dependencies" {
  description = "Variable to force the module to wait for other resources to finish creation"
  type        = any
  default     = null
}

variable "admin_user" {
  description = "The user name for Kong admin user"
  type        = string
  default     = "kong-admin"
}

variable "lb_logging_bucket" {
  description = "The s3 bucket which LB access logs should be stored to"
  type        = string

  default = ""
}

variable "external_lb_logging_prefix" {
  description = "s3 prefix for the external LB access logs"
  type        = string

  default = ""
}

variable "drop_invalid_header_fields" {
  description = "Drop invalid headers in LB"
  type        = bool

  default = false
}

variable "cloudwatch_agent_system_config" {
  description = "Cloudwatch Agent Config for system metrics"
  type        = string

  # set non-existent parameter name to avoid granting broad permissions
  default = "non-existent-parameter"
}

variable "cloudwatch_agent_kong_config" {
  description = "Cloudwatch Agent Config for Kong"
  type        = string

  # set non-existent parameter name to avoid granting broad permissions
  default = "non-existent-parameter"
}

variable "external_lb_deny_paths" {
  description = "List of path to deny access from public internet (works together with external_lb_deny_methods)"
  type        = list(string)
  default     = []
}

variable "external_lb_deny_methods" {
  description = "List of methods to deny access from public internet (works together with external_lb_deny_paths)"
  type        = list(string)
  default     = []
}
