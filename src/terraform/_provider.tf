provider "aws" {
  # Configuration options
  region = var.region

  default_tags {
    tags = local.tags
  }
}