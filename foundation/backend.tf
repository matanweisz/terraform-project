terraform {
  backend "s3" {
    bucket       = "foundation-terraform-project-state"
    region       = "eu-central-1"
    use_lockfile = true
  }
}
