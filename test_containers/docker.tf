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
  name   = "my_network"
  driver = "bridge"
}

resource "docker_image" "giropops_image" {
  name         = "valdirjunior011/linuxtips-giropops-senhas:4.0"
  keep_locally = true
}

resource "docker_container" "giropops_container" {
  name  = "giropops_container"
  image = docker_image.nginx_image.latest
  ports {
    internal = 5000
    external = 8080
  }
  network = docker_network.my_network.name
}

resource "docker_image" "redis_image" {
  name         = "cgr.dev/chainguard/redis"
  keep_locally = true
}

resource "docker_container" "redis_container" {
  name  = "redis_container"
  image = docker_image.redis_image.latest
  network = docker_network.my_network.name
}