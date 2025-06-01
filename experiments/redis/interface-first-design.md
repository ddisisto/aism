# AISM Interface-First Design

## Core Interfaces

### 1. Agent's Perspective (./aism tool)
```bash
# Agent checks inbox
./aism inbox check
# Returns: List of messages/tasks

# Agent transitions state
./aism state transition deep_work
# Returns: Success/failure

# Agent sends message to another agent
./aism send architect "Need architecture review"
# Returns: Message ID

# Agent queries own state
./aism state current
# Returns: Current state name

# Agent publishes completion
./aism task complete task-123
# Returns: Acknowledgment
```

### 2. Engine's Perspective
- Validates all state transitions against FSM rules
- Routes messages between agents
- Tracks agent intent and state
- Never directly commands agents

### 3. Tool (./aism) Requirements
**Option A: Thin Client**
- Tool is stateless, just formats/sends Redis messages
- Engine does all validation and state management
- Pro: Simple tool, one source of truth
- Con: More engine complexity

**Option B: Smart Client**
- Tool validates locally before sending
- Tool maintains connection/session state
- Pro: Faster feedback, less engine load
- Con: Duplicated logic, sync issues

**Recommendation: Thin Client** (aligns with simplicity principle)

## Interaction Flows

### State Transition Flow
```
1. Agent: ./aism state transition deep_work
2. Tool: 
   - Reads agent ID from env/container
   - Sends to Redis: LPUSH aism:requests {type: "state_transition", ...}
   - Waits on reply channel: BRPOP aism:agent:{id}:replies
3. Engine:
   - Polls aism:requests
   - Validates against FSM
   - Updates state in Redis
   - Sends reply to agent's reply channel
4. Tool:
   - Receives reply
   - Exits with appropriate code
```

### Message Send Flow
```
1. Agent: ./aism send architect "Need review"
2. Tool:
   - Formats message with sender ID
   - LPUSH aism:requests {type: "send_message", ...}
   - Waits for ack on reply channel
3. Engine:
   - Validates sender/recipient exist
   - Checks recipient accepts messages in current state
   - LPUSH to recipient's inbox
   - Sends ack to sender
```

## Key Design Decisions

### 1. Single Request Queue
All agent requests go through `aism:requests` queue:
- Engine has one place to monitor
- Natural serialization point
- Easy to add middleware/logging

### 2. Per-Agent Reply Channels
Each agent has `aism:agent:{id}:replies`:
- Tool can block waiting for its specific reply
- No reply crosstalk between agents
- Engine routes replies to correct agent

### 3. Tool Behavior
- **Synchronous**: Tool blocks until reply received
- **Timeout**: 30 seconds default (configurable)
- **Stateless**: No daemon needed per agent
- **Exit codes**: 0=success, 1=invalid request, 2=timeout

### 4. Message Format
```json
{
  "id": "uuid",
  "agent_id": "architect-123",
  "type": "state_transition|send_message|inbox_check|...",
  "payload": {...},
  "timestamp": "iso8601"
}
```

## Redis Mapping

### Queues (Lists)
```
aism:requests              # All agent→engine requests
aism:agent:{id}:replies    # Engine→agent responses
aism:agent:{id}:inbox      # Agent's incoming messages
```

### State (Strings/Hashes)
```
aism:agent:{id}:state      # Current state
aism:agent:{id}:metadata   # Type, labels, etc
```

### Events (Pub/Sub)
```
aism:events:transitions    # State change notifications
aism:events:messages       # Message flow monitoring
```

## Implementation Order

1. **Minimal aism tool**
   ```go
   - Parse command line
   - Read agent ID from env
   - Format JSON message
   - Send to Redis
   - Wait for reply
   - Exit with code
   ```

2. **Basic engine loop**
   ```python
   while True:
       request = redis.brpop("aism:requests")
       response = handle_request(request)
       redis.lpush(f"aism:agent:{request.agent_id}:replies", response)
   ```

3. **State validation**
   - Load FSM from protocols/
   - Validate transitions
   - Update state atomically

## No Daemon Required!
Each `./aism` invocation:
1. Connects to Redis
2. Sends one request
3. Waits for one reply
4. Exits

This maps perfectly to how agents use Bash() - each command is independent.