variable "access_key" {}
variable "secret_key" {}
variable "region" {}
variable "public_key_path" {}
variable "certificate_arn" {}
variable "route53_hosted_zone_name" {}
variable "subdomain_name" {}
variable "ecr_repository" {}
variable "allowed_cidr_blocks" {
  type = list(string)
}
variable "amis" {
  type = map(string)
}
variable "instance_type" {}
variable "autoscaling_group_min_size" {}
variable "autoscaling_group_max_size" {}