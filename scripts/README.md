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

## `sync_gitee_from_github.sh`

Synchronize the local GitHub working tree back to a separate local Gitee
working tree, while preserving the Gitee repository's own `.git/` directory.
After the file sync, the script restores Chinese as the default entry
language:

- `README.zh-CN.md` is copied to `README.md` wherever the translated file is
  available.
- The documentation language switch defaults to Chinese.
- The documentation CSS shows Chinese blocks by default.

Default paths:

```text
GitHub working tree: /home/yin/algoplasma-github/AlgoPlasma
Gitee working tree:  /home/yin/algoplasma
```

Run from the GitHub working tree:

```bash
cd /home/yin/algoplasma-github/AlgoPlasma
./scripts/sync_gitee_from_github.sh
```

If the paths change, override them with environment variables:

```bash
GITHUB_REPO=/path/to/AlgoPlasma \
GITEE_REPO=/path/to/algoplasma \
./scripts/sync_gitee_from_github.sh
```

The target Gitee working tree must be clean because the synchronization can
overwrite tracked files and remove untracked files. If overwriting a dirty
target is intentional, opt in explicitly:

```bash
ALLOW_DIRTY_TARGET=1 ./scripts/sync_gitee_from_github.sh
```

The reverse script uses the same `rsync --delete` exclusions as the GitHub
sync script. In particular, it never copies or deletes either repository's
`.git/` directory. Review the final `git status` in the Gitee working tree,
then commit and push the synchronized changes from there.
