resource "digitalocean_volume" "tlvol" {
  region = "${var.do_region}"
  name                    = "tlvol"
  size                    = 100
  initial_filesystem_type = "ext4"
  description             = "main volume for persisting data "
}

resource "digitalocean_droplet" "tree_learner" {
  image  = "${var.droplet_image}"
  name   = "${var.instance_name_prefix}-treelearn"
  region = "${var.do_region}"
  size   = "${var.do_host_type}"
  # ssh_keys = "${split(",", var.do_ssh_keys)}"
  # ssh_keys = [data.digitalocean_ssh_key.example.id]
  ssh_keys = [
    data.digitalocean_ssh_key.example.id
  ]
  provisioner "remote-exec" {
    # needed to ensure that drop is available before local-exec
    connection {
      host = self.ipv4_address
      user = "root"
      type = "ssh"
      private_key = file(var.do_pvt_key)
      timeout = "1m"
    }
    inline = [
      "mkdir /TreeLearn || true",
      "chmod -R 777 /TreeLearn || true",
      "while sudo lsof /var/lib/dpkg/lock-frontend; do echo 'Waiting for apt to finish...'; sleep 5; done"
    ]
  }

  # provisioner "file" {
  #   content = templatefile("env",
  #   {
  #       downloader = "${var.warrior_downloader}"
  #       project = "${var.warrior_project}"
  #       username = "${var.warrior_username}"
  #       password = "${var.warrior_password}"
  #       concurrency = "${var.warrior_concurrency}"
  #   })
  #   destination = "/tmp/env"
  # }
  # provisioner "file" {
  #   # content = file("loop_and_log.sh")
  #   content = templatefile("start.sh",
  #   {
  #     warriors = "${var.warriors_per_host}"
  #   })
  #   destination = "/tmp/start.sh"
  # # }
  # provisioner "remote-exec" {
  #   # Stops container named exporter if running 
  #   # Starts instance of node-exporter, which monitors 
  #   #  the warrior container, returning metrics to prometheus
  #   inline = [
  #     # "docker stop exporter && docker rm exporter || true",
  #     # "docker run -d --name exporter --net=host --pid=host -v '/:/host:ro,rslave'  prom/node-exporter --path.rootfs /host",
  #     "chmod +x /tmp/start.sh",
  #     "/tmp/start.sh",
  #   ]
  # }
}

resource "digitalocean_volume_attachment" "tlvol_attache" {
  droplet_id = digitalocean_droplet.tree_learner.id
  volume_id  = digitalocean_volume.tlvol.id
}

# Init scripts install docker and the digital ocean agent
#     the latter sends exe metrics (cpu, bandwidth, etc) to DO
resource "null_resource" "basic_init"{
  depends_on = [digitalocean_droplet.tree_learner]
  count  = "${var.do_observers}"
  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u root -i '${element(digitalocean_droplet.tree_learner.*.ipv4_address, count.index)},'  --private-key ${var.do_pvt_key} -e 'pub_key=${var.do_pub_key}' ansible/playbooks/apt_setup.yml"
  }
}

resource "null_resource" "tree_learner_init"{
  depends_on = [null_resource.basic_init] 
  count  = "${var.do_observers}"
  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u root -i '${element(digitalocean_droplet.tree_learner.*.ipv4_address, count.index)},'  --private-key ${var.do_pvt_key} ansible/playbooks/tree_learner.yml"
  }
}

# resource "null_resource" "prometheus_setup_as_target"{
#   depends_on = [null_resource.warrior]
#   count  = "${var.do_observers}"
#   provisioner "local-exec" {
#     command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u root -i '${element(digitalocean_droplet.prometheus.*.ipv4_address, count.index)},' --private-key ${var.do_pvt_key} -e 'pub_key=${var.do_pub_key}' ansible/playbooks/target_nodes.yml"
#   }
# }
