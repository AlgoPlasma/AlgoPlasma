# Maintenance Scripts

This directory contains helper scripts for maintaining local working trees of
AlgoPlasma. These scripts are not required for building or running the
algorithm examples and tests.

## `sync_github_from_gitee.sh`

Synchronize the local Gitee working tree to a separate local GitHub working
tree, while preserving the GitHub repository's own `.git/` directory. After
the file sync, the script adjusts the GitHub copy so that English is the
default entry language:

- `README.en.md` is copied to `README.md`.
- The documentation language switch defaults to English.
- The documentation CSS shows English blocks by default.

Default paths:

```text
Gitee working tree:  /home/yin/algoplasma
GitHub working tree: /home/yin/algoplasma-github/AlgoPlasma
```

Run from the Gitee working tree:

```bash
cd /home/yin/algoplasma
./scripts/sync_github_from_gitee.sh
```

If the paths change, override them with environment variables:

```bash
GITEE_REPO=/path/to/algoplasma \
GITHUB_REPO=/path/to/AlgoPlasma \
./scripts/sync_github_from_gitee.sh
```

The target directory must already be a Git working tree. The script refuses to
run if the target does not contain `.git/`, which helps avoid accidentally
syncing into the wrong directory.

The script uses `rsync --delete`, so files that no longer exist in the Gitee
working tree are removed from the GitHub working tree, except for excluded
paths such as `.git/`, `.venv/`, `docs/build/`, `docs/source/_doxygen/`, and
Python cache files.
