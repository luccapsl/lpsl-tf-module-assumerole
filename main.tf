# -----------------------------------------------------------------------------------------------------
# ASSUME ROLE - AZURE DEVOPS (OIDC)
# -----------------------------------------------------------------------------------------------------

resource "aws_iam_openid_connect_provider" "azure_devops" {
  count = var.assume_role_azuredevops.enable ? 1 : 0

  url             = "https://vstoken.dev.azure.com/${var.assume_role_azuredevops.org_azure_devops}"
  client_id_list  = [var.assume_role_azuredevops.oidc_audience]
  thumbprint_list = var.assume_role_azuredevops.thumbprints

  tags = var.default_tags
}

data "aws_iam_policy_document" "azure_devops_assume_role" {
  for_each = {
    for project_key, project_val in var.assume_role_azuredevops.project_azure_devops :
    project_key => project_val if var.assume_role_azuredevops.enable && project_val.enable_role
  }

  statement {
    effect = "Allow"

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.azure_devops[0].arn]
    }

    actions = ["sts:AssumeRoleWithWebIdentity"]

    condition {
      test     = "StringEquals"
      variable = "vstoken.dev.azure.com/${var.assume_role_azuredevops.org_azure_devops}:aud"
      values   = [var.assume_role_azuredevops.oidc_audience]
    }

    condition {
      test     = "StringEquals"
      variable = "vstoken.dev.azure.com/${var.assume_role_azuredevops.org_azure_devops}:sub"
      values   = [var.assume_role_azuredevops.project_azure_devops[each.key].service_connection_name]
    }
  }
}

resource "aws_iam_role" "azure_devops_role" {
  for_each = {
    for project_key, project_val in var.assume_role_azuredevops.project_azure_devops :
    project_key => project_val if var.assume_role_azuredevops.enable && project_val.enable_role
  }

  name               = "${var.account_initials}-role-${each.key}-azure-devops-oidc"
  assume_role_policy = data.aws_iam_policy_document.azure_devops_assume_role[each.key].json

  tags = merge(
    var.default_tags,
    {
      Name        = "${var.account_initials}-role-${each.key}-azure-devops-oidc"
      Description = "IAM Role assumed by Azure DevOps via OIDC"
    }
  )
}

resource "aws_iam_policy" "azure_devops_policy" {
  for_each = {
    for project_key, project_val in var.assume_role_azuredevops.project_azure_devops :
    project_key => project_val if var.assume_role_azuredevops.enable && project_val.enable_role && project_val.permissions != null
  }

  name = "${var.account_initials}-policy-${each.key}-azure-devops"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = each.value.permissions
        Resource = "*"
      }
    ]
  })

  tags = merge(
    var.default_tags,
    {
      Name        = "${var.account_initials}-policy-${each.key}-azure-devops"
      Description = "Permissions for Azure DevOps pipelines via OIDC"
    }
  )
}

resource "aws_iam_role_policy_attachment" "azure_devops_attach" {
  for_each = {
    for project_key, project_val in var.assume_role_azuredevops.project_azure_devops :
    project_key => project_val if var.assume_role_azuredevops.enable && project_val.enable_role && project_val.permissions != null
  }

  role       = aws_iam_role.azure_devops_role[each.key].name
  policy_arn = aws_iam_policy.azure_devops_policy[each.key].arn
}

resource "aws_iam_role_policy" "azure_devops_inline" {
  for_each = {
    for project_key, project_val in var.assume_role_azuredevops.project_azure_devops :
    project_key => project_val if var.assume_role_azuredevops.enable && project_val.enable_role && project_val.inline_policy != null
  }

  name   = "${var.account_initials}-inline-${each.key}-azure-devops"
  role   = aws_iam_role.azure_devops_role[each.key].name
  policy = each.value.inline_policy
}


# -----------------------------------------------------------------------------------------------------
# ASSUME ROLE - GITLAB (OIDC)
# -----------------------------------------------------------------------------------------------------

locals {
  gitlab_oidc_host = trimprefix(var.assume_role_gitlab.gitlab_url, "https://")
  github_oidc_host = trimprefix(var.assume_role_github.oidc_url, "https://")
}

resource "aws_iam_openid_connect_provider" "gitlab_cicd" {
  count = var.assume_role_gitlab.enable ? 1 : 0

  url             = var.assume_role_gitlab.gitlab_url
  client_id_list  = [var.assume_role_gitlab.gitlab_url]
  thumbprint_list = var.assume_role_gitlab.thumbprints

  tags = var.default_tags
}

data "aws_iam_policy_document" "gitlab_cicd_assume_role" {
  for_each = {
    for project_key, project_val in var.assume_role_gitlab.projects :
    project_key => project_val if var.assume_role_gitlab.enable && project_val.enable_role
  }

  statement {
    effect = "Allow"

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.gitlab_cicd[0].arn]
    }

    actions = ["sts:AssumeRoleWithWebIdentity"]

    condition {
      test     = "StringEquals"
      variable = "${local.gitlab_oidc_host}:aud"
      values   = [var.assume_role_gitlab.gitlab_url]
    }

    condition {
      test     = "StringLike"
      variable = "${local.gitlab_oidc_host}:sub"
      values   = [each.value.subject_claim]
    }
  }
}

resource "aws_iam_role" "gitlab_cicd_role" {
  for_each = {
    for project_key, project_val in var.assume_role_gitlab.projects :
    project_key => project_val if var.assume_role_gitlab.enable && project_val.enable_role
  }

  name               = "${var.account_initials}-role-${each.key}-gitlab-cicd-oidc"
  assume_role_policy = data.aws_iam_policy_document.gitlab_cicd_assume_role[each.key].json

  tags = merge(
    var.default_tags,
    {
      Name        = "${var.account_initials}-role-${each.key}-gitlab-cicd-oidc"
      Description = "IAM Role assumed by GitLab CI/CD via OIDC"
    }
  )
}

resource "aws_iam_policy" "gitlab_cicd_policy" {
  for_each = {
    for project_key, project_val in var.assume_role_gitlab.projects :
    project_key => project_val if var.assume_role_gitlab.enable && project_val.enable_role && project_val.permissions != null
  }

  name = "${var.account_initials}-policy-${each.key}-gitlab-cicd"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = each.value.permissions
        Resource = "*"
      }
    ]
  })

  tags = merge(
    var.default_tags,
    {
      Name        = "${var.account_initials}-policy-${each.key}-gitlab-cicd"
      Description = "Permissions for GitLab CI/CD pipelines via OIDC"
    }
  )
}

resource "aws_iam_role_policy_attachment" "gitlab_cicd_attach" {
  for_each = {
    for project_key, project_val in var.assume_role_gitlab.projects :
    project_key => project_val if var.assume_role_gitlab.enable && project_val.enable_role && project_val.permissions != null
  }

  role       = aws_iam_role.gitlab_cicd_role[each.key].name
  policy_arn = aws_iam_policy.gitlab_cicd_policy[each.key].arn
}

resource "aws_iam_role_policy" "gitlab_cicd_inline" {
  for_each = {
    for project_key, project_val in var.assume_role_gitlab.projects :
    project_key => project_val if var.assume_role_gitlab.enable && project_val.enable_role && project_val.inline_policy != null
  }

  name   = "${var.account_initials}-inline-${each.key}-gitlab-cicd"
  role   = aws_iam_role.gitlab_cicd_role[each.key].name
  policy = each.value.inline_policy
}


# -----------------------------------------------------------------------------------------------------
# ASSUME ROLE - GITHUB (OIDC)
# -----------------------------------------------------------------------------------------------------

resource "aws_iam_openid_connect_provider" "github_actions" {
  count = var.assume_role_github.enable ? 1 : 0

  url             = var.assume_role_github.oidc_url
  client_id_list  = [var.assume_role_github.oidc_audience]
  thumbprint_list = var.assume_role_github.thumbprints

  tags = var.default_tags
}

data "aws_iam_policy_document" "github_actions_assume_role" {
  for_each = {
    for repo_key, repo_val in var.assume_role_github.repositories :
    repo_key => repo_val if var.assume_role_github.enable && repo_val.enable_role
  }

  statement {
    effect = "Allow"

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github_actions[0].arn]
    }

    actions = ["sts:AssumeRoleWithWebIdentity"]

    condition {
      test     = "StringEquals"
      variable = "${local.github_oidc_host}:aud"
      values   = [var.assume_role_github.oidc_audience]
    }

    condition {
      test     = "StringLike"
      variable = "${local.github_oidc_host}:sub"
      values   = [each.value.subject_claim]
    }
  }
}

resource "aws_iam_role" "github_actions_role" {
  for_each = {
    for repo_key, repo_val in var.assume_role_github.repositories :
    repo_key => repo_val if var.assume_role_github.enable && repo_val.enable_role
  }

  name               = "${var.account_initials}-role-${each.key}-github-actions-oidc"
  assume_role_policy = data.aws_iam_policy_document.github_actions_assume_role[each.key].json

  tags = merge(
    var.default_tags,
    {
      Name        = "${var.account_initials}-role-${each.key}-github-actions-oidc"
      Description = "IAM Role assumed by GitHub Actions via OIDC"
    }
  )
}

resource "aws_iam_policy" "github_actions_policy" {
  for_each = {
    for repo_key, repo_val in var.assume_role_github.repositories :
    repo_key => repo_val if var.assume_role_github.enable && repo_val.enable_role && repo_val.permissions != null
  }

  name = "${var.account_initials}-policy-${each.key}-github-actions"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = each.value.permissions
        Resource = "*"
      }
    ]
  })

  tags = merge(
    var.default_tags,
    {
      Name        = "${var.account_initials}-policy-${each.key}-github-actions"
      Description = "Permissions for GitHub Actions pipelines via OIDC"
    }
  )
}

resource "aws_iam_role_policy_attachment" "github_actions_attach" {
  for_each = {
    for repo_key, repo_val in var.assume_role_github.repositories :
    repo_key => repo_val if var.assume_role_github.enable && repo_val.enable_role && repo_val.permissions != null
  }

  role       = aws_iam_role.github_actions_role[each.key].name
  policy_arn = aws_iam_policy.github_actions_policy[each.key].arn
}

resource "aws_iam_role_policy" "github_actions_inline" {
  for_each = {
    for repo_key, repo_val in var.assume_role_github.repositories :
    repo_key => repo_val if var.assume_role_github.enable && repo_val.enable_role && repo_val.inline_policy != null
  }

  name   = "${var.account_initials}-inline-${each.key}-github-actions"
  role   = aws_iam_role.github_actions_role[each.key].name
  policy = each.value.inline_policy
}
