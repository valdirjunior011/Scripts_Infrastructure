terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0.1"
    }
  }

  required_version = ">= 1.2.0"
}

provider "docker" {}

resource "docker_network" "my_network" {
  name = "my_network"
}

resource "docker_image" "giropops_image" {
  name         = "valdirjunior011/linuxtips-giropops-senhas:4.0"
  keep_locally = false
}

resource "docker_volume" "shared_volume" {
  name = "shared_volume"
}

resource "docker_container" "giropops_container" {
  count = 2
  name  = "giropops-senhas${count.index + 1}"
  image = docker_image.giropops_image.name
  dynamic "ports" {
    for_each = count.index == 0 ? [1] : [0]
    content {
      internal = 5000
      external = ports.value == 0 ? 8080 : 8081
    }
  }
  networks_advanced {
    name = docker_network.my_network.name
  }
  volumes {
    container_path = "/volume"
    read_only = true
    host_path = "~/shared_volume/"
    volume_name = "${docker_volume.shared_volume.name}"
  }
}
resource "docker_image" "redis_image" {
  name         = "cgr.dev/chainguard/redis"
  keep_locally = false
}
resource "docker_container" "redis_container" {
  name  = "redisdb"
  image = docker_image.redis_image.name

  networks_advanced {
    name = docker_network.my_network.name
  }
  volumes {
    container_path = "/volume"
    read_only = true
    host_path = "~/shared_volume/"
    volume_name = "${docker_volume.shared_volume.name}"
  }
}
resource "null_resource" "trivy" {
  triggers = {
    giropops_image = docker_image.giropops_image.id
    redis_image    = docker_image.redis_image.id
  }

  provisioner "local-exec" {
    command     = "bash trivy_scan.sh"
  }
}
locals {
  giropops_trivy_output = file("${path.module}/giropops_trivy_output.txt")
  redis_trivy_output    = file("${path.module}/redis_trivy_output.txt")
}

output "container_info" {
  value = concat(
    ["Name: ${docker_container.giropops_container[0].name} IP:${docker_container.giropops_container[0].network_data[0].ip_address}"],
    ["Name: ${docker_container.giropops_container[1].name} IP:${docker_container.giropops_container[1].network_data[0].ip_address}"],
    ["Name: ${docker_container.redis_container.name} IP: ${docker_container.redis_container.network_data[0].ip_address}"]
  )
}
output "giropops_trivy_scan" {
  value = local.giropops_trivy_output
}
output "redis_trivy_scan" {
  value = local.redis_trivy_output
}