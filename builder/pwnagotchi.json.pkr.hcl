packer {
  required_plugins {
    arm-image = {
      version = ">= 0.2.7"
      source  = "github.com/solo-io/arm-image"
    }
    ansible = {
      version = ">= 1.1.0"
      source  = "github.com/hashicorp/ansible"
    }
  }
}

variable "pwn_hostname" {
  type = string
}

variable "pwn_version" {
  type = string
}

source "arm-image" "rpi-pwnagotchi" {
  iso_checksum      = "file:https://downloads.raspberrypi.org/raspios_lite_arm64/images/raspios_lite_arm64-2023-05-03/2023-05-03-raspios-bullseye-arm64-lite.img.xz.sha256"
  iso_url           = "https://downloads.raspberrypi.org/raspios_lite_arm64/images/raspios_lite_arm64-2023-05-03/2023-05-03-raspios-bullseye-arm64-lite.img.xz"
  output_filename   = "../../../pwnagotchi-raspios-bullseye-${var.pwn_version}-arm64.img"
  qemu_binary       = "qemu-aarch64-static"
  target_image_size = 9368709120
  qemu_args         = ["-r", "6.1.21-v8+"]
}
# "arm-image" "opi-pwnagotchi" {
#  iso_checksum      = ""
#  iso_url           = "https://drive.usercontent.google.com/download?id=12DgsOXXgpDTQLRBsh8cKqVGD2FUUMZDk&export=download&authuser=0&confirm=t&uuid=d97afcec-3979-44e2-838a-f17c576a87fb&at=APZUnTWoYAa6oVoxrZWwPP7o8Hn9:1698613336721"
#  output_file       ="../../../pwnagotchi-orangepi-jammy-${var.pwn_version}-arm64.img"
#  qemu_binary       = "qemu-aarch64-static"
#  target_image_size = 9368709120
#  qemu_args         = ["-r", "6.1.21-v8+"]
#}

# a build block invokes sources and runs provisioning steps on them. The
# documentation for build blocks can be found here:
# https://www.packer.io/docs/from-1.5/blocks/build
build {
  name = "Pwnagotchi Torch 64bit"
  sources = [
    "source.arm-image.rpi-pwnagotchi",
    # "source.arm-image.opi-pwnagotchi",
  ]

  provisioner "file" {
    destination = "/usr/bin/"
    sources     = [
      "../builder/data/usr/bin/pwnlib",
      "../builder/data/usr/bin/bettercap-launcher",
      "../builder/data/usr/bin/pwnagotchi-launcher",
      "../builder/data/usr/bin/monstop",
      "../builder/data/usr/bin/monstart",
      "../builder/data/usr/bin/hdmion",
      "../builder/data/usr/bin/hdmioff",
    ]
  }
  provisioner "shell" {
    inline = ["chmod +x /usr/bin/*"]
  }

  provisioner "file" {
    destination = "/etc/systemd/system/"
    sources     = [
      "../builder/data/etc/systemd/system/pwngrid-peer.service",
      "../builder/data/etc/systemd/system/pwnagotchi.service",
      "../builder/data/etc/systemd/system/bettercap.service",
    ]
  }
  provisioner "file" {
    destination = "/etc/update-motd.d/01-motd"
    source      = "../builder/data/etc/update-motd.d/01-motd"
  }
  provisioner "shell" {
    inline = ["chmod +x /etc/update-motd.d/*"]
  }
  provisioner "shell" {
    inline = ["apt-get -y --allow-releaseinfo-change update", "apt-get -y dist-upgrade", "apt-get install -y --no-install-recommends ansible"]
  }
  provisioner "ansible-local" {
    command         = "ANSIBLE_FORCE_COLOR=1 PYTHONUNBUFFERED=1 PWN_VERSION=${var.pwn_version} PWN_HOSTNAME=${var.pwn_hostname} ansible-playbook"
    extra_arguments = ["--extra-vars \"ansible_python_interpreter=/usr/bin/python3\""]
    playbook_file   = "../builder/pwnagotchi.yml"
  }
}
