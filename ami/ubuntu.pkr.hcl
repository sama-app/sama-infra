packer {
  required_plugins {
    amazon = {
      version = ">= 0.0.1"
      source = "github.com/hashicorp/amazon"
    }
  }
}

source "amazon-ebs" "ubuntu" {
  //  access_key = var.aws_access_key
  //  secret_key =  var.aws_secret_key
  region = "eu-central-1"
  source_ami = "ami-05f7491af5eef733a"
  instance_type = "t2.micro"
  ssh_username = "ubuntu"
  ami_name = "ubuntu_{{timestamp}}"
  ami_description = "ubuntu docker + new relic (Packer)"

  vpc_id = "vpc-018a52032e267fae5"
  subnet_id = "subnet-02cfec8862ea546a7"

  launch_block_device_mappings {
    device_name = "/dev/sda1"
    volume_size = 8
    volume_type = "gp2"
    delete_on_termination = true
  }
}

build {
  sources = [
    "source.amazon-ebs.ubuntu"
  ]
  provisioner "file" {
    sources = ["install_docker.sh", "install_aws.sh", "install_newrelic.sh", "newrelic-logging.yml", "post_install.sh"]
    destination = "/tmp/"
  }
  provisioner "shell" {
    inline = [
      "cd /tmp",
      "chmod +x *.sh",
      "./install_docker.sh",
      "./install_aws.sh",
      "./install_newrelic.sh",
      "./post_install.sh"
    ]
  }
}