# credfeto-memory-docker

A shared, searchable memory for AI agents, kept in git, with one store per "space" and a wiki that shows all of them together.

## What's in it

All of it lives in [`memory/`](memory/), in one compose stack:

- **`basic-memory-dev`** and **`basic-memory-netadmin`**: [Basic Memory](https://github.com/basicmachines-co/basic-memory) MCP servers (streamable HTTP), one per space. Each container mounts only its own folder of the notes repo, so one space can never see another. `dev` is shared by Steward Warden and the orchestrator agents. `netadmin` is the network admin agent's own.
- **`wiki`**: [Gollum](https://github.com/gollum/gollum), a git-backed Markdown wiki over the whole notes repo. It's the human view of every space, with search and history. Edits made there are git commits, and Basic Memory picks them up.
- **`git-backup`**: a small sidecar that commits any changes and pushes them to the notes repo every few minutes (5 by default).

The notes themselves are in a separate private repo (`NOTES_REPO`). This repo holds only the stack.

## Security

The Basic Memory HTTP endpoints have **no authentication of their own**. Every route goes through Traefik with its own basic-auth users (`MEMORY_DEV_USERS`, `MEMORY_NETADMIN_USERS`, `WIKI_USERS`), so each space has its own credential. Don't publish port 8000 directly.

## Install

1. Create the private notes repo and add a read/write deploy key for it.
2. `cp memory/.env.example memory/.env` and fill it in.
3. `./install`. It clones the notes repo, creates `dev/` and `netadmin/`, starts the stack and registers each space's folder as its `main` project.

MCP endpoints: `https://$MEMORY_HOST/dev/mcp` and `https://$MEMORY_HOST/netadmin/mcp` (Basic Memory serves streamable HTTP on `/mcp`; the route prefix picks the space). Wiki: `https://$WIKI_HOST/`.

## Adding a space

Copy a `basic-memory-*` service in `memory/docker-compose.yaml` and change its folder, index volume, router and middleware names, and its users variable. Then add the folder name to the `for space in …` loops in `install`.

## Changelog

View [changelog](CHANGELOG.md).

## Licence

[MIT](LICENSE).
