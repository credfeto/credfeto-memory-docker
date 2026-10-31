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
