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

resource "docker_container" "giropops_container" {
  name  = "giropops-senhas"
  image = docker_image.giropops_image.name
  ports {
    internal = 5000
    external = 8080
  }
  networks_advanced {
    name = docker_network.my_network.name
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
  value = "Name: ${docker_container.giropops_container.name} IP:${docker_container.giropops_container.network_data[0].ip_address} And Name: ${docker_container.redis_container.name} IP: ${docker_container.redis_container.network_data[0].ip_address}"
}
output "giropops_trivy_scan" {
  value = local.giropops_trivy_output
}
output "redis_trivy_scan" {
  value = local.redis_trivy_output
}