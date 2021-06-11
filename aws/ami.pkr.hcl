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
  default = "ubuntu-docker"
}

variable "iam_role" {
  type    = string
  default = "arn:aws:iam::393788435358:role/DelegatedAdministrator"
}

variable "docker_package_version" {
  type    = string
  default = "18.06.1~ce~3-0~ubuntu"
}

source "amazon-ebs" "ubuntu" {
  ami_name      = "${var.ami_prefix}-${local.timestamp}"
  instance_type = "t2.micro"
  region        = "us-east-1"

  tags = {
    os_name           = "ubuntu"
    base_ami_id       = "{{ .SourceAMI }}"
    base_ami_name     = "{{ .SourceAMIName }}"
    base_ami_creation = "{{ .SourceAMICreationDate }}"
    base_ami_owner    = "{{ .SourceAMIOwnerName }}"
  }

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
  sources = ["amazon-ebs.ubuntu"]

  provisioner "ansible" {
    playbook_file = "./provision.yaml"
    extra_arguments = [
      "--extra-vars",
      "docker_package_version=${var.docker_package_version}"
    ]
  }

  post-processor "manifest" {
    output     = "manifest.json"
    strip_path = true
    custom_data = {
      source_ami_id       = "${build.SourceAMI}"
      source_ami_name     = "${build.SourceAMIName}"
      source_ami_creation = "${build.SourceAMICreationDate}"
      source_ami_owner    = "${build.SourceAMIOwnerName}"
    }
  }
}