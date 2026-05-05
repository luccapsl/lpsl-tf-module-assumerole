# lpsl-tf-module-assumerole


Terraform module that provisions IAM Roles with OIDC trust policies for CI/CD pipelines/workflows to assume roles in AWS without the use of static credentials.

Supports the three main CI/CD providers:

| Provider | Protocol | AWS Resource |
| --- | --- | --- |
| Azure DevOps | OIDC via `vstoken.dev.azure.com` | IAM OIDC Provider + Role + Policy |
| GitHub Actions | OIDC via `token.actions.githubusercontent.com` | IAM OIDC Provider + Role + Policy |
| GitLab CI/CD | OIDC via `gitlab.com` (or self-hosted) | IAM OIDC Provider + Role + Policy |

---

## How it works

The OIDC authentication flow eliminates static credentials:

```
Pipeline (Azure DevOps / GitHub / GitLab)
    │
    ▼
Generates JWT token signed by the OIDC provider
    │
    ▼
Calls sts:AssumeRoleWithWebIdentity with the token
    │
    ▼
AWS validates the signature via IAM OIDC Provider
    │
    ▼
AWS verifies Trust Policy conditions (aud + sub)
    │
    ▼
Returns temporary credentials (STS)
```

Each provider creates the following AWS resources per enabled project/repository:

- `aws_iam_openid_connect_provider` — registers the OIDC provider in the AWS account (created once per provider)
- `aws_iam_role` — the role the pipeline assumes
- `aws_iam_policy` — managed policy with the declared permissions (created only if `permissions != null`)
- `aws_iam_role_policy_attachment` — attaches the managed policy to the role (created only if `permissions != null`)
- `aws_iam_role_policy` — inline policy directly on the role (created only if `inline_policy != null`)

---

## Requirements

| Tool | Minimum version |
| --- | --- |
| Terraform | `>= 1.5.0` |
| AWS Provider | `>= 5.0.0` |

---

## Created resources

### Azure DevOps

| Resource | AWS name | Condition |
| --- | --- | --- |
| `aws_iam_openid_connect_provider` | Derived from URL `vstoken.dev.azure.com/{org_id}` | `enable = true` |
| `aws_iam_role` | `{account_initials}-role-{key}-azure-devops-oidc` | `enable_role = true` |
| `aws_iam_policy` | `{account_initials}-policy-{key}-azure-devops` | `permissions != null` |
| `aws_iam_role_policy` | `{account_initials}-inline-{key}-azure-devops` | `inline_policy != null` |

### GitHub Actions

| Resource | AWS name | Condition |
| --- | --- | --- |
| `aws_iam_openid_connect_provider` | Derived from URL `token.actions.githubusercontent.com` | `enable = true` |
| `aws_iam_role` | `{account_initials}-role-{key}-github-actions-oidc` | `enable_role = true` |
| `aws_iam_policy` | `{account_initials}-policy-{key}-github-actions` | `permissions != null` |
| `aws_iam_role_policy` | `{account_initials}-inline-{key}-github-actions` | `inline_policy != null` |

### GitLab CI/CD

| Resource | AWS name | Condition |
| --- | --- | --- |
| `aws_iam_openid_connect_provider` | Derived from `gitlab_url` (supports self-hosted) | `enable = true` |
| `aws_iam_role` | `{account_initials}-role-{key}-gitlab-cicd-oidc` | `enable_role = true` |
| `aws_iam_policy` | `{account_initials}-policy-{key}-gitlab-cicd` | `permissions != null` |
| `aws_iam_role_policy` | `{account_initials}-inline-{key}-gitlab-cicd` | `inline_policy != null` |

---

## Variables

### Global variables

| Name | Type | Required | Description |
| --- | --- | --- | --- |
| `account_initials` | `string` | yes | Prefix used in resource naming |
| `default_tags` | `map(string)` | no | Tags applied to all resources |
| `assumerole_permissions` | `list(string)` | no | Default reusable permissions list shared across providers |

### `assume_role_azuredevops`

| Field | Type | Description |
| --- | --- | --- |
| `enable` | `bool` | Enables or disables creation of Azure DevOps resources |
| `org_azure_devops` | `string` | Azure DevOps organization ID (GUID) |
| `oidc_audience` | `string` | OIDC token audience. Default: `api://AzureADTokenExchange` |
| `thumbprints` | `list(string)` | SHA-1 thumbprints of the root CA certificate of the OIDC endpoint |
| `project_azure_devops` | `map(object)` | Map of Azure DevOps projects (see structure below) |

**`project_azure_devops` structure:**

| Field | Type | Description |
| --- | --- | --- |
| `enable_role` | `bool` | Enables or disables the role for this project |
| `project_name` | `string` | Descriptive name of the project |
| `service_connection_name` | `string` | Service connection URI (token `sub` claim) |
| `permissions` | `optional(list(string))` | IAM permissions for the managed policy. If `null`, no managed policy is created |
| `inline_policy` | `optional(string)` | Inline policy JSON. If `null`, no inline policy is created |

### `assume_role_github`

| Field | Type | Description |
| --- | --- | --- |
| `enable` | `bool` | Enables or disables creation of GitHub resources |
| `github_org` | `string` | GitHub organization name |
| `oidc_url` | `string` | OIDC Provider URL. Default: `https://token.actions.githubusercontent.com` |
| `oidc_audience` | `string` | Token audience. Default: `sts.amazonaws.com` |
| `thumbprints` | `list(string)` | SHA-1 thumbprints of the GitHub root CA certificate |
| `repositories` | `map(object)` | Map of repositories (see structure below) |

**`repositories` structure:**

| Field | Type | Description |
| --- | --- | --- |
| `enable_role` | `bool` | Enables or disables the role for this repository |
| `repo_name` | `string` | Repository name |
| `subject_claim` | `string` | Filter for the token `sub` claim (see formats below) |
| `permissions` | `optional(list(string))` | IAM permissions for the managed policy. If `null`, no managed policy is created |
| `inline_policy` | `optional(string)` | Inline policy JSON. If `null`, no inline policy is created |

### `assume_role_gitlab`

| Field | Type | Description |
| --- | --- | --- |
| `enable` | `bool` | Enables or disables creation of GitLab resources |
| `gitlab_url` | `string` | GitLab base URL. Default: `https://gitlab.com` |
| `thumbprints` | `list(string)` | SHA-1 thumbprints of the GitLab root CA certificate |
| `projects` | `map(object)` | Map of GitLab projects (see structure below) |

**`projects` structure:**

| Field | Type | Description |
| --- | --- | --- |
| `enable_role` | `bool` | Enables or disables the role for this project |
| `project_path` | `string` | Full project path (`group/project`) |
| `subject_claim` | `string` | Filter for the token `sub` claim (see formats below) |
| `permissions` | `optional(list(string))` | IAM permissions for the managed policy. If `null`, no managed policy is created |
| `inline_policy` | `optional(string)` | Inline policy JSON. If `null`, no inline policy is created |

---

## Outputs

| Name | Description |
| --- | --- |
| `azuredevops_oidc_provider_arn` | ARN of the Azure DevOps IAM OIDC Provider. `null` if disabled |
| `azuredevops_role_arns` | Map of Azure DevOps role ARNs. Key = key of the `project_azure_devops` map |
| `azuredevops_policy_arns` | Map of Azure DevOps managed policy ARNs. Key = key of the `project_azure_devops` map |
| `gitlab_oidc_provider_arn` | ARN of the GitLab IAM OIDC Provider. `null` if disabled |
| `gitlab_role_arns` | Map of GitLab role ARNs. Key = key of the `projects` map |
| `gitlab_policy_arns` | Map of GitLab managed policy ARNs. Key = key of the `projects` map |
| `github_oidc_provider_arn` | ARN of the GitHub IAM OIDC Provider. `null` if disabled |
| `github_role_arns` | Map of GitHub role ARNs. Key = key of the `repositories` map |
| `github_policy_arns` | Map of GitHub managed policy ARNs. Key = key of the `repositories` map |

> Inline policies (`aws_iam_role_policy`) are embedded directly in the role and do not have an ARN exposed as output.

---

## `subject_claim` formats

### Azure DevOps — `service_connection_name`

The value is the service connection URI in the format:

```
sc://{Organization}/{Project}/{service-connection-name}
```

**Example:**
```
sc://ExampleOrg/Example Project/example-project-aws-dev-assumerole
```

> Find this value in Azure DevOps at: **Project Settings → Service connections → {your connection} → OIDC connection properties.**

### GitHub Actions — `subject_claim`

The `sub` claim is automatically generated by GitHub based on the workflow execution context.

| Context | Format |
| --- | --- |
| Specific branch | `repo:{Org}/{repo}:ref:refs/heads/{branch}` |
| Tag | `repo:{Org}/{repo}:ref:refs/tags/{tag}` |
| Pull Request | `repo:{Org}/{repo}:pull_request` |
| Environment | `repo:{Org}/{repo}:environment:{environment}` |
| Any context | `repo:{Org}/{repo}:*` |

**Examples:**
```
repo:ExampleOrg/example-project:ref:refs/heads/main
repo:ExampleOrg/example-project:environment:production
repo:ExampleOrg/example-project:*
```

> The trust condition uses `StringLike`, so wildcards (`*`) are supported.

### GitLab CI/CD — `subject_claim`

The `sub` claim is generated by GitLab based on the pipeline.

| Context | Format |
| --- | --- |
| Branch | `project_path:{group}/{project}:ref_type:branch:ref:{branch}` |
| Tag | `project_path:{group}/{project}:ref_type:tag:ref:{tag}` |
| Any ref | `project_path:{group}/{project}:*` |

**Examples:**
```
project_path:example-group/example-project:ref_type:branch:ref:main
project_path:example-group/example-project:ref_type:tag:ref:v1.0.0
project_path:example-group/example-project:*
```

> The trust condition uses `StringLike`, so wildcards (`*`) are supported.

---

## Thumbprints

Thumbprints are the SHA-1 hash of the root CA certificate of the OIDC endpoint. They need to be updated if the provider renews its root certificate.

| Provider | Default thumbprint(s) |
| --- | --- |
| Azure DevOps | `6938fd4d98bab03faadb97b34396831e3780aea1` |
| GitHub Actions | `6938fd4d98bab03faadb97b34396831e3780aea1`, `1c58a3a8518e8759bf075b76b750d4f2df264fcd` |
| GitLab SaaS | `b3dd7606d2b5a8b4a13771dbecc9ee1cecafa38a` |

**How to get the thumbprint for a self-hosted GitLab instance:**

```bash
echo | openssl s_client \
  -servername gitlab.yourcompany.com \
  -connect gitlab.yourcompany.com:443 2>/dev/null \
  | openssl x509 -fingerprint -noout \
  | cut -d= -f2 | tr -d ':' | tr '[:upper:]' '[:lower:]'
```

---

## Usage example

```hcl
module "assumerole" {
  source = "./modulos_baselabs/tf-baselabsmodules-assumerole"

  account_initials = "mycompany-dev"

  default_tags = {
    ManagedBy   = "terraform"
    Environment = "dev"
    Owner       = "platform-team"
  }

  # ── Azure DevOps ──────────────────────────────────────────────────────────
  assume_role_azuredevops = {
    enable           = true
    org_azure_devops = "a1b2c3d4-e5f6-7890-abcd-ef1234567890"

    project_azure_devops = {
      example-project = {
        enable_role             = true
        project_name            = "Example Project"
        service_connection_name = "sc://ExampleOrg/Example Project/example-project-aws-dev-assumerole"

        # Option A: managed policy
        permissions = [
          "ecr:*",
          "ecs:Register*", "ecs:Describe*", "ecs:List*", "ecs:Update*",
          "iam:PassRole",
          "s3:Get*", "s3:List*", "s3:Put*"
        ]

        # Option B: inline policy (use one or both as needed)
        # inline_policy = jsonencode({
        #   Version = "2012-10-17"
        #   Statement = [{ Effect = "Allow", Action = ["s3:*"], Resource = "*" }]
        # })
      }
    }
  }

  # ── GitHub Actions ────────────────────────────────────────────────────────
  assume_role_github = {
    enable     = true
    github_org = "ExampleOrg"

    repositories = {
      example-project = {
        enable_role   = true
        repo_name     = "example-project"
        subject_claim = "repo:ExampleOrg/example-project:ref:refs/heads/main"
        permissions = [
          "ecr:*",
          "s3:Get*", "s3:List*", "s3:Put*"
        ]
      }
    }
  }

  # ── GitLab CI/CD ──────────────────────────────────────────────────────────
  assume_role_gitlab = {
    enable = true

    projects = {
      example-project = {
        enable_role   = true
        project_path  = "example-group/example-project"
        subject_claim = "project_path:example-group/example-project:ref_type:branch:ref:main"
        permissions = [
          "ecr:*",
          "s3:Get*", "s3:List*", "s3:Put*"
        ]
      }
    }
  }
}
```

**Accessing the outputs:**

```hcl
output "pipeline_role_arn" {
  value = module.assumerole.azuredevops_role_arns["example-project"]
}

output "github_oidc_arn" {
  value = module.assumerole.github_oidc_provider_arn
}
```

---

## Pipeline configuration

### Azure DevOps

In the YAML pipeline, configure the service connection with the role ARN and use the `AWSShellScript` task:

```yaml
- task: AWSShellScript@1
  inputs:
    awsCredentials: 'example-project-aws-dev-assumerole'
    regionName: 'us-east-1'
    scriptType: 'inline'
    inlineScript: |
      aws sts get-caller-identity
```

### GitHub Actions

```yaml
permissions:
  id-token: write
  contents: read

steps:
  - name: Configure AWS credentials
    uses: aws-actions/configure-aws-credentials@v4
    with:
      role-to-assume: arn:aws:iam::123456789012:role/mycompany-dev-role-example-project-github-actions-oidc
      aws-region: us-east-1
```

### GitLab CI/CD

```yaml
assume_role:
  image: amazon/aws-cli
  id_tokens:
    AWS_OIDC_TOKEN:
      aud: https://gitlab.com
  script:
    - >
      aws sts assume-role-with-web-identity
      --role-arn "arn:aws:iam::123456789012:role/mycompany-dev-role-example-project-gitlab-cicd-oidc"
      --role-session-name "gitlab-pipeline"
      --web-identity-token "$AWS_OIDC_TOKEN"
      --duration-seconds 3600
```
