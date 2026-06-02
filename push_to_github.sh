#!/usr/bin/env bash
# Usage: ./push_to_github.sh <repo-url> [branch]
# Example: ./push_to_github.sh https://github.com/you/streak.git main
set -e
REPO="$1"; BRANCH="${2:-main}"
[ -z "$REPO" ] && { echo "Pass your repo URL as the first argument."; exit 1; }
git init
git add -A
git commit -m "Initial commit: cross-platform streak tracker with home-screen widgets"
git branch -M "$BRANCH"
git remote add origin "$REPO"
git push -u origin "$BRANCH"
