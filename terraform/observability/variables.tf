variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "chart_version" {
  description = "kube-prometheus-stack Helm chart version"
  type        = string
  default     = "87.17.0"
}

variable "project" {
  description = "Project tag applied to all resources"
  type        = string
  default     = "argocd-gitops-aws"
}

# SAO Platform's MCP server /incident endpoint (ALB DNS). Empty by default —
# Módulo 0 only needs to prove the webhook fires (logged by the Lambda);
# wiring this up for real incident handling is Módulo 1's job. Set it once
# SAO Platform's ECS stack is up in the same session.
variable "mcp_server_url" {
  description = "SAO Platform MCP server base URL, e.g. http://<alb-dns>. Empty = dispatcher only logs, doesn't forward."
  type        = string
  default     = ""
}
