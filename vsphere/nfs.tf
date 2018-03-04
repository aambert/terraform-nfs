variable "vsphere_user" {}
variable "vsphere_password" {}
variable "vsphere_server" {}
variable "vsphere_datacenter" {}
variable "vsphere_datastore" {}
variable "vsphere_resource_pool" {}
variable "vsphere_network" {}
variable "vm_template" {}
variable "vm_name" {}
variable "vm_vcpu" {}
variable "vm_memory" {}
variable "vm_disk1_size" {}
variable "vm_domain" {}
variable "vm_time_zone" {}
variable "hacluster_password" {}
variable "hacluster_vip" {}
variable "jc_x_connect_key" {}

provider "vsphere" {
  version        = "~> 1.3"
  user           = "${var.vsphere_user}"
  password       = "${var.vsphere_password}"
  vsphere_server = "${var.vsphere_server}"

  # if you have a self-signed cert
  allow_unverified_ssl = true
}

data "vsphere_datacenter" "dc" {
  name = "${var.vsphere_datacenter}"
}

data "vsphere_datastore" "datastore" {
  name          = "${var.vsphere_datastore}"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_resource_pool" "pool" {
  name          = "${var.vsphere_resource_pool}"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_network" "network" {
  name          = "${var.vsphere_network}"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_virtual_machine" "template" {
  name          = "${var.vm_template}"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

resource "vsphere_virtual_machine" "vm" {
  count            = "2"
  name             = "${var.vm_name}${count.index}"
  resource_pool_id = "${data.vsphere_resource_pool.pool.id}"
  datastore_id     = "${data.vsphere_datastore.datastore.id}"

  num_cpus = "${var.vm_vcpu}"
  memory   = "${var.vm_memory}"
  guest_id = "${data.vsphere_virtual_machine.template.guest_id}"

  scsi_type = "${data.vsphere_virtual_machine.template.scsi_type}"

  network_interface {
    network_id     = "${data.vsphere_network.network.id}"
    adapter_type   = "${data.vsphere_virtual_machine.template.network_interface_types[0]}"
    use_static_mac = true
    mac_address    = "${lookup(var.instance_macs, count.index)}"
  }

  disk {
    label            = "disk0"
    size             = "${data.vsphere_virtual_machine.template.disks.0.size}"
    eagerly_scrub    = "${data.vsphere_virtual_machine.template.disks.0.eagerly_scrub}"
    thin_provisioned = "${data.vsphere_virtual_machine.template.disks.0.thin_provisioned}"
  }

  disk {
    label            = "disk1"
    size             = "${var.vm_disk1_size}"
    eagerly_scrub    = false
    thin_provisioned = true
    unit_number      = 1
  }

  clone {
    template_uuid = "${data.vsphere_virtual_machine.template.id}"

    customize {
      linux_options {
        host_name = "${var.vm_name}${count.index}"
        domain    = "${var.vm_domain}"
        time_zone = "${var.vm_time_zone}"
      }

      network_interface {}
    }
  }

  # Run commands with remote-exec over ssh
  provisioner "remote-exec" {
    inline = [
      #"sudo hostnamectl set-hostname ${var.vm_name}.${var.vm_domain}",
      #"sudo sed -i '2i 127.0.0.1       ${var.vm_name}.${var.vm_domain}' /etc/hosts",
      #"sudo sed -i '3d' /etc/hosts",
      "sudo apt-get update",
      "sudo apt-get upgrade -y",
      "sudo apt-get autoremove -y",
      #"sudo mkdir -p /var/lib/postgresql/${var.postgresql_version}",
      #"sudo mkfs.ext4 /dev/sdb",
      #"UUID=$(sudo blkid -o value -s UUID /dev/sdb)",
      #"echo \"UUID=$UUID /var/lib/postgresql/${var.postgresql_version} ext4 defaults 0 0\" | sudo tee -a /etc/fstab",
      #"sudo mount -a",
      #"sudo groupadd --gid 120 postgres",
      #"sudo adduser --gid 120 --uid 120 --disabled-password -gecos \"PostgreSQL\" postgres",
      #"sudo chmod 0700 /var/lib/postgresql/${var.postgresql_version}",
      #"sudo chown -R postgres:postgres /var/lib/postgresql/${var.postgresql_version}",
      "sudo apt-get install -qy python-pip",
      "sudo pip install suds-jurko",
      "sudo pip install requests",
      "sudo apt-get install -qy pcs pacemaker fence-agents",
      "MYIP=$(ifconfig ens160 | grep 'inet addr' | cut -d ':' -f 2 | cut -d ' ' -f 1)",
      "echo \"# Disable IPv6\" | sudo tee -a /etc/default/pcsd",
      "echo \"PCSD_BIND_ADDR='$MYIP'\" | sudo tee -a /etc/default/pcsd",
      "printf '${var.hacluster_password}\n${var.hacluster_password}' | sudo passwd hacluster",
      "sudo systemctl start pcsd",
      "sudo systemctl enable pcsd",
      "sudo systemctl enable corosync",
      "sudo systemctl enable pacemaker",
      "echo Automate me please",
      #"sudo pcs cluster auth nfs0.${var.vm_domain} nfs1.${var.vm_domain}",
      #"sudo pcs cluster setup --name nfs_cluster nfs0.${var.vm_domain} nfs1.${var.vm_domain}",
      #"sudo pcs cluster start --all",
      #"sudo pcs property set stonith-enabled=false",
      #"sudo pcs property set no-quorum-policy=ignore",
      #"sudo pcs resource create virtual_ip ocf:heartbeat:IPaddr2 ip=${var.hacluster_vip} cidr_netmask=32 op monitor interval=30s",
      #"curl --silent --show-error --header 'x-connect-key: ${var.jc_x_connect_key}' https://kickstart.jumpcloud.com/Kickstart | sudo bash",
      #"sudo rm -f 2",
      "sudo rm -f /home/ubuntu/shutdown.sh",
    ]
  }

  connection {
    type        = "ssh"
    private_key = "${file("~/.ssh/id_rsa")}"
    user        = "ubuntu"
    agent       = false
  }
}
