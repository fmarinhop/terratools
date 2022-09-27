#!/usr/bin/env bash

git init && git branch -m main

set -e

echo "Create base terraform templates..."
touch main.tf data.tf outputs.tf

if [ ! -f providers.tf ]; then
  echo "Create providers file..."
  cat >providers.tf <<-PROVIDERS
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = var.region
}
PROVIDERS
fi

if [ ! -f variables.tf ]; then
  echo "Create variables file..."
  cat >variables.tf <<-VARIABLES
variable "region" {
  description = "AWS region to create resources in"
  type        = string
  default     = "us-east-1"
}

variable "key_name" {
  default = "terraform-aws-key"
}

variable "linux_instance_type" {
  type        = string
  description = "EC2 instance type for Linux Server"
  default     = "t3.micro"
}
variable "linux_associate_public_ip_address" {
  type        = bool
  description = "Associate a public IP address to the EC2 instance"
  default     = true
}
variable "linux_root_volume_size" {
  type        = number
  description = "Volumen size of root volumen of Linux Server"
}
variable "linux_data_volume_size" {
  type        = number
  description = "Volumen size of data volumen of Linux Server"
}
variable "linux_root_volume_type" {
  type        = string
  description = "Volumen type of root volumen of Linux Server."
  default     = "gp3"
}
variable "linux_data_volume_type" {
  type        = string
  description = "Volumen type of data volumen of Linux Server"
  default     = "gp3"
}
VARIABLES
fi

if [ ! -f key-pair-main.tf ]; then
  echo "Create key-pair template file..."
  cat >key-pair-main.tf <<-KEYPAIR
# Generates a secure private key and encodes it as PEM
resource "tls_private_key" "key_pair" {
  algorithm   = "RSA"
  rsa_bits    = 4096
}
# Create the Key Pair
resource "aws_key_pair" "key_pair" {
  key_name    = "terraform-key-pair"  
  public_key  = tls_private_key.key_pair.public_key_openssh
}
# Save file
resource "local_file" "ssh_key" {
  filename  = "${aws_key_pair.key_pair.key_name}.pem"
  content  = tls_private_key.key_pair.private_key_pem
}
KEYPAIR
fi


if [ ! -f locals.tf ]; then
  echo "Create locals template file..."
  cat >locals.tf <<-LOCALS
locals {
}
LOCALS
fi

echo "Create default terraform variable file..."
mkdir -p tfvars && touch tfvars/main.tfvars

echo "Create .gitignore file..."
cat >.gitignore <<-IGNORE
**/.terraform/**
**/.terragrunt-cache/**
*/keys/*.pem
*/keys/*.pub
IGNORE

echo "Create default terraform folders..."
mkdir -p keys && mkdir -p templates && mkdir -p data && mkdir -p docker && touch docker/.env && touch docker/docker-compose.yaml
