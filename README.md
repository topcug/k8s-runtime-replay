# k8s-runtime-replay

<p align="center">
  <img src="k8s-runtime-replay.png" alt="k8s-runtime-replay" width="400" />
</p>

Safe, repeatable Kubernetes runtime scenarios for detection demos, workshops, and rule validation.

This repository gives you small, well-scoped runtime behaviors that are easy to trigger, observe, and clean up — without requiring any destructive actions or production access.

**This repository validates runtime behavior generation first, and detection mappings second.**


## Who this is for

- **Platform engineers** validating detection coverage on their clusters
- **Security engineers** testing Falco rules and audit log pipelines
- **Workshop trainers** running live Kubernetes security demos
- **Falco users** verifying rule hits against real workload behavior
- **Rule authors** who need reproducible trigger conditions


## Quick start

```bash
# 1. Create a local test cluster (requires kind + Docker)
make setup-kind

# 2. Install Falco (optional — scenarios work without it)
make setup-falco

# 3. Run a scenario
make scenario-shell-spawn

# 4. Watch Falco alerts in a second terminal
make logs-falco

# 5. Clean up
make cleanup-shell-spawn
```


## Scenarios

| Scenario | Behavior | Expected signal | Cleanup |
|----------|----------|-----------------|---------|
| `shell-spawn` | Executes a shell inside a container | Shell execution in container | `make cleanup-shell-spawn` |
| `sa-token-read` | Reads the mounted service account token | Sensitive file read in container | `make cleanup-sa-token-read` |
| `kubectl-exec` | Triggers a `kubectl exec` audit event | Attach/Exec Pod audit event | `make cleanup-kubectl-exec` |
| `curl-egress` | Makes an outbound HTTP request from a container | Unexpected outbound connection | `make cleanup-curl-egress` |
| `secret-enumeration` | Lists Kubernetes Secrets from inside a container | K8s API contact from container | `make cleanup-secret-enumeration` |

> **Note:** Expected signal names describe the *behavior*, not an exact detection rule name. Rule names vary by tool, ruleset version, and configuration. See each scenario's `README.md` for known variants.

```bash
# See all scenarios
make list-scenarios
```


## Safe by design

- **No destructive actions** — scenarios never delete, modify, or exfiltrate real data.
- **Isolated namespace** — all workloads run in a dedicated `k8s-replay` namespace.
- **Full cleanup** — every scenario has a cleanup target that removes all resources.
- **Production guard** — scripts refuse to run if the current context looks like a production cluster.
- **Safety banner** — every trigger script prints a clear notice before doing anything.
- **Test clusters only** — these scenarios are designed for kind, minikube, or dedicated test clusters.


## Understanding scenario results

Each scenario reports execution and detection as **separate statuses**:

```
Environment checks     PASS
Scenario deploy        PASS
Scenario trigger       PASS
Detection backend      Falco
Detection verification FAIL  (see below for likely causes)
```

If Falco is not installed:

```
Environment checks     PASS
Scenario deploy        PASS
Scenario trigger       PASS
Detection backend      NOT INSTALLED
Detection verification SKIPPED
```

A scenario is considered **successful** when the behavior is triggered and observable — regardless of detection outcome. Detection verification is a second layer, and depends on your installed ruleset and version.


## All make targets

```bash
make help                       # show all targets

# Setup
make setup-kind                 # create a local kind cluster
make setup-falco                # install Falco via Helm

# Scenarios
make scenario-shell-spawn
make scenario-sa-token-read
make scenario-kubectl-exec
make scenario-curl-egress
make scenario-secret-enumeration

# Cleanup
make cleanup-<scenario>         # remove a specific scenario
make cleanup                    # delete the k8s-replay namespace
make reset                      # full teardown including kind cluster

# Utilities
make list-scenarios             # list available scenarios
make logs-falco                 # filtered Falco alert log view
make logs-falco-raw             # raw recent Falco logs (useful for format debugging)
make list-rules                 # attempt to infer loaded Falco rule names (best-effort)
```


## Scenario structure

Every scenario follows the same layout:

```
scenarios/<name>/
  README.md              — goal, what gets deployed, what is triggered,
                           expected behavior, detection notes, known rule-name variants,
                           cleanup, safety notes
  manifests/             — Kubernetes YAML (namespace, workload, RBAC)
  trigger.sh             — deploys and triggers the behavior
  cleanup.sh             — removes all scenario resources
```


## Optional: Test with Falco

Falco is not required — scenarios run and are observable via `kubectl` and audit logs without it. But if you want to validate runtime rule hits:

```bash
make setup-falco
make scenario-shell-spawn

# In a second terminal
make logs-falco

# If no alerts appear, check raw logs for format issues
make logs-falco-raw
```

> Detection rule names depend on your installed Falco ruleset and version. Each scenario's README lists known rule-name variants to help you map behavior to your local rules.

See [docs/falco-setup.md](docs/falco-setup.md) for full Falco setup instructions.


## Documentation

- [docs/local-cluster.md](docs/local-cluster.md) — setting up a local kind cluster
- [docs/falco-setup.md](docs/falco-setup.md) — installing and verifying Falco
- [docs/workshop-mode.md](docs/workshop-mode.md) — running as a structured workshop


## Roadmap

- [x] v0.1 — 5 core scenarios (shell-spawn, sa-token-read, kubectl-exec, curl-egress, secret-enumeration)
- [ ] v0.2 — `privileged-start` scenario
- [ ] v0.3 — `verify.sh` per scenario (automated signal verification)
- [ ] v0.4 — asciinema recordings per scenario
- [ ] v1.0 — Falco rule mapping table, MITRE ATT&CK annotation


## License

Apache 2.0 — see [LICENSE](LICENSE)
