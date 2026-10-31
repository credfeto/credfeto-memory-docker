# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

<!--
Please ADD ALL Changes to the UNRELEASED SECTION and not a specific release
-->

## [Unreleased]
### Security
- Memory stack uses host networking with firewalld rich rules (added by ./install) so only the Traefik hosts can reach the unauthenticated Basic Memory and wiki ports; published Docker ports bypassed firewalld
- Traefik example authenticates each memory space with its own bearer token (traefik-api-token-middleware) instead of basic auth; tokens come from the Traefik hosts' .env
### Added
### Fixed
- Wiki serves the notes repo at /wiki; it was given a relative `dir` path, which Gollum resolves to the non-existent /wiki/dir
### Changed
- Memory stack publishes ports for Traefik on separate hosts instead of using Docker labels, with an example file-provider config
- SDK - Updated DotNet SDK to 10.0.403
### Deprecated
### Removed
### Deployment Changes

<!--
Releases that have at least been deployed to staging, BUT NOT necessarily released to live.  Changes should be moved from [Unreleased] into here as they are merged into the appropriate release branch
-->

## [0.0.1] - 2026-10-31
### Added
- Shared agent memory stack: Basic Memory MCP servers per space, a Gollum wiki over all spaces, and a git backup sidecar
### Changed
- SDK - Updated DotNet SDK to 10.0.403

## [0.0.0] - Project created