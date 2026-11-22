variable "aws_region" {
  type        = string
  description = "Region de AWS para la instancia EC2."
  default     = "us-east-1"
}

variable "instance_type" {
  type        = string
  description = "Tipo de instancia EC2."
  default     = "t3.micro"
}

variable "allowed_cidr" {
  type        = string
  description = "CIDR con acceso al puerto 80 (Istio ingress gateway)."
  default     = "0.0.0.0/0"
}
