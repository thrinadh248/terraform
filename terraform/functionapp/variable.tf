variable "resource_group_name" {
  type    = string
  default = "thrinadh-alerts"
}

variable "location" {
  type    = string
  default = "East US"
}

variable "app_service_plan_name" {
  type    = string
  default = "thrinadh-app-service-plan"
}

variable "function_app_name" {
  type    = string
  default = "thrinadh-function-app"
}

variable "application_insights_name" {
  type    = string
  default = "thrinadh-app-insights"
}

variable "log_analytics_workspace_name" {
  type    = string
  default = "thrinadh-law"
}

variable "alert_email" {
  type    = string
  default = "thrinadh0248@gmail.com"
}

