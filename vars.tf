//Defining some variables that we will be calling for resources creation in the main.tf file

variable "region" {
  default = "europe-west1"
}

variable "project" {
  default = "quantum-talent-248210"
}

variable "servertype" {
  default = "n1-standard-2"
}

variable "vmtype" {
  default = "g1-small"
}

variable "image" {
  default = "centos-cloud/centos-7"
}

variable "imagewin" {
  default = "windows-cloud/windows-2012-r2"
}

variable "zone" {
  default = "europe-west1-c"
}