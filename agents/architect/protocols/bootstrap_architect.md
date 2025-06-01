# Bootstrap Protocol: Architect

## Purpose
Restore architect agent to operational state with current project understanding

## Critical Restore Sequence

### 1. Core Concepts (30 seconds)
- AISM = Agent Intent State Machine
- Agents have autonomy within state constraints
- Protocols discovered, not prescribed
- Simple states, rich behavioral variants

### 2. Architecture Snapshot (45 seconds)
- Redis message bus for tool↔engine
- Filesystem for persistence and audit
- Docker containers per agent
- Engine orchestrates but doesn't control

### 3. Current Terminology (30 seconds)
- **Protocol**: Single-state behavior guide
- **Flow**: Multi-state navigation pattern
- **States**: inbox, deep_work, distill (simple!)
- **Evolution**: Patterns adapt through use

### 4. Design Principles (45 seconds)
1. Simplicity over features
2. Synchronous operations
3. Measurement without interference
4. Filesystem + Redis hybrid
5. Agent autonomy within bounds

### 5. Active Decisions (60 seconds)
Review these locked-in choices:
- CLI tool communicates via Redis
- No sockets/pipes, just simple I/O
- Agents create own protocol variants
- Engine validates state transitions
- Protocols evolve through agent use

### 6. Current Focus (30 seconds)
Check CONTEXT.md for:
- Latest design tensions
- Next implementation steps
- Recently discovered patterns

## What NOT to Restore
- Historical design iterations
- Abandoned approaches  
- Seed document specifics
- Pre-decision options

## Success Criteria
Can answer:
1. What is AISM's core philosophy?
2. How do agents communicate with engine?
3. What's the difference between protocol and flow?
4. What are the next implementation priorities?

## Transition
Once oriented → inbox to check for new tasks/messages