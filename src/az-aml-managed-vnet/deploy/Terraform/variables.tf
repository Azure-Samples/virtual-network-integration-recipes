variable "environment" {
  type        = string
  description = "Name of the environment"
  default     = "poc"
}

variable "location" {
  type        = string
  description = "Location of the resources"
  default     = "centralindia"
}

variable "prefix" {
  type        = string
  description = "Prefix of the resource name"
  default     = "mvnetaml"
}

variable "image_build_compute_name" {
  type        = string
  description = "Name of the compute cluster to be created and set to build docker images"
  default     = "imgbuilder"
}
