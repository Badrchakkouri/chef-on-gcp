//adding the connection information for my GCP account
provider "google" {
  region = var.region
  project = var.project
  credentials = file("./GCP-account.json")
}

