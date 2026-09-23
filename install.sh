#!/bin/sh
set -eu

PROJECT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
SOURCE_DIR="$PROJECT_DIR/slap"
SLAP_USER_HOME=${SLAP_INSTALL_HOME:-${HOME:?HOME is not set}}
MARKER_FILE="$SOURCE_DIR/.ai-slapper-install"
REMOVAL_FAILED=0

case "$SLAP_USER_HOME" in
  ""|/)
    printf 'Refusing to use unsafe home path: %s\n' "$SLAP_USER_HOME" >&2
    exit 2
    ;;
  /*) ;;
  *)
    printf 'Refusing to use a non-absolute home path: %s\n' "$SLAP_USER_HOME" >&2
    exit 2
    ;;
esac

if [ ! -f "$MARKER_FILE" ]; then
  printf 'Installation marker is missing from the source package.\n' >&2
  exit 2
fi

usage() {
  printf 'Usage: %s [--install|--reinstall|--uninstall]\n' "$0"
}

is_managed_install() {
  candidate=$1
  [ -d "$candidate" ] &&
    [ ! -L "$candidate" ] &&
    [ -f "$candidate/.ai-slapper-install" ] &&
    cmp -s "$MARKER_FILE" "$candidate/.ai-slapper-install"
}

is_legacy_install() {
  candidate=$1
  [ -d "$candidate" ] &&
    [ ! -L "$candidate" ] &&
    [ -f "$candidate/SKILL.md" ] &&
    [ -f "$candidate/agents/openai.yaml" ] &&
    [ -f "$candidate/assets/slapper.html" ] &&
    [ -f "$candidate/scripts/open_slapper.py" ] &&
    cmp -s "$SOURCE_DIR/agents/openai.yaml" "$candidate/agents/openai.yaml" &&
    cmp -s "$SOURCE_DIR/scripts/open_slapper.py" "$candidate/scripts/open_slapper.py" &&
    grep -Fq 'name: slap' "$candidate/SKILL.md" &&
    grep -Fq 'Open a harmless local browser toy' "$candidate/SKILL.md" &&
    grep -Fq '<title>AI Slapper</title>' "$candidate/assets/slapper.html" &&
    grep -Fq 'connect-src '\''none'\''' "$candidate/assets/slapper.html"
}

install_skill() {
  target_root=$1
  product=$2
  target="$target_root/slap"

  mkdir -p "$target_root"
  if [ -e "$target" ] || [ -L "$target" ]; then
    if is_managed_install "$target"; then
      printf '%s already has AI Slapper at %s (left unchanged).\n' "$product" "$target"
    else
      printf '%s already has an unmanaged slap entry at %s (left unchanged).\n' "$product" "$target" >&2
    fi
    return
  fi

  cp -R "$SOURCE_DIR" "$target"
  printf 'Installed for %s: %s\n' "$product" "$target"
}

remove_skill() {
  target_root=$1
  product=$2
  target="$target_root/slap"

  if [ ! -e "$target" ] && [ ! -L "$target" ]; then
    printf 'AI Slapper is not installed for %s at %s.\n' "$product" "$target"
    return
  fi

  if [ -L "$target" ]; then
    printf 'Refusing to remove symlink at %s; remove it manually if intended.\n' "$target" >&2
    REMOVAL_FAILED=1
    return
  fi

  if ! is_managed_install "$target" && ! is_legacy_install "$target"; then
    printf 'Refusing to remove unverified directory at %s.\n' "$target" >&2
    REMOVAL_FAILED=1
    return
  fi

  rm -rf "$target"
  printf 'Removed AI Slapper for %s: %s\n' "$product" "$target"
}

if [ "$#" -gt 1 ]; then
  usage >&2
  exit 2
fi

COMMAND=${1:---install}
case "$COMMAND" in
  --install|install)
    install_skill "$SLAP_USER_HOME/.claude/skills" "Claude Code"
    install_skill "$SLAP_USER_HOME/.agents/skills" "Codex"
    printf '\nInvoke it with /slap in Claude Code or $slap in Codex.\n'
    ;;
  --uninstall|uninstall)
    remove_skill "$SLAP_USER_HOME/.claude/skills" "Claude Code"
    remove_skill "$SLAP_USER_HOME/.agents/skills" "Codex"
    if [ "$REMOVAL_FAILED" -ne 0 ]; then
      printf '\nRemoval was incomplete; unverified entries were left untouched.\n' >&2
      exit 1
    fi
    printf '\nAI Slapper removal complete. Parent skill directories were left intact.\n'
    ;;
  --reinstall|reinstall)
    remove_skill "$SLAP_USER_HOME/.claude/skills" "Claude Code"
    remove_skill "$SLAP_USER_HOME/.agents/skills" "Codex"
    if [ "$REMOVAL_FAILED" -ne 0 ]; then
      printf '\nReinstallation stopped; unverified entries were left untouched.\n' >&2
      exit 1
    fi
    install_skill "$SLAP_USER_HOME/.claude/skills" "Claude Code"
    install_skill "$SLAP_USER_HOME/.agents/skills" "Codex"
    printf '\nAI Slapper reinstalled. Invoke it with /slap in Claude Code or $slap in Codex.\n'
    ;;
  --help|-h|help)
    usage
    ;;
  *)
    printf 'Unknown option: %s\n' "$COMMAND" >&2
    usage >&2
    exit 2
    ;;
esac
