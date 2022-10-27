# FastAPI - Terraform

This repository shows an example template of deploying a FastAPI instance to an AWS that is:

* Isolated in a virtual-private-cloud (VPC)
* Load balanced
* Auto scaled
* Secured by SSL
* DNS routed with Route53
* Accessible by SSH
* Continuously deployed with ECR

It is based on the example [Terraform AWS VPC Example](https://github.com/benoutram/terraform-aws-vpc-example), with a
few modifications to use AWS ECR to host the docker containers that will run the FastAPI instances, as well as the
auto scaling group automatically replacing EC2 instances when a new docker image is pushed to the ECR repository.

## How do I get setup?

### Docker

Docker will be used to containerize the FastAPI apps. [Follow the instructions to install for your OS](https://docs.docker.com/engine/install/)

### Terraform

To install terraform, [follow the installation instructions for your OS](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli).
Alternatively, to install terraform on linux, run the shell commands:

```shell
sudo apt update
sudo apt install  software-properties-common gnupg2 curl
curl https://apt.releases.hashicorp.com/gpg | gpg --dearmor > hashicorp.gpg
sudo install -o root -g root -m 644 hashicorp.gpg /etc/apt/trusted.gpg.d/
sudo apt-add-repository "deb [arch=$(dpkg --print-architecture)] https://apt.releases.hashicorp.com focal main"
sudo apt update
sudo apt install terraform
```

### IAM User with Permissions

* Create an IAM group called TerraformUsers
* Attach the policy PowerUserAccess
* Add your IAM users to the group

### Hosted zone with a wildcard simple record

Follow [this](https://stackoverflow.com/questions/63710263/configuring-wildcard-record-on-aws-route-53) stackoverflow 
answer to create a wildcard simple record for your hosted zone.

### An ECR repository.

[Follow this tutorial](https://docs.aws.amazon.com/AmazonECR/latest/userguide/repository-create.html) To create a
repository in AWS to push your docker images to.

### AWS CLI

We will use AWS CLI to push docker images from our computer to AWS. [Follow the tutorial for your OS](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)

### Configure the project properties

Fill in the appropriate variables in the `user.tfvars` file.

## Deployment

First, initialize terraform

```commandline
terraform init
```

then check the plan

```shell
terraform plan
```

deploy the plan to AWS.

```shell
terraform apply -var-file="user.tfvars"
```

then, make sure to destroy your deployment after testing to avoid charges.

```shell
terraform destroy -var-file="user.tfvars"
```
