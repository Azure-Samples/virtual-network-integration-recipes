variable "environment" {
  type        = string
  description = "Name of the environment"
  default     = "nonprod"
}

variable "location" {
  type        = string
  description = "Location of the resources"
  default     = "australiaeast"
}

variable "prefix" {
  type        = string
  description = "Prefix of the resource name"
  default     = "aml"
}

variable "image_build_compute_name" {
  type        = string
  description = "Name of the compute cluster to be created and set to build docker images"
  default     = "image-builder"
}
