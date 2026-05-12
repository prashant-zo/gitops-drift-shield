variable "project_name" {
  type = string
}

variable "suffix" {
  type = string
}

variable "common_tags" {
  type    = map(string)
  default = {}
}
