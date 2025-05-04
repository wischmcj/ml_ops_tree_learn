variable "do_token" {}
variable "do_pvt_key" {}
variable "do_pub_key" {}

variable "do_ssh_keys" {}
variable "do_hosts" {}
variable "do_observers" {}
variable "do_region" {}
variable "do_host_type" {}
variable "do_key_password" {}
variable "instance_name_prefix" {
  default = "tree-learner"
}

variable "droplet_image" {
  default = "ubuntu-20-04-x64"
  # default = "gpu-h100x8-base"
}