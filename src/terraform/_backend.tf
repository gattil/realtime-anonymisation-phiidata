terraform {
  backend "s3" {
    encrypt        = true
    bucket         = "terraform-state-<AWS-ACCOUNT-ID>"
    dynamodb_table = "terraform-state-lock-<AWS-ACCOUNT-ID>"
    key            = "pii-rt-scraper.tfstate"
    region         = "eu-west-1"
  }
}