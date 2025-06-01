# Engine Interface Design

## Tool Bridge Interface

The `aism` CLI tool communicates with the engine via Redis message bus:

```bash
# Agent calls (via Claude Code's Bash() tool)
aism state current
aism state transition inbox --context '{"reason": "task complete"}'
aism message send alice "Need help with task X"
aism message read --unread
```

**Internal flow:**
1. Agent calls `aism` tool via Bash()
2. Tool publishes request to Redis channel
3. Engine processes request and publishes response
4. Tool blocks waiting for response
5. Tool returns JSON to agent's stdout

Key principles:
- Synchronous from agent's perspective (blocks for response)
- Simple JSON on stdout, errors on stderr
- Redis handles all IPC complexity
- Clean separation between agent interface and engine implementation

## Communication Patterns

### State Transitions (Always Synchronous)
Agent requests transition, blocks until validated and executed:

```
Agent: aism state transition deep_work --context '{"task": "implement parser"}'
Engine: {"success": true, "state": "deep_work", "since": "2024-01-01T12:00:00Z"}
```

### Message Sending (Synchronous Accept, Async Delivery)
Agent sends message, blocks until engine accepts for routing:

```
Agent: aism message send bob "Can you review this?"
Engine: {"success": true, "accepted": "2024-01-01T12:00:00Z", "id": "msg_123"}
```

The receiving agent may read the message later - delivery is async.

### Message Reading (Synchronous)
Agent polls for messages when ready:

```
Agent: aism message read --unread
Engine: {"messages": [{"from": "alice", "content": "...", "timestamp": "..."}]}
```

## Data Models

### Core Types

```typescript
interface AgentIdentity {
  id: string
  capabilities: string[]
  protocols: string[]
  metadata: Record<string, any>
}

interface StateContext {
  current: string
  since: Date
  transitions_available: string[]
  constraints: StateConstraints
  measurements: StateMeasurements
}

interface Message {
  id: string
  from: string
  to: string
  type: MessageType
  content: any
  timestamp: Date
  thread_id?: string
}

interface TransitionRequest {
  from: string
  to: string
  context: Record<string, any>
  reason?: string
}

interface ToolResponse {
  success: boolean
  data?: any
  error?: ErrorInfo
  measurements?: Measurements
}
```

## Error Handling

### Error Categories

1. **Validation Errors**
   - Invalid state transition
   - Missing required context
   - Protocol violation

2. **System Errors**
   - Container failure
   - Resource exhaustion
   - Network issues

3. **Coordination Errors**
   - Message delivery failure
   - Conflicting state claims
   - Timeout violations

### Error Response Format

```json
{
  "error": {
    "type": "validation_error",
    "code": "invalid_transition",
    "message": "Cannot transition from 'idle' to 'deep_work'",
    "details": {
      "current_state": "idle",
      "requested_state": "deep_work",
      "allowed_transitions": ["inbox"]
    },
    "recovery_suggestions": [
      "Transition to 'inbox' first",
      "Check protocol definition"
    ]
  }
}
```

## Extensibility

### Tool Commands
The aism CLI tool can be extended with new commands as needed, but core commands remain stable:

```bash
# Core commands (always available)
aism state [current|transition]
aism message [send|read]
aism measure [self|system]

# Future extensions possible
aism protocol list
aism context [save|load]
```

### Model Context Protocol (MCP)
Future integration point for richer tool ecosystems, but not required for MVP.

## Security & Isolation

1. **Agent Identity**
   - Set via AGENT_ID environment variable
   - Trusted within container boundary
   - Cannot be spoofed by agent

2. **Filesystem Permissions**
   - Agents can only write to their own workspace
   - Bus operations go through aism tool only
   - Direct bus writes are prevented

3. **Container Isolation**
   - Each agent in separate container
   - Shared repo mount but controlled access
   - No direct agent-to-agent communication

## Performance Considerations

1. **Latency Targets**
   - Tool response: <100ms
   - State transition: <500ms
   - Message delivery: <1s

2. **Throughput Targets**
   - 100+ agents concurrent
   - 1000+ messages/second
   - 10+ state transitions/second

3. **Resource Limits**
   - Memory per agent
   - CPU quotas
   - Storage boundaries