#____________________________Variables__________________________#
variable "vpc_id" {
  description = "VPC ID for usage throughout the build process"
  default = "vpc-8955b0ee"
}

variable "db_password" {
	description = "Please enter a password for MariaDB Instance."
}