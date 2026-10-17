---
name: deploy-changes
description: "Deploy published repo changes to Docker guests through their confirmed Proxmox owners using dupull. Use when explicitly asked to deploy a stack such as caddy, roll out changes to LXCs or VMs, or run dupull remotely."
argument-hint: "Stack directory to deploy, for example caddy"
user-invocable: true
disable-model-invocation: true
---

# Deploy Changes

Invoke `/deploy-changes caddy` to request deployment planning and execution
for Caddy. An explicit natural-language deployment request can also select
this workflow. Creating this skill, editing code, running local tests, or
refreshing the deployment map does not authorize a deployment.

## Scope and Approval

- Read `.github/copilot-instructions.md`, `deployments.yaml`, and the relevant
  stack definitions. Confirm the local hostname/account and working directory.
  The local checkout is not a deployment target; never run `dupull` here.
- Explain the affected guests and the operations before mutation. A request
  to deploy a named stack authorizes necessary target discovery and SSH for
  that task, using existing access. Ask when targets or access scope are
  ambiguous. Obey tool approval prompts; never alter approval settings,
  credentials, host-key verification, permissions, or trust relationships.
- `dupull` is not stack-scoped. The current `.common/functions.sh` runs
  `upgrade` followed by `dpull`. The `upgrade` alias in `.common/aliases.sh`
  updates APT, performs a distribution package upgrade, cleans the cache,
  and autoremoves packages with purge. `dpull` pulls Git, then pulls images,
  rebuilds without cache, and runs Compose up with orphan removal for every
  top-level Compose stack present in the guest checkout.
- Before running `dupull`, explicitly obtain approval for its OS package
  upgrades, package removal, image/build changes, and guest-wide Compose
  recreation/orphan removal. A generic request to deploy a config edit is
  not permission for undisclosed package removal or unrelated workloads.
  If that broader scope is not approved, stop and propose a narrower workflow;
  do not silently substitute it or change the helper.
- Do not commit, push, transfer files, change sparse-checkout rules, install
  tooling, start stopped guests, run bootstrap, reboot, or change networking
  as implicit deployment prerequisites. Ask for each needed scope expansion.
- Execute guests sequentially. Stop rollout on failure and report completed,
  failed, and skipped targets; do not silently roll back or retry mutations.

## Resolve Targets and Preflight

1. Resolve changed stack paths through `docker_guests`, using hostname matches
   and the documented exceptions. Caddy requires ALL three LXCs: 203 and 205
   were on Cerulean, and 204 on Kex. Recheck live ownership and guest state
   through approved cluster discovery before using those observations.
   Confirm each owner, guest ID/type, and in-guest hostname; `pct` is for LXCs,
   never VMs. Do not start stopped guests; report skipped deployments.
2. NVIDIA VM 101 hosts the `immich` and `plex-video` repo directories. Tautulli
   is a service inside the Plex Compose definitions on VM 101 and LXCs 108
   and 120, not a separate required sparse-checkout stack. Inspect actual
   Compose references before inferring additional repo paths.
3. Inspect local changes and relevant tests. Identify the intended published
   commit and branch. `dupull` cannot deploy local uncommitted or unpushed
   edits. If publishing is needed, report the blocker and ask before Git
   commits or pushes. Do not imply that Git pull transfers local edits.
4. Confirm the guest checkout location, repository identity, branch/upstream,
   current revision, clean tracked/untracked worktree, sparse paths, and the
   upstream revision that Git pull would retrieve. Inspect relevant ownership
   first, applying only the standing scoped repair approval in
   `.github/copilot-instructions.md` when needed, and run Git as `dante`.
   Do not probe Git as root or add `safe.directory` exceptions. `/docker` is
   expected, but verify it before use. Preserve remote changes; do not reset, stash,
   clean, force-pull, or bypass Git ownership checks. Do not print credentials
   or environment files. Stop on divergence or unrelated upstream changes
   unless their inclusion is explicitly approved. Record the predeploy SHA.
5. Review the deployed helper and alias definitions before running them; they
   may differ from this checkout. Confirm the expected top-level workloads
   and disclose that all of them will be affected. Nested Gluetun Compose
   stacks are not traversed by the current `dpull` loop. If deploying nested
   changes, stop and agree on a separate targeted rollout; `dupull` alone
   does not prove those services were updated.
6. Determine service validation commands from the actual Compose runtime and
   mounted configuration. For Caddy, plan config validation in its actual
   image/context and checks of its deployed routes. A check against old
   deployed files is not validation of unpublished local changes.

## Execute Through the Correct Owner

Use noninteractive SSH with existing aliases, bounded connection timeouts,
and strict host-key checking. Reconfirm the owner identity on each connection.
For an LXC, run `pct exec <id> --keep-env 0 -- ...` on that owner. Do not use
interactive `pct enter`, and do not substitute a local or host command if
guest access fails. For a VM, use approved configured SSH access or an available
QEMU guest agent, not `pct`.

Run the repository shell inside the guest as `dante`, using
`pct exec <id> --keep-env 0 -- runuser -u dante -- /bin/bash --noprofile --norc`
for LXCs. For VMs, prefer an existing trusted `dante` SSH alias. Do not switch
execution methods to bypass failed SSH host-key verification. Root is for
approved administrative actions, not Git; do not run the helper body as root.

`dupull` is a Bash function. Do not assume a noninteractive shell reads the
interactive `.bashrc`, which returns early without a prompt. After reviewing
the deployed files, the guest-side command body is:

```bash
set -e
test "$(id -un)" = dante
cd /docker
shopt -s expand_aliases
source /docker/.common/aliases.sh
source /docker/.common/functions.sh
declare -F dupull >/dev/null
dupull
```

Execute this body in noninteractive Bash inside the selected guest, with no
interactive startup files. Enable alias expansion BEFORE sourcing functions
because `upgrade` is an alias expanded when `dupull` is defined. Use safe
argument passing/quoting across SSH, the owner shell, and `pct exec`; do not
interpolate untrusted discovery output into shell commands. Never source the
helpers or run this command body in the local checkout or on the PVE host.

Keep output bounded, but do not pipe interactive prompts through filters. If
elevated access is required but not already approved, stop. Secrets must be
entered directly by the user, never requested through chat or tools.

Do not write logs, staging files, or scratch folders on Proxmox nodes or in
guests; read remote output through the command result, bounded with `tail`
or `grep`. Any log that must be kept locally goes under
`/tmp/lxc-deploy-logs/` in this WSL2 instance; it is tmpfs and cleared on
boot, so it needs no cleanup. Do not use other local log locations. Local
logs are only a convenience: judge success from server-side evidence such
as guest Git HEAD, Compose state, container logs, and service checks.

## Verify and Report

1. Check the command result and bounded output from EACH phase. The existing
   `dupull` wrapper and `upgrade` alias do not guarantee an earlier upgrade
   failure propagates as the final exit status; do not infer complete success
   solely from a zero exit code. Do not fix helper semantics as an unrequested
   deployment side effect. Stop rollout if any phase failed.
2. Verify guest HEAD matches the intended published revision; account for a
   branch advancing during rollout. Inspect Compose service state and health
   without dumping environment values or resolved secret-bearing configs.
   Validate the newly deployed config and relevant endpoints; do not call a
   running container proof that config validation or route checks passed.
3. For Caddy, complete those checks for every target, one guest at a time.
   Prefer verified secondary instances before a verified primary when that
   rollout order is available. Do not claim full success if a target was
   stopped, unreachable, failed, or skipped.
4. Report guest ID, owner, before/after revision, helper result, validation
   result, and any failures or skipped targets. Record important observations
   in the repo only as authorized; keep secrets and runtime status out of
   `deployments.yaml`. Do not promise automatic rollback of package upgrades
   or mutable image tags, and never reboot as part of this skill.
