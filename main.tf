#### Volume will remain in digital ocean to avoid having to upload
####  large files each run 

resource "digitalocean_volume" "tlvol" {
  region = "${var.do_region}"
  name                    = "tlvol"
  size                    = 100
  initial_filesystem_type = "ext4"
  description             = "main volume for persisting data"
  snapshot_id           = var.volume_snapshot_id == "" ? null : var.volume_snapshot_id
  # volume_id             = var.volume_id == "" ? null : var.volume_id
}

resource "digitalocean_droplet" "tree_learner" {
  image  = var.droplet_snapshot_id == "" ?  "${var.droplet_image}": var.droplet_snapshot_id
  name   = "${var.instance_name_prefix}-treelearn"
  region = "${var.do_region}"
  size   = "${var.do_host_type}"
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
}

resource "digitalocean_volume_attachment" "tlvol_attache" {
  droplet_id = digitalocean_droplet.tree_learner.id
  volume_id  = var.volume_id == "" ? digitalocean_volume.tlvol.id : var.volume_id
}

# Init scripts install docker and the digital ocean agent
#     the latter sends exe metrics (cpu, bandwidth, etc) to DO
resource "null_resource" "basic_init"{
  depends_on = [digitalocean_droplet.tree_learner, digitalocean_volume_attachment.tlvol_attache]
  count  = 1
  provisioner "local-exec" {
    command = join(" ", ["ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook",
                          "-u root",
                          "-i '${element(digitalocean_droplet.tree_learner.*.ipv4_address, count.index)},'", 
                          "--private-key ${var.do_pvt_key}",
                          "ansible/playbooks/apt_setup.yml"
                          ])
  }
}

resource "null_resource" "tree_learner_init"{
  depends_on = [null_resource.basic_init] 
  count  = 1
  provisioner "local-exec" {
    command = join(" ", ["ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook",
                          "-u root",
                          "-i '${element(digitalocean_droplet.tree_learner.*.ipv4_address, count.index)},'", 
                          "--private-key ${var.do_pvt_key}",
                          # "-e forest_file_name=${var.forest_file_name}",
                          "ansible/playbooks/tree_learner.yml",
                          "--extra-vars '@inputs.tfvars.json'"
                          ])
  }
}

