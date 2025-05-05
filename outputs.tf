output "droplet_ip" {
  value = "${digitalocean_droplet.tree_learner.ipv4_address}"
}
output "droplet_id" {
  value = "${digitalocean_droplet.tree_learner.id}"
}
output "volume_id" {
  value = "${digitalocean_volume.tlvol.id}"
}