# credfeto-memory-docker

A shared, searchable memory for AI agents, kept in git, with one store per "space" and a wiki that shows all of them together.

## What's in it

All of it lives in [`memory/`](memory/), in one compose stack:

- **`basic-memory-dev`** and **`basic-memory-netadmin`**: [Basic Memory](https://github.com/basicmachines-co/basic-memory) MCP servers (streamable HTTP), one per space. Each container mounts only its own folder of the notes repo, so one space can never see another. `dev` is shared by Steward Warden and the orchestrator agents. `netadmin` is the network admin agent's own.
- **`wiki`**: [Gollum](https://github.com/gollum/gollum), a git-backed Markdown wiki over the whole notes repo. It's the human view of every space, with search and history. Edits made there are git commits, and Basic Memory picks them up.
- **`git-backup`**: a small sidecar that commits any changes and pushes them to the notes repo every few minutes (5 by default).

The notes themselves are in a separate private repo (`NOTES_REPO`). This repo holds only the stack.

## Security and Traefik

Traefik runs on separate hosts, so this stack doesn't talk to it. Each service listens on its own port on the docker host (`MEMORY_DEV_PORT`, `MEMORY_NETADMIN_PORT`, `WIKI_PORT`) using host networking, and Traefik's file-provider config routes to it. [`traefik/dynamic.example.yml`](traefik/dynamic.example.yml) has the routers, services and middlewares to merge into the Traefik hosts' dynamic config.

The Basic Memory HTTP endpoints have **no authentication of their own**. So:

- each space's route in Traefik checks its own **bearer token** (`Authorization: Bearer <token>`, via the `traefik-api-token-middleware` plugin), alongside the usual internal-only allow list, so a dev token can't reach netadmin. The wiki uses basic auth, since a browser can't send a bearer token;
- `./install` adds firewalld rich rules so **only `TRAEFIK_HOSTS`** can connect to the service ports, so nothing can bypass Traefik.

Why host networking: ports published with `ports:` go through Docker's own nftables chains and firewalld's `docker-forwarding` policy, so firewalld zone rules don't apply to them and anyone on the network could reach the unauthenticated endpoints. With host networking they're ordinary inbound connections that the firewalld rules control. Check it from a host that isn't a Traefik host: `curl -m 5 http://<docker host>:8101/mcp` must time out.

## Host firewall

`./install` also runs `firewall/configure`, which locks down what the host may connect to, the same way as the key, DNS and monitoring servers. Ingress stays as above: the stack publishes no Docker ports, so the firewalld rules for `TRAEFIK_HOSTS` cover the service ports.

| Filter                               | Traffic                                      | Allowed                                                                                                                                                                                                                  |
|--------------------------------------|----------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `host_out` (nftables `mem_egress`)   | host, Basic Memory and the wiki -> anywhere  | DNS to the fleet's DNS servers, NTP to the router, HTTPS to the proxies (docker-cache, pacman, monitoring), journald uploads and syslog to monitoring, GitHub, ghcr.io, Docker Hub, Cloudflare, pkgstats, the Arch WKD, ICMP |
| `docker_fwd` (nftables `mem_egress`) | git-backup -> outside world                  | DNS, GitHub over SSH                                                                                                                                                                                                     |

Basic Memory and the wiki use host networking, so their outbound traffic is the host's. The table is replaced in a single `nft -f` transaction, so a refresh never makes firewalld reload, and a ruleset that fails to load leaves the previous one in place.

Two timers keep it current:

* `mem-egress-refresh.timer` (30 seconds after boot, then every 10 minutes) rebuilds the address sets for destinations without a stable address: names resolved from DNS (each address stays allowed for 7 days after it was last seen), plus GitHub's and Cloudflare's published ranges (`firewall/github-egress-ranges` and `firewall/cloudflare-egress-ranges`). It only loads the table when it differs from the loaded one.
* `mem-firewall-sync.timer` (every 15 minutes) pulls the checkout and re-runs `firewall/configure` when anything under `firewall/` changed since the commit it last applied. Container and compose changes still wait for `./install`.

The `Repo: Update egress ranges` workflow regenerates the two range files daily and commits any change to main, refusing a list that has shrunk by more than a fifth.

`MEMORY_FIREWALL_ENFORCE` in `memory/.env` is the only switch. Unset or anything other than `true` is observation mode: every rule is in place, but traffic that matches none of them still flows and is logged with the prefix `mem-egress-unmatched:` or `mem-egress-docker-unmatched:` (rate-limited to 30 a minute). Run in observation mode first and check the journal for anything legitimate that is not covered:

```sh
sudo journalctl -k --since -1d | grep -E 'mem-egress-[a-z-]*unmatched'
```

then set `MEMORY_FIREWALL_ENFORCE=true` and run `sudo firewall/configure` (or `./install`). Straight after enforcing, check that the MCP endpoints still answer through Traefik and that git-backup still pushes (`docker logs memory-git-backup`). To see the live rules:

```sh
sudo nft list table inet mem_egress
```

## Install

1. Create the private notes repo and add a read/write deploy key for it.
2. `cp memory/.env.example memory/.env` and fill it in.
3. `./install` (as root; needs firewalld running, as on a credfeto-setup-arch-vm host). It opens the service ports to `TRAEFIK_HOSTS` only, clones the notes repo, creates `dev/` and `netadmin/`, starts the stack and registers each space's folder as its `main` project.

Then add the routes from `traefik/dynamic.example.yml` to the Traefik hosts. MCP endpoints: `https://<memory host>/dev/mcp` and `/netadmin/mcp` (Basic Memory serves streamable HTTP on `/mcp`; Traefik strips the space prefix). Wiki: `https://<wiki host>/`.

## Adding a space

Copy a `basic-memory-*` service in `memory/docker-compose.yaml` and change its folder, index volume and port, and add a matching router, middlewares and service in the Traefik config. Then add the folder name to the `for space in …` loops in `install`.

## Changelog

View [changelog](CHANGELOG.md).

## Licence

[MIT](LICENSE).
