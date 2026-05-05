# ---------------------------------------------------------------------------------------------------------------------
# OUTPUTS - AZURE DEVOPS
# ---------------------------------------------------------------------------------------------------------------------

output "azuredevops_oidc_provider_arn" {
  description = "ARN of the IAM OIDC Provider created for Azure DevOps. Null if disabled."
  value       = try(aws_iam_openid_connect_provider.azure_devops[0].arn, null)
}

output "azuredevops_role_arns" {
  description = "Map of IAM Role ARNs created for Azure DevOps projects. Key matches the project_azure_devops map key."
  value       = { for k, v in aws_iam_role.azure_devops_role : k => v.arn }
}

output "azuredevops_policy_arns" {
  description = "Map of IAM Policy ARNs created for Azure DevOps projects. Key matches the project_azure_devops map key."
  value       = { for k, v in aws_iam_policy.azure_devops_policy : k => v.arn }
}

# ---------------------------------------------------------------------------------------------------------------------
# OUTPUTS - GITLAB
# ---------------------------------------------------------------------------------------------------------------------

output "gitlab_oidc_provider_arn" {
  description = "ARN of the IAM OIDC Provider created for GitLab CI/CD. Null if disabled."
  value       = try(aws_iam_openid_connect_provider.gitlab_cicd[0].arn, null)
}

output "gitlab_role_arns" {
  description = "Map of IAM Role ARNs created for GitLab projects. Key matches the projects map key."
  value       = { for k, v in aws_iam_role.gitlab_cicd_role : k => v.arn }
}

output "gitlab_policy_arns" {
  description = "Map of IAM Policy ARNs created for GitLab projects. Key matches the projects map key."
  value       = { for k, v in aws_iam_policy.gitlab_cicd_policy : k => v.arn }
}

# ---------------------------------------------------------------------------------------------------------------------
# OUTPUTS - GITHUB
# ---------------------------------------------------------------------------------------------------------------------

output "github_oidc_provider_arn" {
  description = "ARN of the IAM OIDC Provider created for GitHub Actions. Null if disabled."
  value       = try(aws_iam_openid_connect_provider.github_actions[0].arn, null)
}

output "github_role_arns" {
  description = "Map of IAM Role ARNs created for GitHub repositories. Key matches the repositories map key."
  value       = { for k, v in aws_iam_role.github_actions_role : k => v.arn }
}

output "github_policy_arns" {
  description = "Map of IAM Policy ARNs created for GitHub repositories. Key matches the repositories map key."
  value       = { for k, v in aws_iam_policy.github_actions_policy : k => v.arn }
}
