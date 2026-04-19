#!/usr/bin/env bash
# Resolve a source tree for install.sh / upgrade.sh from either the current
# checkout or an explicit Git ref/tag exported as a clean temporary tree.

resolve_governance_source() {
  local checkout_dir="$1"
  local requested_ref="$2"
  local out_dir_var="$3"
  local out_label_var="$4"

  local resolved_dir="$checkout_dir"
  local resolved_label="checkout atual"

  if [[ -n "$requested_ref" ]]; then
    if ! command -v git >/dev/null 2>&1; then
      echo "ERRO: git nao encontrado. Nao e possivel usar ref explicita: $requested_ref" >&2
      return 1
    fi

    local repo_root resolved_commit archive_dir
    if ! repo_root="$(git -C "$checkout_dir" rev-parse --show-toplevel 2>/dev/null)"; then
      echo "ERRO: ref explicita requer checkout Git valido. Nao foi possivel resolver: $requested_ref" >&2
      return 1
    fi

    if ! resolved_commit="$(git -C "$repo_root" rev-parse --verify "${requested_ref}^{commit}" 2>/dev/null)"; then
      echo "ERRO: ref/tag invalida ou inexistente: $requested_ref" >&2
      echo "Dica: use um nome resolvivel por 'git rev-parse', como branch, tag ou SHA." >&2
      return 1
    fi

    archive_dir="$(mktemp -d)"
    if ! git -C "$repo_root" archive --format=tar "$resolved_commit" | tar -xf - -C "$archive_dir"; then
      rm -rf "$archive_dir"
      echo "ERRO: falha ao materializar a arvore da ref explicita: $requested_ref" >&2
      return 1
    fi

    resolved_dir="$archive_dir"
    resolved_label="ref explicita: $requested_ref ($resolved_commit)"
    export AI_GOVERNANCE_SOURCE_TMPDIR="$archive_dir"
  fi

  printf -v "$out_dir_var" '%s' "$resolved_dir"
  printf -v "$out_label_var" '%s' "$resolved_label"
}
