# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

<!--
Please ADD ALL Changes to the UNRELEASED SECTION and not a specific release
-->

## [Unreleased]
### Security
- `TRAEFIK_HOSTS` in `memory/.env.example` lists only the reverse proxies' DMZ VLAN addresses; their old Servers VLAN addresses are retired
- `TRAEFIK_HOSTS` in `memory/.env.example` lists the reverse proxies' DMZ VLAN addresses (192.168.140.250/.251 and 2a02:8010:61d5:140::250/251) alongside their Servers VLAN ones, so the proxies can reach Basic Memory and the wiki from either network
### Added
### Fixed
- git-backup: retry a failed backup round once after BACKUP_RETRY_SECONDS (default 30) so a transient DNS or network blip doesn't fail the round, and log when a round succeeds after a failure so the last log line reflects the current state
### Changed
- All containers use `restart: always` instead of `unless-stopped`, so a container stopped during a reboot or daemon restart is always brought back (an unless-stopped container was left down after a clean reboot)
- The git-backup image is built and published to ghcr.io/credfeto/memory-git-backup by a workflow whenever memory/git-backup/ changes, and docker-compose pulls it from there instead of building it locally, so watchtower can update it
### Deprecated
### Removed
- Removed unused .NET global.json and template solution (src/global.json, src/Credfeto.Template.slnx) - issue #4
### Deployment Changes

<!--
Releases that have at least been deployed to staging, BUT NOT necessarily released to live.  Changes should be moved from [Unreleased] into here as they are merged into the appropriate release branch
-->

## [0.0.3] - 2026-11-04
### Changed
- SDK - Updated DotNet SDK to 11.0.100-rc.3.26522.148

## [0.0.2] - 2026-10-31
### Security
- Memory stack uses host networking with firewalld rich rules (added by ./install) so only the Traefik hosts can reach the unauthenticated Basic Memory and wiki ports; published Docker ports bypassed firewalld
- Traefik example authenticates each memory space with its own bearer token (traefik-api-token-middleware) instead of basic auth; tokens come from the Traefik hosts' .env
### Fixed
- Wiki serves the notes repo at /wiki; it was given a relative `dir` path, which Gollum resolves to the non-existent /wiki/dir
### Changed
- Memory stack publishes ports for Traefik on separate hosts instead of using Docker labels, with an example file-provider config
- SDK - Updated DotNet SDK to 10.0.403

## [0.0.1] - 2026-10-31
### Added
- Shared agent memory stack: Basic Memory MCP servers per space, a Gollum wiki over all spaces, and a git backup sidecar
### Changed
- SDK - Updated DotNet SDK to 10.0.403

## [0.0.0] - Project created