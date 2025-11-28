#!/usr/bin/env bash
set -euo pipefail

echo "=== WP Training Team: Dependabot + auto-approve + auto-merge setup ==="

# 1. Ask for repo directory
read -rp "Enter the path to your local repository directory: " REPO_DIR
if [ ! -d "$REPO_DIR" ]; then
  echo "Error: Directory '$REPO_DIR' does not exist."
  exit 1
fi

# Move into the repo directory
cd "$REPO_DIR"

# Optional: verify it's a git repo
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Error: '$REPO_DIR' is not a Git repository."
  exit 1
fi

# Create and switch to the feature branch
echo "Creating and switching to branch: add-dependabot-workflows"
git checkout -b add-dependabot-workflows 2>/dev/null || git checkout add-dependabot-workflows

# 2. Ask for GitHub username
read -rp "Enter your GitHub username (for assignees/reviewers): " GH_USER
if [ -z "$GH_USER" ]; then
  echo "Error: GitHub username cannot be empty."
  exit 1
fi

# 3. Choose example/template
echo
echo "Choose project type / Dependabot example:"
echo "  1) PHP (Composer) project"
echo "  2) JavaScript (npm) project"
echo "  3) Both npm and Composer dependencies"
read -rp "Enter choice (1-3): " EXAMPLE_CHOICE

case "$EXAMPLE_CHOICE" in
  1)
    TEMPLATE_NAME="php"
    ;;
  2)
    TEMPLATE_NAME="js"
    ;;
  3)
    TEMPLATE_NAME="both"
    ;;
  *)
    echo "Invalid choice."
    exit 1
    ;;
esac

# 4. Ensure .github directory and workflows directory exist
GITHUB_DIR="$REPO_DIR/.github"
WORKFLOWS_DIR="$GITHUB_DIR/workflows"
mkdir -p "$WORKFLOWS_DIR"

DEPENDABOT_FILE="$GITHUB_DIR/dependabot.yml"
AUTO_APPROVE_FILE="$WORKFLOWS_DIR/dependabot-auto-approve.yml"
AUTO_MERGE_FILE="$WORKFLOWS_DIR/dependabot-auto-merge.yml"

echo
echo "Creating Dependabot configuration at:"
echo "  $DEPENDABOT_FILE"
echo

# 5. Generate dependabot.yml based on choice
case "$TEMPLATE_NAME" in
  php)
    cat > "$DEPENDABOT_FILE" <<EOF
# Dependabot configuration for a PHP/Composer project
# Based on the WP Training Team Dependabot guide (Example 1).

version: 2
updates:
  - package-ecosystem: "composer"
    directory: "/"              # location of composer.json
    schedule:
      interval: "weekly"        # or "daily", "monthly"
    assignees:
      - "$GH_USER"
    reviewers:
      - "$GH_USER"
    open-pull-requests-limit: 10
EOF
    ;;

  js)
    cat > "$DEPENDABOT_FILE" <<EOF
# Dependabot configuration for a JavaScript/npm project
# Based on the WP Training Team Dependabot guide (Example 2).

version: 2
updates:
  - package-ecosystem: "npm"
    directory: "/"              # location of package.json
    schedule:
      interval: "weekly"        # or "daily", "monthly"
    assignees:
      - "$GH_USER"
    open-pull-requests-limit: 10
EOF
    ;;

  both)
    cat > "$DEPENDABOT_FILE" <<EOF
# Dependabot configuration for both Composer and npm dependencies
# Based on the WP Training Team Dependabot guide (Example 3).

version: 2
updates:
  - package-ecosystem: "composer"
    directory: "/"              # location of composer.json
    schedule:
      interval: "weekly"
    assignees:
      - "$GH_USER"
    open-pull-requests-limit: 10

  - package-ecosystem: "npm"
    directory: "/"              # location of package.json
    schedule:
      interval: "weekly"
    assignees:
      - "$GH_USER"
    open-pull-requests-limit: 10
EOF
    ;;
esac

echo "Dependabot configuration created."

# 6. Create the auto-approve workflow

echo
echo "Creating GitHub Actions auto-approve workflow at:"
echo "  $AUTO_APPROVE_FILE"
echo

cat > "$AUTO_APPROVE_FILE" <<'EOF'
name: Dependabot auto-approve

on: pull_request

permissions:
  pull-requests: write

jobs:
  dependabot:
    runs-on: ubuntu-latest
    # Only run for PRs opened by Dependabot
    if: github.event.pull_request.user.login == 'dependabot[bot]'
    steps:
      - name: Approve Dependabot PR
        run: gh pr review --approve "$PR_URL"
        env:
          PR_URL: ${{ github.event.pull_request.html_url }}
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
EOF

echo "Auto-approve workflow created."

# 7. Create the auto-merge workflow

echo
echo "Creating GitHub Actions auto-merge workflow at:"
echo "  $AUTO_MERGE_FILE"
echo

cat > "$AUTO_MERGE_FILE" <<'EOF'
name: Dependabot auto-merge

on: pull_request

permissions:
  contents: write
  pull-requests: write

jobs:
  dependabot:
    runs-on: ubuntu-latest
    # Only run for PRs opened by Dependabot
    if: github.event.pull_request.user.login == 'dependabot[bot]'
    steps:
      - name: Dependabot metadata
        id: metadata
        uses: dependabot/fetch-metadata@v2
        with:
          github-token: "${{ secrets.GITHUB_TOKEN }}"

      - name: Auto-merge changes from Dependabot
        # Auto-merge all non-major updates, and all GitHub Actions updates
        if: steps.metadata.outputs.update-type != 'version-update:semver-major' || steps.metadata.outputs.package-ecosystem == 'github_actions'
        run: gh pr merge --auto --squash "$PR_URL"
        env:
          PR_URL: ${{ github.event.pull_request.html_url }}
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
EOF

echo "Auto-merge workflow created."

# 8. Show previews

echo
echo "===== Preview: .github/dependabot.yml ====="
echo
cat "$DEPENDABOT_FILE"

echo
echo "===== Preview: .github/workflows/dependabot-auto-approve.yml ====="
echo
cat "$AUTO_APPROVE_FILE"

echo
echo "===== Preview: .github/workflows/dependabot-auto-merge.yml ====="
echo
cat "$AUTO_MERGE_FILE"
echo
echo "================================================================"

# 9. Summary / next steps

echo
echo "You are now on branch 'add-dependabot-workflows'."
echo
echo "Next steps:"
echo " In this repo, run:"
echo "   git status"
echo "   git add .github/dependabot.yml .github/workflows/dependabot-auto-approve.yml .github/workflows/dependabot-auto-merge.yml"
echo "   git commit -m \"Add Dependabot config, auto-approve, and auto-merge workflows\""
echo "   git push -u origin add-dependabot-workflows"
echo
echo "Done."