# Security Policy

Please do not open a public issue for a vulnerability that could expose the
private dashboard source, build credentials, release credentials, device
credentials, or update infrastructure.

Report security issues privately to the Andless maintainers through the
organization's established private contact channel.

The build repository intentionally has no production publishing credentials.
If a workflow, GitHub App private key, or release artifact may have been
compromised, disable the workflow, revoke or suspend the dashboard-only GitHub
App installation, rotate its private key, and rotate any affected signing
material before rebuilding.
