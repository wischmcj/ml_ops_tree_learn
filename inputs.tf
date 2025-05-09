#Digital Ocean settings 
variable "do_token" {}
variable "do_pvt_key" {}
variable "do_pub_key" {}
variable "do_region" {}
variable "do_host_type" {}
variable "volume_id" {
  default = ""
}
variable "volume_snapshot_id" {
  default = ""
}
variable "droplet_snapshot_id" {
  default = ""
}

# Pipeline Configuration
variable "forest_file_name" {}
variable "weights_path" {}
variable "forest_data_path" {}
variable "root_vol" {}
variable "local_ip" {}
variable "local_user" {}
variable "local_data_dir" {}
variable "save_format" {}
variable "return_type" {}
variable "config_path" {}
variable "start_at" {}

# TreeLearn Configuration
variable "data_url" {}
variable "tree_learn_repo" {}
variable "example_forest_url" {}

# Droplet Configuration
variable "instance_name_prefix" {
  default = "tree-learner"
}

variable "droplet_image" {
  default = "ubuntu-20-04-x64"
  # default = "gpu-h100x8-base"
}