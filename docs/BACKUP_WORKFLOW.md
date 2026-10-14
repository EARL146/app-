# Safe GitHub Backup Workflow

[[PROJECT_HOME]] · [[INTEGRATION_MAP]] · [[SECURITY]] · [[NEXT_SESSION]]

## Current Git facts

- Repository root: `C:\Users\shizu\OneDrive\Documents\Ampps\www\Burger_bites`.
- Current branch: `main`, tracking `origin/main`.
- Configured remote (credentials redacted): `https://github.com/EARL146/app-.git`.
- Read-only remote connectivity was verified with `git ls-remote --heads origin main`.
- The user explicitly requested that the current BurgerBites and workflow changes be pushed to GitHub. Review the exact staged files and diffs, then verify the remote hash after publishing.

## Review before staging

Run from the repository root in PowerShell:

```powershell
git status --short --branch
git diff --check
git diff --stat
git diff
git diff --cached --check
git diff --cached
git ls-files --others --exclude-standard
git check-ignore -v backend/.env
```

Review changed and untracked files manually for secrets and generated output. The root `.gitignore` excludes `.env` and `.env.*` except `.env.example`; `backend/.gitignore` also excludes `.env`. Never print or stage secret contents.

**Do not stage `.obsidian/workspace.json` or `.obsidian/graph.json`.** They are tracked and modified local UI state, so `.gitignore` cannot hide these changes. Also exclude ignored `graphify-out/` and `.icm/` data and `backend/.env`. Avoid `git add .` and `git add -A`. If the user decides to stop tracking Obsidian's local files in future commits, review any staged removal explicitly; do not rewrite remote history to erase earlier versions.

## Stage and publish only when authorized

For tracked files that mix old and new edits, use interactive hunk selection:

```powershell
git add -p README.md .gitignore docs/PROJECT_MAP.md docs/SCREEN_FLOW.md docs/API_DATABASE.md docs/DECISIONS.md docs/KNOWN_ISSUES.md docs/NEXT_SESSION.md docs/CHANGELOG.md
```

Add intended new files by exact path, not with a wildcard. Before committing:

```powershell
git diff --cached --check
git diff --cached --stat
git diff --cached
```

The user authorized the current commit and push. Use a clear message such as:

```powershell
git commit -m "Document Burger_bites development workflow"
```

Push the existing branch without force:

```powershell
git push origin main
git status --short --branch
git ls-remote --heads origin main
```

If the push is rejected because the remote moved, stop and review/merge; never reset, overwrite, delete, or force-push remote history. Confirm the final commit hash and remote branch result.
