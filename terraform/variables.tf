variable "yc_token" {
  description = "IAM secret key (from service account)"
  type        = string
}

variable "yc_cloud_id" {
  description = "Yandex Cloud ID"
  type        = string
}

variable "yc_folder_id" {
  description = "Yandex Folder ID"
  type        = string
}

variable "domain" {
  description = "Your domain name, e.g. example.com"
  type        = string
}

variable "ssh_public_key" {
  description = "Public SSH key for VM access (optional)"
  type        = string
  default     = ""
}