---
name: deploy
description: "Deploy published repo changes to Docker guests through their confirmed Proxmox owners: stop each guest's stacks with dcd -v, run dpull, then validate startup and app IP/port accessibility, including Caddy reverse-proxy checks. AdGuard Home and Caddy roll out staggered. Use when explicitly asked to deploy all pending changes, the guests edited in the current thread, every guest, or named stacks/guest IDs."
argument-hint: "Optional: all, stack names, or guest IDs, for example caddy or 100 200"
user-invocable: true
disable-model-invocation: true
---

# Deploy

Invoke `/deploy` to request deployment planning and execution. An explicit
natural-language deployment request can also select this workflow. Creating
this skill, editing code, running local tests, or refreshing the deployment
map does not authorize a deployment.

For a metadata-only update of local `deployments.yaml`, use
`/refresh-deployments` instead. Deployment still requires current ownership,
state, and role discovery; follow the refresh workflow when updating the map,
without treating that refresh as permission to deploy additional guests.

## Choose Targets

- `/deploy` in a new thread, with no earlier edits, deployments, or named
  guests in the conversation: deploy all pending changes. Fetch published
  `main`, then for each running Docker guest compare its `/docker` HEAD with
  `origin/main` and select it when files in its sparse paths changed. Changes
  to shared paths such as `.common/` or `bootstrap.sh` select every guest.
  Report guests already at `origin/main` as up to date and skip them.
- `/deploy` in an existing thread: target only the guests whose stacks or
  guest IDs were edited, deployed, or explicitly named earlier in that
  thread. Show the derived list with the reason for each guest and get
  confirmation before running.
- `/deploy all`: every running Docker guest in `docker_guests`, whether or not
  it has pending changes.
- `/deploy <stacks or guest IDs>`: exactly what is named. A stack resolves to
  every guest that runs it; a guest ID selects only that guest.
- In every mode, list the targets, the rollout order, and the guest-wide
  scope, obtain the approvals below, and deploy only published commits.
- "Each container" follows the same scoping: all targets for a new-thread
  `/deploy`, only the relevant guests within an existing thread.

## Scope and Approval

- Read `.github/copilot-instructions.md`, `deployments.yaml`, and the relevant
  stack definitions. Confirm the local hostname/account and working directory.
  The local checkout is not a deployment target; never run `dpull` here.
- Explain the affected guests and the operations before mutation. A request
  to deploy a named stack authorizes necessary target discovery and SSH for
  that task, using existing access. Ask when targets or access scope are
  ambiguous. Obey tool approval prompts; never alter approval settings,
  credentials, host-key verification, permissions, or trust relationships.
- Per guest, first complete Bootstrap Changes below when applicable, then
  stop every top-level stack with `dcd -v`
  (`dcd` is the `docker compose down` alias in `.common/aliases.sh`), run
  `dpull` from `.common/functions.sh`, then validate startup. Stopping first
  forces a clean recreate, so validation proves the stacks start from the
  new definitions rather than surviving as old containers.
- Use `dpull`, not `dupull`. `dupull` only adds the `upgrade` alias (APT
  dist-upgrade, cache clean, `autoremove --purge`), which is unrelated to
  deploying repo changes. Run `upgrade`/`dupull` only when the user
  explicitly asks for OS upgrades, with separate approval for package
  upgrades and removal.
- Neither step is stack-scoped. Both cover every top-level stack in the
  guest checkout (`/docker/*/compose.y*ml`), including `include:` children
  such as `gluetun/qbittorrent` and `gluetun/soulseek`. `dpull` runs plain
  `git pull`, then per stack `docker compose pull --ignore-buildable`,
  `build --pull --no-cache`, and `up --build -d --remove-orphans`, returning
  on the first failure.
- Before running, explicitly obtain approval for guest-wide downtime, the
  volume removal below, image/build changes, and orphan removal. A generic
  request to deploy a config edit is not permission for unrelated workloads
  beyond this disclosed scope. If it is not approved, stop and propose a
  narrower workflow; do not silently substitute it or change the helpers.
- Do not commit, push, transfer files, change sparse-checkout rules, install
  tooling, start stopped guests, reboot, or change networking as implicit
  deployment prerequisites. Required bootstrap has the standing authorization
  below; ask for every other needed scope expansion.
- Execute deployment mutations sequentially. Stop rollout on failure and
  report completed, failed, and skipped targets; do not silently roll back
  or retry mutations.
- Run independent read-only discovery, preflight, and service checks
  concurrently in bounded batches to reduce elapsed time. Keep each result
  associated with its guest and owner. Within a guest's validation window,
  run independent checks concurrently, but preserve the full settling window
  and before/after snapshots. Finish validation before mutating the next
  guest; concurrency never bypasses networking waves or failure gates.

## Publish Local Changes

- Check for both uncommitted changes and commits ahead of the upstream
  before selecting the intended deployment revision. Fetch published
  `main` and confirm the branch, upstream, and fast-forward relationship.
- Include publishing in deployment planning: do not leave local changes
  silently undeployed. Explain the pending diff and request approval to
  commit and push when the request has not already authorized those actions.
  A push request authorizes pushing existing commits, not committing edits.
- After approval, validate the reviewed changes, stage only approved paths,
  commit if needed, and push the current branch without force. Preserve
  unrelated edits and disclose existing unpushed commits. Do not create a
  branch or resolve divergence implicitly. Confirm the published SHA before
  guest deployment; `dpull` cannot deploy an unpublished local change.
- Publishing approval does not authorize guest downtime, bootstrap, OS
  upgrades, credential provisioning, or any other deployment prerequisite.

## Bootstrap Changes

For each selected guest, compare its recorded predeploy revision with the
intended published revision. If that incoming diff includes `bootstrap.sh`,
run the guest's `bootstrap` alias before `dcd -v`, `dpull`, or any other
deployment mutation. Read-only preflight and required approvals come first.
An unpublished local bootstrap edit is a publishing blocker, not permission
to run an older deployed script. Do not expand the selected guest scope.

1. Inspect the deployed alias and the incoming published script before
   execution. The current alias pulls Git as `dante`, then sources
   `/docker/bootstrap.sh` in the invoking shell. Its `git pull || true`
   masks pull failures: explicitly fast-forward as `dante` and verify the
   intended revision before invoking the alias; check HEAD again afterward.
   Preserve the old Compose definitions and active-project snapshot before
   this pull. If changed definitions cannot safely tear down the old projects,
   stop and agree on a targeted teardown rather than silently missing them.
2. The user has given standing approval to run required bootstrap on selected
  deployment guests without reconfirmation. Report which guests require it
  and inspect the incoming script first. This approval covers the script's
  Ubuntu release upgrade, package installation, possible Docker restart,
  ownership/permission/group/sudo changes, and SSH key/authentication/trust
  changes. These actions outside `bootstrap.sh` still need their own approval.
  Do not suppress bootstrap failures or silently skip phases. Never reboot
  implicitly, run bootstrap locally or on a Proxmox owner, or bypass failed
  SSH verification to reach a guest.
3. The current alias uses `runuser`, requiring a guest administrative shell;
  the standing bootstrap approval includes that shell through the existing
  approved access method, not new remote access or trust configuration.
  It cannot simply be invoked as unprivileged `dante`. Inspect
   and load the deployed alias explicitly in noninteractive Bash, enabling
   alias expansion before parsing its invocation (for example, invoke the
   reviewed alias using `eval 'bootstrap'` after sourcing its definition).
   Do not substitute `bash bootstrap.sh`: the alias sources the script.
4. Check output from every bootstrap phase, not only its final status;
   neither the alias nor script guarantees all earlier failures propagate.
   Stop on failure before teardown. Open a fresh `dante` session afterward,
   recheck repository identity, revision, helper definitions, Docker access,
   and service availability, then proceed with `dcd -v` and `dpull`.

For AdGuard Home and Caddy, bootstrap belongs to that guest's rollout wave,
not a fleet-wide preliminary pass: validate the secondary completely before
bootstrapping another instance or a primary. Bootstrap itself may interrupt
Docker, so confirm the serving peer before bootstrap as well as before down.

## Volume Removal (`dcd -v`)

`docker compose down -v` removes the stack's non-external named volumes and
anonymous volumes (image `VOLUME` paths not covered by a mount). Bind mounts
and `external: true` volumes are untouched. Removing a local-driver NFS
volume only unmounts it and deletes Docker's definition; server data stays.
A static audit of the published stacks on 2026-10-16 found `-v` safe for all:

| Stack                             | Removed by `-v`                                                                                                       | Effect                                                                                            |
| --------------------------------- | --------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------- |
| adguardhome                       | nothing; state and configs are bind mounts                                                                            | none                                                                                              |
| caddy                             | anonymous `/config` and `/data` outside the `./data` bind at `/data/caddy`                                            | autosave regenerates from the Caddyfile; certificates and ACME accounts persist in `./data`       |
| gluetun (+ qbittorrent, soulseek) | `qbittorrent_nfs`, `soulseek_nfs` definitions; qBittorrent anonymous `/config` outside the `/config/qBittorrent` bind | NFS data persists; qBittorrent loses only `$HOME/.cache`                                          |
| immich                            | NFS volume definitions                                                                                                | NFS data persists; Postgres and Redis `/data` are bind mounts; Redis uses append-only persistence |
| plex-music, plex-video            | NFS volume definitions                                                                                                | NFS data persists; Plex and Tautulli config are bind mounts                                       |
| pocket-id, spoolman               | nothing; data is a bind mount                                                                                         | none                                                                                              |
| common-dockge-agent (undeployed)  | nothing; its volume is external                                                                                       | none                                                                                              |

For a deployment that introduces the Redis or AudioMuse plugin bind mounts,
first inspect the existing mounts through approved read-only guest access.
Preserve and migrate existing data before any `down -v`; an empty new bind
does not recover old anonymous-volume data. Migration needs explicit approval.
For Dawarich, also verify the existing Photon index layout and compatibility;
automatic index downloads and updates are disabled. See the README storage audit.

Re-audit statically before deploying
when the published diff adds a stack or changes `volumes:`, mount targets,
or images. A new non-external named volume, or an unmounted image `VOLUME`,
holding data that cannot be regenerated is a blocker: stop and report.

## Networking Rollout Order (AdGuard Home and Caddy)

AdGuard Home (200, 201, 202 at last refresh) and Caddy (203, 204, 205) run
duplicate instances behind keepalived. Never let a deployment take every
instance of a type down at once. This applies in every target mode,
including threads scoped only to AdGuard Home or Caddy.

1. Classify each instance as primary or secondary (secondary, tertiary,
   and so on) by its PVE role tags in `deployments.yaml`, rechecked live.
   If duplicate instances lack distinguishing role tags, ask which is
   primary rather than guessing from IDs or nodes.
2. Count running instances per type. Skip stopped ones; never start them.
   If fewer than two are running for an affected type, do not deploy that
   type; report and ask.
3. Wave 1 (canary): one running secondary per affected type, that is one
   AdGuard Home and one Caddy. If the primary is down, any running instance
   may be the canary as long as another remains running. Before stopping a
   canary, confirm another instance of that type is running and serving.
4. Validate each canary fully (see Verify). On failure, stop the rollout of
   all remaining networking guests and report; leave the others untouched.
5. Wave 2: remaining secondaries, one at a time, each validated.
6. Wave 3: primaries last, one at a time, each validated.

Non-networking guests may share the batch in any position, but primaries
start only after every targeted secondary has passed validation.

Before stopping a networking guest, confirm its own resolver
(`/etc/resolv.conf`) does not depend on its local AdGuard Home: `dpull`
needs DNS for Git and image pulls after the stacks are down. Disclose that
Caddy's outage includes a `--no-cache` rebuild that downloads Caddy from
caddyserver.com while the guest's Caddy is stopped.

## Resolve Targets and Preflight

1. Resolve changed stack paths through `docker_guests`, using hostname matches
   and the documented exceptions. Caddy and AdGuard Home each resolve to all
   three of their LXCs; order them per Networking Rollout Order. Recheck
   live ownership, state, and tags through approved cluster discovery
   before using recorded observations.
   Confirm each owner, guest ID/type, and in-guest hostname; `pct` is for LXCs,
   never VMs. Do not start stopped guests; report skipped deployments.
2. NVIDIA VM 101 hosts the `immich` and `plex-video` repo directories. Tautulli
   is a service inside the Plex Compose definitions on VM 101 and LXCs 108
   and 120, not a separate required sparse-checkout stack. Inspect actual
   Compose references before inferring additional repo paths.
3. Inspect local changes and relevant tests. Identify the intended published
   commit and branch. `dpull` cannot deploy local uncommitted or unpushed
  edits. Complete Publish Local Changes using the applicable approvals
  before deployment. Do not imply that Git pull transfers local edits.
4. Confirm the guest checkout location, repository identity, branch/upstream,
  current revision, tracked worktree, untracked files, sparse paths, and the
   upstream revision that Git pull would retrieve. Inspect relevant ownership
   first, applying only the standing scoped repair approval in
   `.github/copilot-instructions.md` when needed, and run Git as `dante`.
   Do not probe Git as root or add `safe.directory` exceptions. `/docker` is
  expected, but verify it before use. Report untracked files and preserve them
  during upgrades; they do not block deployment unless they collide with
  incoming paths or prevent safe operation. Leave cleanup for manual review
  or a follow-up request. Preserve tracked remote changes; do not reset, stash,
  clean, force-pull, or bypass Git ownership checks. Do not print credentials
   or environment files. Stop on divergence or unrelated upstream changes
   unless their inclusion is explicitly approved. `dpull` uses plain
   `git pull`, so confirm after `git fetch` that it would fast-forward.
   Record the predeploy SHA.
5. Review the deployed `dcd` alias and `dpull` definition before running
   them; they may differ from this checkout. If they no longer match the
   behavior described here, stop and report. Confirm the expected top-level
   workloads and disclose that all of them will be stopped and recreated.
6. Confirm `dante` can reach the Docker daemon, then snapshot each running
   container's name, state, health, and restart count, plus the active
   Compose projects. Stacks remain down if a later step fails, so this
   snapshot is the reference for both validation and failure reports.
   On both LXCs and Docker VMs (including `nvidia-vm`/101), run Git,
   `docker`, Compose, and deployment helpers as `dante` without `sudo`.
   Historical sudo requirements are not current requirements: verify using
   a read-only `docker info` in that user's fresh session. If access fails,
   stop and report; do not retry as root, add sudo, or change groups/socket
   permissions. Bootstrap administration is the separate exception above.
7. Determine service validation commands from the actual Compose runtime and
  mounted configuration. Inventory each app's actual IP, exposed port,
  protocol, and webpage/API/health path across every stack that will be
  recreated, including nested stacks. Resolve published host ports versus
  container ports, host/shared networking, and configured bind addresses;
  never use a wildcard bind address as a destination or assume default
  ports. Use current guest addresses, not stale map entries. Do not print
  secrets or entire resolved Compose configurations. Record which endpoints
  are intentionally internal-only and choose an appropriate in-guest probe
  for those rather than exposing them. For Caddy, plan config validation in
  its actual image/context and the reverse-proxy checks below. A check
  against old deployed files is not validation of unpublished local changes.

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
approved administrative actions, not Git; do not run the Docker helper body
as root. This applies to every Docker VM, not only VM 101. An approved root
guest session may select `dante` via `runuser`; it must not execute Docker
or Git as root. Never infer a need for sudo from the guest being a VM.

`dpull` is a Bash function and `dcd` is an alias. Do not assume a
noninteractive shell reads the interactive `.bashrc`, which returns early
without a prompt, or expands aliases. After reviewing the deployed files
and completing any required Bootstrap Changes phase, the guest-side command
body below applies when the checked-out definitions can tear down the old
projects safely:

```bash
set -e
test "$(id -un)" = dante
cd /docker
source /docker/.common/functions.sh
declare -F dpull >/dev/null
# dcd -v in every stack dpull will bring up, using the pre-pull definitions
for app_dir in /docker/*/; do
	[ -f "${app_dir}compose.yaml" ] || [ -f "${app_dir}compose.yml" ] || continue
	echo "== down: ${app_dir}"
	(cd "$app_dir" && docker compose down -v)
done
dpull
```

Execute this body in noninteractive Bash inside the selected guest, with no
interactive startup files. The loop mirrors `dpull`'s stack discovery and
runs before its `git pull` in the normal path, so containers stop using the
definitions that created them. The bootstrap path has already pulled;
use the teardown plan established before that pull instead if necessary.
It spells out the `dcd` alias definition because aliases are
not expanded noninteractively; confirm the deployed alias matches. Use safe
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

1. Check the exit status and bounded output from each phase. The body
   exits on the first failed down, Git pull, image pull, build, or up. A
   failure leaves that stack and every later stack down: report exactly
   which stacks are down against the snapshot and stop the rollout. Do not
   retry, roll back, or fix helper semantics without approval.
2. Verify guest HEAD matches the intended published revision; account for a
   branch advancing during rollout.
3. Validate startup for every stack in the guest, not only changed ones:
   - Every container in the predeploy snapshot is running again, and
     healthchecked services report `healthy`, and each was created after
     the deploy started. Account for profiles such as `adguardhome-sync`:
     a profiled container not recreated was skipped by down/up. Flag any
     container missing, stale, or newly present.
   - Observe a settling window of at least 60 seconds, longer than the
     largest healthcheck `start_period` involved (Gluetun's is 2 minutes).
     Compare state and restart counts at its start and end; any increase,
     `restarting`, `exited`, or `unhealthy` is a failure.
   - Review logs since the deploy start, bounded per stack, for example
     `docker compose logs --since <start> --no-color --tail 200`, scanning
     for errors, panics, permission denials, mount failures, and crash
     loops. Distinguish benign startup noise; do not dump environment
     values or resolved secret-bearing configs.
   - Run service checks after the settling window, since probes can race
     startup. For every recreated app, probe its discovered IP and exposed
     port from an approved client vantage point, not only localhost inside
     its container. For HTTP(S), request an actual webpage/API/health path
     and verify the expected status and application-specific response; a
     listening socket, redirect alone, unrelated default page, or proxy
     error is not sufficient. Follow expected redirects with bounded hops
     and verify the final destination; note when a direct URL redirects to
     a proxy rather than independently proving the backend works. Treat an
     authentication response as expected only when confirmed for that app;
     never read credentials or log in implicitly. Use protocol-appropriate
     read-only checks for non-HTTP services, including AdGuard Home DNS
     queries against that guest's address and keepalived state in its logs.
     Internal-only dependencies use the planned in-guest checks.
   - For Caddy, run `caddy validate` in its container and check the
     reverse-proxied `https://pve.samskeyti.net` webpage/API through normal
     DNS. Also use `curl --resolve pve.samskeyti.net:443:<guest-ip>` against
     each deployed Caddy guest individually, preserving the hostname/SNI
     and TLS certificate verification. Normal DNS or a shared VIP alone
     cannot prove the recreated instance serves the route. Verify the
     expected Proxmox response, not merely that DNS resolves or TLS connects;
     502/503/504 responses fail validation. This representative route replaces
     a sweep of every Caddy URL, but also check routes specifically changed
     by the deployment. These proxy checks supplement, not replace, direct
     app IP/port checks.
   - Use bounded connection/request timeouts and certificate verification;
     never bypass TLS or access controls to make a probe pass. Record the
     endpoint, probe vantage point, expected/observed result, and any blocked
     or untestable checks without credentials or sensitive response bodies.
     Missing tools, network reachability, or authorization are validation
     gaps, not passes; stop and report rather than installing tools, changing
     networking, or expanding remote access without approval. A running
     container is not proof of application accessibility.
4. AdGuard Home and Caddy follow Networking Rollout Order; a guest's
   validation must pass before the next wave begins. Do not claim full
   success if a target was stopped, unreachable, failed, or skipped.
5. Report guest ID, owner, role tag, before/after revision, helper result,
  validation result, direct IP/port and Caddy proxy probe results, and any
  failures, validation gaps, or skipped targets. Record important
   observations in the repo only as authorized; keep secrets and runtime
   status out of `deployments.yaml`. Do not promise automatic rollback of
   mutable image tags, and never reboot as part of this skill.
