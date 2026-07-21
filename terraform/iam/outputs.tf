output "github_actions_role_arn" {
  value = aws_iam_role.github_actions.arn
}

output "alb_controller_role_arn" {
  value = aws_iam_role.alb_controller.arn
}

# TEMPORARY (see fallback_ci_user.tf) — sensitive, never printed to logs,
# only read via `terraform output -raw` to load into GitHub Actions secrets.
output "github_actions_fallback_access_key_id" {
  value     = aws_iam_access_key.github_actions_fallback.id
  sensitive = true
}

output "github_actions_fallback_secret_access_key" {
  value     = aws_iam_access_key.github_actions_fallback.secret
  sensitive = true
}
