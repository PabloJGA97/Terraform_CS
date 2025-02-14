variable "aws_region" {
  description = "Región de AWS"
  type        = string
  default     = "us-east-1"
}

variable "db_name" {
  description = "Nombre de la base de datos"
  type        = string
  default     = "wordpress_db"
}

variable "db_username" {
  description = "Usuario de la base de datos"
  type        = string
  default     = "admin"
}

variable "db_password" {
  description = "Contraseña de la base de datos"
  type        = string
  sensitive   = true
}

variable "instance_type" {
  description = "Tipo de instancia EC2"
  type        = string
  default     = "t2.micro"
}

variable "ami_id" {
  description = "AMI de Ubuntu"
  type        = string
  default     = "ami-0fc5d935ebf8bc3bc"
}

variable "key_name" {
  description = "Nombre de la clave SSH"
  type        = string
}

variable "public_ip" {
  description = "¿Asignar IP pública?"
  type        = bool
  default     = true
}

variable "major_engine_version" {
  description = "Versión principal del motor de base de datos"
  type        = string
}

variable "family" {
  description = "Familia de parámetros de la base de datos"
  type        = string
}
