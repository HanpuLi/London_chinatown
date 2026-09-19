# Security policy

This repository is a static research site and reproducibility archive rather than a service that accepts credentials or executes untrusted user input. Security-sensitive findings include accidentally published credentials or personal machine data, unsafe third-party script/workflow changes, and repository changes that cause the public report to load assets from unintended locations.

## Reporting

Use GitHub private vulnerability reporting for security-sensitive findings. Do not include personal data or credentials in a public issue. The latest `main` branch receives fixes.

## Repository boundary

- Generated pipeline output belongs under ignored `build/`.
- CI uses least-privilege permissions and commit-pinned third-party actions.
- A fresh network data pull must not silently replace the archived 10 October 2025 OSM snapshot.
- Changes that alter classification totals are research-result changes and should be reviewed against `REPRODUCIBILITY.md`.
- Local HTML references in the public report are checked so accidental missing or escaping paths fail CI.
