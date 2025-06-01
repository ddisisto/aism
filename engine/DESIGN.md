# Engine Design Document

## Core Concepts

### 1. Engine as Orchestrator
The engine is the source of truth and coordination, but NOT the source of control. Agents maintain autonomy within the constraints of the FSM protocols.

### 2. State Machine Philosophy
- States are not just labels, but contexts with capabilities
- Transitions are validated but not prescribed
- Protocols define possibilities, not scripts

### 3. Communication Patterns

**Agent → Engine:**
- Tool calls (state transitions, message sending)
- Heartbeats/liveness
- Measurement data

**Engine → Agent:**
- Initial prompts/wake-ups
- State change notifications
- System events

**Agent → Agent:**
- Via message bus only
- Engine validates and routes
- No direct communication

### 4. Measurement as First-Class Citizen
Everything is measured, but measurement doesn't interfere with operation. The "fourth wall" principle.

## Key Design Decisions

### 1. Synchronous vs Asynchronous Operations

**Synchronous (blocking):**
- State transitions - agent waits for validation
- Tool calls - agent waits for response

**Asynchronous (non-blocking):**
- Message delivery - fire and forget
- Measurements - collected in background

### 2. Protocol Definition Format

Protocols are markdown files that are both human-readable documentation AND machine-parseable specifications:

```markdown
# Protocol: inbox

## States
- inbox: Processing messages and requests
- deep_work: Focused task execution  
- distill: Context compression

## Transitions
- inbox → deep_work: When focused task identified
- inbox → idle: When no actionable items
- deep_work → distill: When context pressure high
```

### 3. Tool Interface Design

The `aism` CLI tool communicates with the engine via Redis:
- Lightweight message bus for request/response
- Pub/sub for async notifications if needed
- Atomic operations for state management
- Simple client libraries in any language

### 4. Container Interaction Pattern

Our interaction model:
- Engine prompts agent via stdin to check state/messages
- Agent autonomously decides what to do based on current state and protocol
- Agent reports back via tool calls (aism CLI)

**Workflow:**
1. Engine spawns agent container with AGENT_ID set
2. Engine sends prompt to stdin: "You are agent Alice in state 'bootstrap'. Follow the bootstrap protocol."
3. Agent reads `/protocols/bootstrap.md`, executes expected behaviors
4. Agent calls: `aism state transition inbox --context '{"bootstrap": "complete"}'`
5. Engine validates transition against current flow, updates state, responds
6. Engine prompts: "You are now in state 'inbox'. Follow the inbox protocol."

**Benefits:**
- Agents maintain autonomy (decide their own actions)
- Engine maintains control (validates all transitions)
- Clear boundaries between orchestration and execution
- Natural for LLM agents (respond to prompts)
- Synchronous operations keep things simple

## Component Architecture

### 1. Core Engine Components

```
Engine
├── Orchestrator (container lifecycle)
├── Validator (FSM rules)
├── Router (message passing)
├── Measurement (observability)
└── Bridge (tool interface)
```

### 2. Data Flow Patterns

```
Agent Tool Call → Bridge → Validator → Executor → Response
                                ↓
                          Measurement
```

### 3. State Management

**Redis for live operations:**
- Current agent states
- Pending transitions
- Message queues
- Request/response channels

**Filesystem for persistence:**
- `/agents/{name}/` - agent workspaces
- `/protocols/` - FSM definitions
- `/engine/_measurements/` - metrics and history
- Git tracks all changes for auditability

**Benefits:**
- Fast operations via Redis
- Durability via filesystem
- Debuggability - can inspect both layers
- No complex filesystem watching

## Resolved Design Decisions

1. **Agent Command Discovery**
   - Commands are documented in agent CLAUDE.md
   - Core commands (state, message, measure) always available
   - Additional commands can be discovered via `aism help`

2. **Failure Handling**
   - Agent crashes: Engine detects, logs, can restart
   - Mid-transition failures: Filesystem state shows incomplete
   - Engine restarts: Reads state from filesystem, resumes

3. **Multi-agent Coordination**
   - Central coordination through engine (no direct agent-to-agent)
   - Message passing for collaboration
   - Protocols define coordination patterns

4. **Resource Management**
   - Container-level CPU/memory limits
   - Token tracking via Claude Code session logs
   - Rate limiting in aism tool if needed

## Open Questions (Remaining)

1. **Session Management**
   - How to handle long-running agent sessions?
   - When to restart vs continue conversation?
   - Context window pressure handling?

2. **Protocol Evolution**
   - How to upgrade protocols while agents are running?
   - Version compatibility between agents?

3. **Measurement Granularity**
   - What level of detail to track?
   - How long to retain history?
   - Real-time metrics vs batch analysis?

## Next Steps

1. Define concrete protocol schema
2. Choose tool communication mechanism
3. Design measurement data model
4. Specify failure handling strategies