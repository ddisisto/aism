# Redis Channel Design for AISM

## Redis Concepts Quick Primer

### Pub/Sub
- Publishers send messages to channels
- Subscribers receive messages from channels they're watching
- Fire-and-forget (no persistence, no guaranteed delivery)
- Good for: real-time events, state changes

### Lists (Queues)
- LPUSH/RPOP for queue behavior
- Messages persist until consumed
- Blocking pop available (BRPOP)
- Good for: task queues, command buffers

### Streams
- Append-only log with consumer groups
- Messages persist with IDs
- Multiple consumers can read at different positions
- Good for: event sourcing, audit trails

## AISM Requirements → Redis Patterns

### 1. Engine → Agent Commands
**Need**: Engine sends commands to specific agents
**Pattern**: List per agent for command queue
```
Channel: aism:agent:{agent_id}:commands
Example: aism:agent:architect-a1b2c3:commands
Operations: LPUSH (engine), BRPOP (agent)
```

### 2. Agent → Engine Responses
**Need**: Agents respond to engine, engine routes by type
**Pattern**: Pub/Sub for immediate notifications + List for persistence
```
Channel: aism:engine:responses (pub/sub for notifications)
List: aism:engine:response_queue (for reliable delivery)
```

### 3. State Change Events
**Need**: Broadcast state transitions for monitoring
**Pattern**: Pub/Sub for real-time updates
```
Channel: aism:events:state_changes
Message: {agent_id, old_state, new_state, timestamp}
```

### 4. Agent Heartbeats
**Need**: Detect agent health/liveness
**Pattern**: Sorted Set with timestamps
```
Key: aism:agents:heartbeats
Score: timestamp
Member: agent_id
```

## Proposed Channel Structure

```
aism:
├── agent:
│   └── {agent_id}:
│       ├── commands       (List - engine→agent commands)
│       ├── state         (String - current state)
│       └── metadata      (Hash - labels, type, etc)
├── engine:
│   ├── responses         (Pub/Sub channel)
│   └── response_queue    (List - reliable delivery)
├── events:
│   ├── state_changes     (Pub/Sub - all state transitions)
│   ├── errors           (Pub/Sub - system errors)
│   └── measurements     (Pub/Sub - metrics)
└── agents:
    └── heartbeats       (Sorted Set - liveness tracking)
```

## Message Flow Examples

### 1. State Transition Command
```
Engine: LPUSH aism:agent:architect-a1b2c3:commands
{
  "id": "cmd-123",
  "type": "state_transition",
  "payload": {"target": "deep_work"},
  "timestamp": "2025-01-06T..."
}

Agent: BRPOP aism:agent:architect-a1b2c3:commands 0
(blocks until command available)
```

### 2. Agent Response
```
Agent: 
1. LPUSH aism:engine:response_queue {response}
2. PUBLISH aism:engine:responses {response}

Engine:
- Subscribes to aism:engine:responses (for immediate notification)
- Processes from response_queue (for reliability)
```

### 3. State Change Event
```
Agent: PUBLISH aism:events:state_changes
{
  "agent_id": "architect-a1b2c3",
  "old_state": "inbox",
  "new_state": "deep_work",
  "timestamp": "2025-01-06T..."
}
```

## Design Questions

1. **Delivery Guarantees**: Use Lists for commands (persistent) but Pub/Sub for events (ephemeral)?
2. **Message Format**: JSON for flexibility vs MessagePack for efficiency?
3. **Channel Naming**: Hierarchical (shown above) vs flat?
4. **Error Handling**: Separate error queue per agent or centralized?
5. **History**: Use Streams for audit trail or rely on filesystem?

## Next Steps
- Validate this design aligns with AISM philosophy
- Create test scripts to verify patterns work as expected
- Define exact message schemas
- Consider failure scenarios