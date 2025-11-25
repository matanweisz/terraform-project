terraform {
  backend "s3" {
    bucket       = "foundation-terraform-project-state"
    key          = "terraform.tfstate"
    region       = "eu-central-1"
    use_lockfile = true
    encrypt      = true
  }
}
