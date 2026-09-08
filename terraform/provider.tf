
provider "aws" {
  region  = var.aws_region
  profile = "alandriel"

  default_tags {
    tags = {
      Project   = "Portfolio Devops"
      ManagedBy = "terraform"
      Repo      = "portfolio-devops"
    }
  }
}

# Alias obligatorio solo para el certificado ACM de site.tf — CloudFront
# solo lee certificados que viven en us-east-1, sin importar la region
# default del resto del stack.
provider "aws" {
  alias   = "us_east_1"
  region  = "us-east-1"
  profile = "alandriel"

  default_tags {
    tags = {
      Project   = "Portfolio Devops"
      ManagedBy = "terraform"
      Repo      = "portfolio-devops"
    }
  }
}
