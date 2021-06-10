packer {
  required_plugins {
    amazon = {
      version = ">= 0.0.1"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

locals {
  timestamp = regex_replace(timestamp(), "[- TZ:]", "")
}

variable "ami_prefix" {
  type    = string
  default = "test-luismi"
}

variable "iam_role" {
  type    = string
  default = "arn:aws:iam::393788435358:role/DelegatedAdministrator"
}

variable "docker_package_version" {
  type = string
  default = "18.06.1~ce~3-0~ubuntu"
}

source "amazon-ebs" "ubuntu" {
  ami_name      = "${var.ami_prefix}-${local.timestamp}"
  instance_type = "t2.micro"
  region        = "us-east-1"

  assume_role {
    role_arn     = "${var.iam_role}"
    session_name = "test-ami-build"
  }

  source_ami_filter {
    filters = {
      name                = "ubuntu/images/*ubuntu-xenial-16.04-amd64-server-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["099720109477"]
  }

  ssh_username = "ubuntu"
}

build {
  sources = [
    "source.amazon-ebs.ubuntu"
  ]

  provisioner "ansible" {
    playbook_file = "./provision.yaml"
    extra_arguments = [
      "--extra-vars",
      "docker_package_version=${var.docker_package_version}"
    ]
  }
}