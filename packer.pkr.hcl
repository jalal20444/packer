packer {
  required_plugins {
    amazon = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

# Variables
variable "region" {}
variable "source_ami" {}
variable "instance_type" {}
variable "vpc_id" {}
variable "subnet_id" {}

# Source builder
source "amazon-ebs" "ubuntu" {
  region        = var.region
  source_ami    = var.source_ami
  instance_type = var.instance_type
  ssh_username  = "ubuntu"

  # AMI name with invalid characters removed
  ami_name = "DevSecOps-AMI-${replace(replace(timestamp(), ":", ""), "T", "-")}"

  vpc_id    = var.vpc_id
  subnet_id = var.subnet_id

  tags = {
    Name = "DevSecOps-AMI"
  }
}

# Build configuration
build {
  sources = ["source.amazon-ebs.ubuntu"]

  provisioner "shell" {
    inline = [
      "sudo apt update -y",
      "sudo apt install -y nginx git",
      "git clone https://github.com/saikiranpi/webhooktesting.git",
      "sudo rm -f /var/www/html/index.nginx-debian.html",
      "sudo cp webhooktesting/index.html /var/www/html/index.nginx-debian.html",
      "sudo cp webhooktesting/style.css /var/www/html/style.css",
      "sudo cp webhooktesting/scorekeeper.js /var/www/html/scorekeeper.js",
      "sudo systemctl enable nginx",
      "sudo systemctl start nginx",
      "curl -fsSL https://get.docker.com | sudo bash"
    ]
  }

  provisioner "file" {
    source      = "docker.service"
    destination = "/tmp/docker.service"
  }

  provisioner "shell" {
    inline = [
      "sudo cp /tmp/docker.service /lib/systemd/system/docker.service",
      "sudo usermod -aG docker ubuntu",
      "sudo systemctl daemon-reload",
      "sudo systemctl restart docker"
    ]
  }
}
