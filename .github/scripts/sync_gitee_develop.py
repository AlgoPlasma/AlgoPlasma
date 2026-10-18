#!/usr/bin/env python3
"""Import Gitee develop history and generate GitHub's English presentation.

Only Git objects are read from Gitee. No source checkout, hooks, or source-side
scripts are executed. The controller must be maintained on GitHub main.
"""
from __future__ import annotations

import base64
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile
from dataclasses import dataclass


TOOL = "algoplasma-gitee-develop"
RECIPE_VERSION = 1
BOOTSTRAP = "4ad1f7d4261a9efe4975a079509c818356de3dc1"
JS_PATH = "docs/source/_static/ap-language-switch.js"
CSS_PATH = "docs/source/_static/custom.css"
SHA = re.compile(r"^[0-9a-f]{40}$")


class SyncError(RuntimeError):
    pass


@dataclass
class Config:
    source_url: str = "https://gitee.com/algoplasma/algoplasma.git"
    target_url: str = "https://github.com/AlgoPlasma/AlgoPlasma.git"
    bootstrap: str = BOOTSTRAP
    dry_run: bool = True
    token: str = ""


def git(repo: Path, *args: str, data: bytes | None = None,
        extra_env: dict[str, str] | None = None,
        allowed: tuple[int, ...] = (0,)) -> bytes:
    env = os.environ.copy()
    for key in list(env):
        if key in {"GITHUB_TOKEN", "GH_TOKEN", "GIT_CONFIG_COUNT", "GIT_CONFIG_PARAMETERS",
                   "GIT_DIR", "GIT_WORK_TREE", "GIT_INDEX_FILE", "GIT_CURL_VERBOSE"} or key.startswith(("GIT_TRACE", "GIT_CONFIG_KEY_", "GIT_CONFIG_VALUE_")):
            env.pop(key, None)
    env.update({"GIT_TERMINAL_PROMPT": "0", "GIT_NO_REPLACE_OBJECTS": "1"})
    if extra_env:
        env.update(extra_env)
    result = subprocess.run(["git", "-C", str(repo), *args], input=data,
                            stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                            env=env, timeout=300)
    if result.returncode not in allowed:
        # Credentials are passed only through environment, never through argv.
        raise SyncError("git " + args[0] + " failed:\n" + result.stderr.decode("utf-8", "replace"))
    return result.stdout


def revision(repo: Path, ref: str) -> str:
    return git(repo, "rev-parse", "--verify", ref).decode().strip()


def ancestor(repo: Path, older: str, newer: str) -> bool:
    if older == newer:
        return True
    base = git(repo, "merge-base", older, newer, allowed=(0, 1)).decode().strip()
    return base == older


def entries(repo: Path, ref: str) -> dict[str, tuple[str, str, str]]:
    result = {}
    for record in git(repo, "ls-tree", "-r", "-z", ref).split(b"\0"):
        if record:
            info, path = record.split(b"\t", 1)
            mode, kind, sha = info.decode().split()
            result[path.decode("utf-8")] = (mode, kind, sha)
    return result


def replace_once(text: str, pattern: str, replacement: str, label: str) -> str:
    updated, count = re.subn(pattern, lambda _: replacement, text, flags=re.S)
    if count != 1:
        raise SyncError(f"{label}: expected one match, found {count}; update the main controller first")
    return updated


def generated_tree(repo: Path, source: str) -> tuple[str, int]:
    source_entries = entries(repo, source)
    git(repo, "read-tree", source + "^{tree}")
    count = 0
    for path, (mode, kind, blob) in source_entries.items():
        if path == "README.en.md" or path.endswith("/README.en.md"):
            if kind != "blob" or mode not in {"100644", "100755"}:
                raise SyncError(f"English README must be a regular file: {path}")
            target = path[:-len("README.en.md")] + "README.md"
            existing = source_entries.get(target)
            if existing and existing[0] not in {"100644", "100755"}:
                raise SyncError(f"Default README must be a regular file: {target}")
            target_mode = existing[0] if existing else mode
            git(repo, "update-index", "--add", "--cacheinfo", target_mode, blob, target)
            count += 1
    if not count:
        raise SyncError("No README.en.md files found; refusing to publish an untranslated tree")

    for path in (JS_PATH, CSS_PATH):
        if path not in source_entries:
            continue
        mode, kind, blob = source_entries[path]
        if kind != "blob" or mode not in {"100644", "100755"}:
            raise SyncError(f"Language configuration must be a regular file: {path}")
        text = git(repo, "cat-file", "blob", blob).decode("utf-8")
        if path == JS_PATH:
            text = replace_once(text, r'var storageKey = "ap-doc-language(?:-github)?";',
                                'var storageKey = "ap-doc-language-github";', path + " storage key")
            text = replace_once(text, r'readStoredLanguage\(\) \|\| "(?:zh|en)"',
                                'readStoredLanguage() || "en"', path + " default")
        else:
            pair = r"(?m)^\.ap-lang-zh\s*\{\s*display:\s*none;\s*\}\s*^\.ap-lang-en\s*\{\s*display:\s*block;\s*\}"
            hidden_english = r"(?m)^\.ap-lang-en\s*\{\s*display:\s*none;\s*\}"
            replacement = ".ap-lang-zh {\n    display: none;\n}\n\n.ap-lang-en {\n    display: block;\n}"
            pattern = pair if re.search(pair, text, re.S) else hidden_english
            text = replace_once(text, pattern, replacement, path + " defaults")
        updated_blob = git(repo, "hash-object", "-w", "--stdin", data=text.encode("utf-8")).decode().strip()
        git(repo, "update-index", "--cacheinfo", mode, updated_blob, path)

    tree = revision(repo, git(repo, "write-tree").decode().strip())
    final_entries = entries(repo, tree)
    for path in source_entries.keys() | final_entries.keys():
        if source_entries.get(path) != final_entries.get(path):
            if path not in {JS_PATH, CSS_PATH} and not (path == "README.md" or path.endswith("/README.md")):
                raise SyncError("Unexpected generated change: " + path)
    return tree, count


def previous_source(repo: Path, target: str, config: Config) -> str | None:
    if target == config.bootstrap:
        return None
    message = git(repo, "show", "-s", "--format=%B", target).decode("utf-8")
    fields = {}
    for name in ("Sync-Tool", "Gitee-Source", "Generated-Tree", "Recipe-Version"):
        values = re.findall(r"^" + re.escape(name) + r": (.+)$", message, re.M)
        if len(values) != 1:
            raise SyncError("GitHub develop has an unrecognized commit; inspect manual changes before syncing")
        fields[name] = values[0]
    if fields["Sync-Tool"] != TOOL or not SHA.fullmatch(fields["Gitee-Source"]) or not SHA.fullmatch(fields["Generated-Tree"]):
        raise SyncError("Invalid synchronization metadata on GitHub develop")
    if not fields["Recipe-Version"].isdigit() or not 1 <= int(fields["Recipe-Version"]) <= RECIPE_VERSION:
        raise SyncError("Unsupported generation recipe on GitHub develop")
    if fields["Generated-Tree"] != revision(repo, target + "^{tree}"):
        raise SyncError("GitHub develop content changed after synchronization")
    source = fields["Gitee-Source"]
    if not ancestor(repo, source, target):
        raise SyncError("Recorded Gitee history is missing from GitHub develop")
    return source


def summary(text: str) -> None:
    print(text, flush=True)
    filename = os.environ.get("GITHUB_STEP_SUMMARY")
    if filename:
        with open(filename, "a", encoding="utf-8") as output:
            output.write(text + "\n")


def synchronize(config: Config, repo: Path) -> dict[str, str]:
    git(repo, "init", "--bare", ".")
    git(repo, "remote", "add", "origin", config.target_url)
    git(repo, "remote", "add", "gitee", config.source_url)
    git(repo, "fetch", "--no-tags", "origin", "refs/heads/develop:refs/remotes/github/develop")
    git(repo, "fetch", "--no-tags", "gitee", "refs/heads/develop:refs/remotes/gitee/develop")
    target = revision(repo, "refs/remotes/github/develop")
    source = revision(repo, "refs/remotes/gitee/develop")
    previous = previous_source(repo, target, config)
    if previous and not ancestor(repo, previous, source):
        raise SyncError("Gitee develop was rewound or rewritten; inspect it before resuming")
    tree, readme_count = generated_tree(repo, source)
    already_imported = ancestor(repo, source, target)
    summary(f"Mode: {'DRY RUN (no push)' if config.dry_run else 'LIVE'}\n\nGitee source: `{source}`\n\nGitHub before: `{target}`\n\nEnglish README defaults: {readme_count}")
    if already_imported and tree == revision(repo, target + "^{tree}"):
        summary("Result: already synchronized; no commit and no push.")
        return {"status": "unchanged", "source": source, "before": target, "after": target}

    parents = [target] if already_imported else [target, source]
    message = (f"Sync Gitee develop {source[:12]} with English documentation\n\n"
               f"Sync-Tool: {TOOL}\nGitee-Source: {source}\n"
               f"Generated-Tree: {tree}\nRecipe-Version: {RECIPE_VERSION}\n")
    identity = {"GIT_AUTHOR_NAME": "github-actions[bot]", "GIT_COMMITTER_NAME": "github-actions[bot]",
                "GIT_AUTHOR_EMAIL": "41898282+github-actions[bot]@users.noreply.github.com",
                "GIT_COMMITTER_EMAIL": "41898282+github-actions[bot]@users.noreply.github.com"}
    parent_args = [item for parent in parents for item in ("-p", parent)]
    commit = git(repo, "commit-tree", tree, *parent_args, data=message.encode(), extra_env=identity).decode().strip()
    actual_parents = git(repo, "show", "-s", "--format=%P", commit).decode().split()
    if actual_parents != parents or not ancestor(repo, source, commit) or not ancestor(repo, target, commit):
        raise SyncError("Synchronization ancestry verification failed")
    changes = git(repo, "diff", "--stat", target, commit).decode("utf-8", "replace").strip()
    summary(f"Prepared commit: `{commit}`\n\nChanges versus GitHub develop:\n\n```text\n{changes or '(no file changes; importing new source history)'}\n```")
    if config.dry_run:
        summary("Result: preview complete. Remote branches were not changed.")
        return {"status": "preview", "source": source, "before": target, "after": commit}

    remote = git(repo, "ls-remote", "--exit-code", "origin", "refs/heads/develop").decode().split()[0]
    if remote != target:
        raise SyncError("GitHub develop changed during this run; refusing to overwrite it")
    authentication = {}
    if config.token:
        if config.target_url != Config.target_url:
            raise SyncError("Refusing to send the GitHub token to a different repository")
        value = base64.b64encode(("x-access-token:" + config.token).encode()).decode()
        authentication = {"GIT_CONFIG_COUNT": "1", "GIT_CONFIG_KEY_0": "http.https://github.com/.extraheader",
                          "GIT_CONFIG_VALUE_0": "AUTHORIZATION: basic " + value}
    elif config.target_url.startswith(("https://", "http://")):
        raise SyncError("A GitHub token is required for live synchronization")
    # A normal fast-forward push only; never force or mirror push.
    git(repo, "push", "origin", commit + ":refs/heads/develop", extra_env=authentication)
    summary("Result: GitHub develop updated successfully.")
    return {"status": "pushed", "source": source, "before": target, "after": commit}


def main() -> int:
    dry_run = os.environ.get("DRY_RUN", "true").lower()
    if dry_run not in {"true", "false"}:
        raise SyncError("DRY_RUN must be true or false")
    config = Config(dry_run=dry_run == "true", token=os.environ.get("GITHUB_TOKEN", ""))
    temp_root = Path(os.environ.get("RUNNER_TEMP") or tempfile.gettempdir()).resolve()
    with tempfile.TemporaryDirectory(prefix="algoplasma-sync-", dir=temp_root) as name:
        work = Path(name).resolve()
        if work.parent != temp_root or not work.name.startswith("algoplasma-sync-"):
            raise SyncError("Invalid temporary repository directory")
        synchronize(config, work)
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (SyncError, subprocess.TimeoutExpired, UnicodeError) as error:
        print("Synchronization stopped: " + str(error), file=sys.stderr)
        sys.exit(1)
