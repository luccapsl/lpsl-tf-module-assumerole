# ---------------------------------------------------------------------------------------------------------------------
# GLOBAL VARIABLES
# ---------------------------------------------------------------------------------------------------------------------

variable "default_tags" {
  description = "Default tags to apply to all resources."
  type        = map(string)
  default = {
    ManagedBy   = "terraform"
    Environment = ""
    Owner       = ""
  }
}

variable "account_initials" {
  description = "Account initials used as prefix in resource naming."
  type        = string
  default     = ""
}

variable "assumerole_permissions" {
  description = "Default permissions for the assume role policies."
  type        = list(string)
  default = [""]
}

# ---------------------------------------------------------------------------------------------------------------------
# VARIABLES AZURE DEVOPS
# ---------------------------------------------------------------------------------------------------------------------

variable "assume_role_azuredevops" {
  description = "Settings for assuming roles via Azure DevOps OIDC."
  type = object({
    enable           = optional(bool, false)
    org_azure_devops = optional(string, "")
    oidc_audience    = optional(string, "api://AzureADTokenExchange")
    thumbprints      = optional(list(string), ["6938fd4d98bab03faadb97b34396831e3780aea1"])
    project_azure_devops = optional(map(object({
      enable_role             = bool
      project_name            = string
      service_connection_name = string
      permissions             = optional(list(string), null)
      inline_policy           = optional(string, null)
    })), {})
  })
  # example = {
  #   enable_role             = true
  #   project_name            = "Example"
  #   service_connection_name = "sc://ExampleOrg/ExampleProject/example-service-connection"
  #   permissions             = var.assumerole_permissions
  # }
  default = {}
}

# ---------------------------------------------------------------------------------------------------------------------
# VARIABLES GITHUB
# ---------------------------------------------------------------------------------------------------------------------

variable "assume_role_github" {
  description = "Settings for assuming roles via GitHub Actions OIDC."
  type = object({
    enable        = optional(bool, false)
    github_org    = optional(string, "")
    oidc_url      = optional(string, "https://token.actions.githubusercontent.com")
    oidc_audience = optional(string, "sts.amazonaws.com")
    thumbprints = optional(list(string), [
      "6938fd4d98bab03faadb97b34396831e3780aea1",
      "1c58a3a8518e8759bf075b76b750d4f2df264fcd"
    ])
    repositories = optional(map(object({
      enable_role   = bool
      repo_name     = string
      subject_claim = string
      # Formats: branch → "repo:Org/repo:ref:refs/heads/main"
      #          tag    → "repo:Org/repo:ref:refs/tags/v*"
      #          env    → "repo:Org/repo:environment:production"
      #          any    → "repo:Org/repo:*"
      permissions   = optional(list(string), null)
      inline_policy = optional(string, null)
    })), {})
  })
  default = {}
}

# ---------------------------------------------------------------------------------------------------------------------
# VARIABLES GITLAB                                                                                                    
# ---------------------------------------------------------------------------------------------------------------------

variable "assume_role_gitlab" {
  description = "Settings for assuming roles via GitLab CI/CD OIDC."
  type = object({
    enable     = optional(bool, false)
    gitlab_url = optional(string, "https://gitlab.com")
    # For self-hosted GitLab, replace with the thumbprint of your instance's root CA.
    thumbprints = optional(list(string), ["b3dd7606d2b5a8b4a13771dbecc9ee1cecafa38a"])
    projects = optional(map(object({
      enable_role   = bool
      project_path  = string
      subject_claim = string
      # Formats: branch → "project_path:group/project:ref_type:branch:ref:main"
      #          tag    → "project_path:group/project:ref_type:tag:ref:v1.0"
      #          any    → "project_path:group/project:*"
      permissions   = optional(list(string), null)
      inline_policy = optional(string, null)
    })), {})
  })
  default = {}
}
