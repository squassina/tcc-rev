variable "prefix" {
  description = "The Prefix used for all resources"
  type        = string
  default     = "squassina"
}

variable "environment" {
  description = "Environment being deployed"
  type        = string
  default     = "develop"
}

variable "location" {
  description = "The Azure Region in which all resources should be created."
  type        = string
  default     = "eastus"
}

variable "tables" {
  description = "tables connected to kusto eventhub"
  type = object({
    CAPITULOS     = string
    CATEGORIAS    = string
    CLIMA         = string
    GRUPOS        = string
    HOSP_CONS     = string
    HOSP_DET      = string
    SUBCATEGORIAS = string
  })
  default = {
    "CAPITULOS"     = "CSV",
    "CATEGORIAS"    = "CSV",
    "CLIMA"         = "CSV",
    "GRUPOS"        = "CSV",
    "HOSP_CONS"     = "CSV",
    "HOSP_DET"      = "CSV",
    "SUBCATEGORIAS" = "CSV"
  }
}

variable "ARM_CLIENT_SECRET" {}