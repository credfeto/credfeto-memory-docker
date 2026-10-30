# credfeto-memory-docker

A shared, searchable memory for AI agents, kept in git, with one store per "space" and a wiki that shows all of them together.

## What's in it

All of it lives in [`memory/`](memory/), in one compose stack:

- **`basic-memory-dev`** and **`basic-memory-netadmin`**: [Basic Memory](https://github.com/basicmachines-co/basic-memory) MCP servers (streamable HTTP), one per space. Each container mounts only its own folder of the notes repo, so one space can never see another. `dev` is shared by Steward Warden and the orchestrator agents. `netadmin` is the network admin agent's own.
- **`wiki`**: [Gollum](https://github.com/gollum/gollum), a git-backed Markdown wiki over the whole notes repo. It's the human view of every space, with search and history. Edits made there are git commits, and Basic Memory picks them up.
- **`git-backup`**: a small sidecar that commits any changes and pushes them to the notes repo every few minutes (5 by default).

The notes themselves are in a separate private repo (`NOTES_REPO`). This repo holds only the stack.

## Security and Traefik

Traefik runs on separate hosts, so this stack doesn't talk to it. Each service publishes a port on the docker host (`MEMORY_DEV_PORT`, `MEMORY_NETADMIN_PORT`, `WIKI_PORT`, bound to `BIND_ADDRESS`), and Traefik's file-provider config routes to it. [`traefik/dynamic.example.yml`](traefik/dynamic.example.yml) has the routers, services and middlewares to merge into the Traefik hosts' dynamic config.

The Basic Memory HTTP endpoints have **no authentication of their own**. So:

- each space's route in Traefik has its own basic-auth users, alongside the usual internal-only allow list, so a dev credential can't reach netadmin;
- bind the published ports to an address only the Traefik hosts can reach, and firewall them to those hosts, so nothing can bypass Traefik.

## Install

1. Create the private notes repo and add a read/write deploy key for it.
2. `cp memory/.env.example memory/.env` and fill it in.
3. `./install`. It clones the notes repo, creates `dev/` and `netadmin/`, starts the stack and registers each space's folder as its `main` project.

Then add the routes from `traefik/dynamic.example.yml` to the Traefik hosts. MCP endpoints: `https://<memory host>/dev/mcp` and `/netadmin/mcp` (Basic Memory serves streamable HTTP on `/mcp`; Traefik strips the space prefix). Wiki: `https://<wiki host>/`.

## Adding a space

Copy a `basic-memory-*` service in `memory/docker-compose.yaml` and change its folder, index volume and port, and add a matching router, middlewares and service in the Traefik config. Then add the folder name to the `for space in …` loops in `install`.

## Changelog

View [changelog](CHANGELOG.md).

## Licence

[MIT](LICENSE).
