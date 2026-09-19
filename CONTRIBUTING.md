# Contributing

Contributions should preserve the published data snapshot and make methodology or presentation changes explicit.

Before opening a pull request:

```sh
python3 tools/check_repository.py
```

Do not silently change the October 2025 data snapshot, reported counts, cultural classifications, or diversity metrics as part of an unrelated site/maintenance change. Keep machine-local paths and credentials out of the public repository. Changes to generated HTML should preserve valid repository-relative asset links.
