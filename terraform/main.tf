terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  # Estado local a proposito: este stack es el que crea el bucket de estado.
  # Una vez aplicado, se migra con `terraform init -migrate-state`.
  backend "s3" {
    bucket       = "portfolio-devops-state"
    key          = "terraform.tfstate"
    use_lockfile = true
    region       = "us-east-2"
    profile      = "alandriel"
  }
}
