packer {
  required_plugins {
    docker = {
      version = ">= 0.0.7"
      source = "github.com/hashicorp/docker"
    }
  }
}

source "docker" "python" {
  image = "python:3.11-alpine"
  commit = true
  changes = [
    "ENTRYPOINT [\"/app/venv/bin/python\", \"/app/run.py\"]",
    "CMD []",
    "VOLUME /data"
  ]
}

build {
  name = "pfsense-backup"
  sources = ["source.docker.python"]

  provisioner "shell" {
    inline = [
      "mkdir -p /app",
      "apk add --no-cache tzdata"
    ]
  }

  provisioner "file" {
    source = "run.py"
    destination = "/app/run.py"
  }
  
  provisioner "file" {
    source = "requirements.txt"
    destination = "/app/requirements.txt"
  }

  provisioner "shell" {
    inline = [
      "chmod +x /app/run.py",
      "mkdir -p /data",
      "python -m venv /app/venv",
      "/app/venv/bin/pip install --upgrade pip",
      "/app/venv/bin/pip install --no-cache-dir -r /app/requirements.txt"
    ]
  }

  post-processors {
    post-processor "docker-tag" {
      repository = "docker-registry.jealwh.local:5000/pfsense-backup"
      tags = ["latest"]
    }
  
    post-processor "docker-push" {
      login = false
    }
}

}
