# ---------------------------------------------------------------------------
# TEMPORARY fallback: static credentials for CI, only because this AWS
# account is on the $200 Free Trial tier and appears to block external OIDC
# federation (AssumeRoleWithWebIdentity fails with a generic AccessDenied
# even with a verified-correct trust policy — undocumented by AWS, but
# consistent with the account's other undocumented Free-Tier-only
# restrictions). The role + OIDC provider above are kept as-is; once the
# account is verified/upgraded, switch the workflow back to
# role-to-assume and delete this file.
#
# Scoped identically to the OIDC role: ECR push only, nothing else.
# ---------------------------------------------------------------------------

resource "aws_iam_user" "github_actions_fallback" {
  name = "${var.project}-github-actions-fallback"

  tags = {
    Project = var.project
    Purpose = "temporary-oidc-workaround"
  }
}

resource "aws_iam_user_policy" "github_actions_fallback_ecr" {
  name   = "ecr-push"
  user   = aws_iam_user.github_actions_fallback.name
  policy = data.aws_iam_policy_document.github_actions_ecr.json
}

resource "aws_iam_access_key" "github_actions_fallback" {
  user = aws_iam_user.github_actions_fallback.name
}
