# Terragrunt CI/CD

A reference repository demonstrating how to deploy infrastructure using **Terragrunt v1** (explicit stacks) with GitHub Actions CI/CD, local development via Floci, and automated dependency updates via Renovate.

> Companion to [terraform-ci-cd](https://github.com/felipelaptrin/terraform-ci-cd), adapted for Terragrunt v1 patterns.

## Features

- **Terragrunt v1 explicit stacks** — `terragrunt.stack.hcl` files compose multiple units into deployable stacks
- **Two module patterns** — reusable `units/` for repeated infrastructure, inline `tfr:///` for one-off resources
- **Community Terraform modules** — no local wrapper modules; `terraform-aws-modules` referenced directly
- **Pre-commit hooks** — `terragrunt-hcl-fmt` and file hygiene checks
- **Trivy security scan** — runs in CI after `terragrunt plan`, scanning `tfplan.json` with resolved variable values (HIGH/CRITICAL)
- **Local development** — Floci (local AWS emulator) via Docker Compose for offline plan/apply
- **GitHub Actions** — parallel plans on PRs with PR comments, sequential apply (dev → prod with manual approval)
- **OIDC authentication** — no long-lived AWS credentials; GitHub Actions assumes IAM roles via OIDC
- **Cache optimizations** — Terraform provider cache, Terragrunt module cache, mise tools cache, pre-commit env cache
- **Renovate** — weekly automated dependency updates for mise tools, Terraform modules, and GitHub Actions

## Prerequisites

| Tool | Purpose |
|------|---------|
| [mise](https://mise.jdx.dev) | Tool version manager and task runner |
| [Docker](https://www.docker.com) | Required for Floci local development |
| [AWS CLI](https://aws.amazon.com/cli/) | Used by `floci-up` to bootstrap the local state bucket |

## Quick Start (Local Development)

```bash
# Install all pinned tools (terraform, terragrunt, pre-commit, trivy...)
mise install

# Install pre-commit hooks
mise run pre-commit-install

# Start Floci (local AWS emulator) and bootstrap the state bucket
mise run floci-up

# Plan all stacks in the local environment
mise run plan-local

# Apply all stacks in the local environment
mise run apply-local

# Tear down Floci
mise run floci-down
```

## Directory Structure

```
.
├── live/                          # Live infrastructure (Terragrunt hierarchy)
│   ├── dev/
│   │   ├── account.hcl            # Dev account ID + environment name
│   │   └── us-east-1/
│   │       ├── region.hcl         # Region config
│   │       └── demo-stack/
│   │           └── terragrunt.stack.hcl  # Explicit stack definition
│   ├── prod/
│   │   ├── account.hcl
│   │   └── us-east-1/
│   │       ├── region.hcl
│   │       └── demo-stack/
│   │           └── terragrunt.stack.hcl
│   └── local/                     # Floci environment (local dev only)
│       ├── account.hcl
│       └── us-east-1/
│           ├── region.hcl
│           └── demo-stack/
│               └── terragrunt.stack.hcl
├── units/                         # Reusable Terragrunt unit definitions
│   ├── bucket/terragrunt.hcl      # S3 bucket (terraform-aws-modules/s3-bucket)
│   └── sqs/terragrunt.hcl         # SQS queue (terraform-aws-modules/sqs)
├── root.hcl                       # Shared root config (remote state, provider, tags)
├── .mise.toml                     # Tool versions + task runner
├── .pre-commit-config.yaml        # Pre-commit hook definitions
├── docker-compose.yaml            # Floci local AWS emulator
└── renovate.json                  # Automated dependency updates
```

## Module Patterns

This repo demonstrates two ways to reference Terraform modules in Terragrunt:

### 1. Reusable Units (for repeated infrastructure)

Create a `terragrunt.hcl` in `units/<name>/` and reference it from any stack. Ideal when the same resource type appears across multiple stacks or environments.

```hcl
# units/bucket/terragrunt.hcl
terraform {
  source = "tfr:///terraform-aws-modules/s3-bucket/aws?version=4.6.0"
}
inputs = {
  bucket = values.bucket_name  # injected by the stack
  ...
}
```

```hcl
# live/dev/us-east-1/demo-stack/terragrunt.stack.hcl
unit "bucket" {
  source = "${get_repo_root()}/units/bucket"
  path   = "bucket"
  values = { bucket_name = "my-bucket" }
}
```

### 2. Direct Community Module (for one-off resources)

Reference a community module inline in the stack file — no `units/` directory needed.

```hcl
# live/dev/us-east-1/demo-stack/terragrunt.stack.hcl
unit "sns" {
  source = "tfr:///terraform-aws-modules/sns/aws?version=6.1.0"
  path   = "sns"
  values = { name = "my-topic" }
}
```

## Adding New Infrastructure

### New stack under an existing environment/region

Create a new directory with a `terragrunt.stack.hcl`. It is automatically discovered by the CI/CD pipeline — no workflow changes needed.

```
live/dev/us-east-1/
├── demo-stack/
│   └── terragrunt.stack.hcl
└── network-stack/           ← new
    └── terragrunt.stack.hcl
```

### New reusable unit

Add a `terragrunt.hcl` under `units/<name>/` and reference it from any stack via `source = "${get_repo_root()}/units/<name>"`.

### New region

1. Add `live/<env>/<region>/region.hcl`
2. Add stack directories under that region
3. Add plan + apply jobs to `.github/workflows/main.yaml`

### New environment

1. Add `live/<env>/account.hcl` with `environment` and `account_id`
2. Add region + stack directories
3. Add jobs to `.github/workflows/main.yaml`
4. Create the corresponding GitHub environment (with protection rules for prod)
5. Add `DEV_TERRAFORM_ROLE` / `PROD_TERRAFORM_ROLE` variable to the GitHub repository

## CI/CD Pipeline

```
┌─ Pull Request ──────────────────────────────────────┐
│  ci            → pre-commit run --all-files          │
│  plan-dev      → terragrunt run --all plan (DEV)     │
│  plan-prod     → terragrunt run --all plan (PROD)    │
│                  (plan output posted as PR comment)  │
└─────────────────────────────────────────────────────┘

┌─ Merge to main ─────────────────────────────────────┐
│  plan-dev  ──→ apply-dev  ──┐                        │
│                              ├──→ apply-prod          │
│  plan-prod ─────────────────┘                        │
│              (prod requires manual approval)         │
└─────────────────────────────────────────────────────┘
```

- Plans always run (on both PRs and merges) for fast feedback
- Plan output for each environment is posted as a collapsible PR comment and updated on re-run
- Dev apply runs automatically on merge to `main`
- Prod apply requires dev to succeed first, then waits for manual approval via the `prod` GitHub environment

### GitHub Setup

Create two GitHub environments:

| Environment | Protection |
|-------------|-----------|
| `dev` | None (auto-deploy) |
| `prod` | Required reviewers |

Add these repository variables (not secrets — IAM roles are assumed via OIDC):

| Variable | Value |
|----------|-------|
| `DEV_TERRAFORM_ROLE` | ARN of the IAM role for the dev account |
| `PROD_TERRAFORM_ROLE` | ARN of the IAM role for the prod account |

For Renovate, add these repository secrets:

| Secret | Value |
|--------|-------|
| `RENOVATE_APP_ID` | GitHub App ID |
| `RENOVATE_APP_PRIVATE_KEY` | GitHub App private key |

## Local Development

[Floci](https://floci.io) is used as a local AWS emulator (similar to LocalStack). It runs via Docker Compose and exposes an AWS-compatible API on `http://localhost:4566`.

The `local` environment in `live/local/` is pre-configured with Floci endpoints in `root.hcl` — no code changes needed to switch between local and cloud.

```
mise run floci-up     # starts Floci + creates the S3 state bucket
mise run plan-local   # plans all stacks against Floci
mise run apply-local  # applies all stacks against Floci
mise run floci-down   # stops Floci
```

## Available Tasks

Run any task with `mise run <task>`:

| Task | Description |
|------|-------------|
| `floci-up` | Start Floci and bootstrap the local state bucket |
| `floci-down` | Stop Floci |
| `plan-local` | Plan all stacks in `live/local/us-east-1` against Floci |
| `apply-local` | Apply all stacks in `live/local/us-east-1` against Floci |
| `pre-commit-install` | Install pre-commit git hooks |
| `pre-commit` | Run all pre-commit hooks against all files |
