# AISM - Agent Intent State Machine

A framework for orchestrating autonomous AI agents with formal state management and explicit intent tracking.

## Structure

- `agents/` - Agent workspaces and identities
- `protocols/` - Single-state behavior definitions
- `flows/` - Multi-state patterns and cycles
- `engine/` - Orchestration engine and measurement harness
- `docker/` - Container definitions and compose files

## Architecture

- **Message Bus**: Redis for tool-engine communication
- **State Management**: Redis for live state, filesystem for persistence
- **Agent Interface**: CLI tool (`aism`) using Claude Code's Bash()
- **Container Orchestration**: Docker with engine managing agent lifecycle

## Quick Start

```bash
# Start Redis and Engine
docker compose up -d

# Engine will spawn agents according to protocols
```