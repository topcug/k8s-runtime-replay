#!/usr/bin/env bash
# lib/checks.sh — pre-flight checks for k8s-runtime-replay

set -euo pipefail
# shellcheck source=common.sh
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# Check that we are NOT on a production-looking cluster
check_not_production() {
  local ctx
  ctx="$(kubectl config current-context 2>/dev/null || echo '')"

  local prod_patterns=("prod" "production" "prd" "live" "staging-prod")
  for pattern in "${prod_patterns[@]}"; do
    if echo "$ctx" | grep -qi "$pattern"; then
      error "Current context looks like a production cluster: $ctx"
      error "k8s-runtime-replay is designed for test clusters only."
      error "Override this check by setting REPLAY_ALLOW_ANY_CLUSTER=true (not recommended)."
      if [[ "${REPLAY_ALLOW_ANY_CLUSTER:-false}" != "true" ]]; then
        exit 1
      fi
      warn "REPLAY_ALLOW_ANY_CLUSTER=true — proceeding anyway."
    fi
  done

  info "Current context: $ctx (looks safe)"
}

# Check optional Falco availability
check_falco() {
  if kubectl get pods -n falco --selector=app.kubernetes.io/name=falco \
       --field-selector=status.phase=Running -o name 2>/dev/null | grep -q pod; then
    success "Falco is running — expected rule hits will be visible in Falco logs"
    return 0
  else
    warn "Falco not detected — scenario will still run, but no runtime alerts will fire"
    warn "See docs/falco-setup.md to install Falco"
    return 0
  fi
}

# Check kind availability (optional local cluster)
check_kind() {
  if command -v kind &>/dev/null; then
    success "kind is available"
  else
    warn "kind not found — install it for local cluster setup: https://kind.sigs.k8s.io"
  fi
}
