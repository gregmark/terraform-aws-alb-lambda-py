variable "region" {
  type    = string
  default = "us-east-1"
}

variable "profile" {
  type    = string
  default = "default"
}

variable "tags" {
  type = map(any)
  default = {
    Name = "alf"
  }
}

variable "s3_access_logs" {
  type    = string
  default = null
}
