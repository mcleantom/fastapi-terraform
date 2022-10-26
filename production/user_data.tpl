#cloud-config

packages:
  - docker.io

# create the docker group
groups:
  - docker

users:
  - name: ubuntu
    groups: docker
    home: /home/ubuntu
    shell: /bin/bash
    sudo: ALL=(ALL) NOPASSWD:ALL

# Add default auto created user to docker group
system_info:
  default_user:
    groups: [docker]

runcmd:
  - sudo apt upgrade
  - sudo apt update
  - sudo apt install python3-pip -y
  - pip3 install awscli
  - docker login -u AWS -p $(aws ecr get-login-password --region eu-west-2) 543250707263.dkr.ecr.eu-west-2.amazonaws.com
  - docker pull enriquecatala/fastapi-helloworld
  - docker run -p 80:5000 enriquecatala/fastapi-helloworld
