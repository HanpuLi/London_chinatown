# Security policy

This is a research/data repository rather than a service that accepts credentials or executes untrusted user input. Security concerns still include accidental publication of credentials, private source material, unsafe workflow changes and supply-chain changes in GitHub Actions.

## Reporting

Use GitHub private vulnerability reporting for security-sensitive findings. Do not paste credentials or private data into public issues.

## Repository boundary

- Generated pipeline output belongs under ignored `build/`.
- CI must use least-privilege permissions and commit-pinned third-party actions.
- A fresh network data pull must not silently replace the archived 10 October 2025 OSM snapshot.
- Changes that alter classification totals should be treated as research-result changes and reviewed against `REPRODUCIBILITY.md`.
