# Architect Context

## Current State (Session #2, 2025-01-06)

### Where We Are
- Docker/Podman container lifecycle tested and understood
- Redis-based agent communication pattern designed (single request queue, per-agent replies)
- Tool interface (`./aism`) defined as stateless CLI
- Ready to implement minimal tool and engine loop

### Next Priorities
1. Implement minimal `aism` tool (Go/Python - parse, send to Redis, wait for reply)
2. Create basic engine loop (poll requests, validate, respond)
3. Design FSM format for state validation
4. Test tool↔engine↔agent communication flow

### Active Tensions
- Message format simplicity vs future extensibility
- Engine complexity vs tool intelligence (resolved: thin client)
- Synchronous tool calls vs async agent operations

## Core Patterns

### System Architecture
- **Communication**: Redis message bus, not stdin/stdout
- **Persistence**: Redis (live state) + Filesystem (durability) hybrid
- **Containers**: Podman/Docker with host networking for now
- **Tool Design**: Stateless CLI, blocks for replies

### Design Principles
1. **Simplicity First**: Every choice reduces complexity
2. **Agent Autonomy**: Agents pull work when ready
3. **Living Patterns**: Protocols evolve through use
4. **Measurement Without Interference**: Observe via Redis events

References:
- Tool interface: `/experiments/redis/interface-first-design.md`
- Docker patterns: `/experiments/docker/distilled-insights.md`

## Architecture Decisions

### Redis Communication Pattern (Session #2)
**Decision**: Single `aism:requests` queue with per-agent reply channels
**Rationale**: 
- Single serialization point for engine
- Natural request/reply pattern for CLI tool  
- Agents can't crosstalk on replies
**Supersedes**: Direct stdin/stdout between engine and agents (Session #1)

### Tool Behavior (Session #2)
**Decision**: Stateless, synchronous CLI tool
**Rationale**:
- Maps perfectly to Bash() execution model
- No daemon complexity per agent
- Clear exit codes for success/failure

### Container Strategy (Session #2)
**Decision**: Host networking with Podman compatibility
**Rationale**:
- Simpler Redis access during development
- Podman already available on system
- Can migrate to isolated networks later

### Agent Workspace Structure (Session #1)
**Decision**: `/agents/{agent_id}/` for persistence
**Rationale**:
- Clean volume mounting
- Git-trackable changes
- No special characters in paths

## Meta: Maintaining This File

### What Belongs Here
- Current state and immediate priorities (constantly updated)
- Architectural decisions with rationale and session tracking
- Core patterns that guide implementation
- Pointers to detailed documentation

### What Doesn't
- Implementation code (link to files)
- Historical narratives (use git history)
- Detailed procedures (use separate docs)
- Speculative designs (use experiments/)

### Update Protocol
1. **Session Start**: Read full file, check current state
2. **During Work**: Note decisions as they're made
3. **Session End**: Update current state, add decisions, remove superseded content
4. **Maintenance**: Keep under 150 lines, link for details

### Decision Entry Format
```
### [Decision Name] (Session #X)
**Decision**: One-line summary
**Rationale**: Why this choice
**Supersedes**: Previous approach if applicable
```

Remove superseded sections once implementation is updated.