# Docker Discovery - Distilled Insights

## Key Findings

### 1. Podman vs Docker
- System uses Podman with Docker compatibility
- Commands work identically, but compose needs adjustment
- Network behavior slightly different (use --network host for simplicity)

### 2. Container Communication Pattern
**Recommended**: Redis-based messaging over stdin/stdout complexity
- Cleaner separation of concerns
- Easier to debug and monitor
- Scales better with multiple agents

### 3. Container Architecture
```
[Engine] <--> [Redis] <--> [Agent Containers]
                             |
                             +-- Volume: /agents/{id}
```

### 4. Implementation Priority
1. **Immediate**: Get basic Redis pub/sub working
2. **Next**: Agent bootstrap script that connects to Redis
3. **Then**: Engine that spawns containers and monitors Redis
4. **Finally**: aism CLI that publishes to Redis

## Critical Decision Points

### Container Networking
- Use `--network host` for now (simpler Redis access)
- Move to custom networks later for isolation

### Message Format
Keep it simple:
```json
{
  "agent_id": "architect-a1b2c3",
  "command": "state_transition",
  "payload": {"target": "deep_work"},
  "timestamp": "2025-01-06T..."
}
```

### Next Concrete Steps
1. Create minimal agent bootstrap script
2. Test Redis pub/sub between containers
3. Design engine's container lifecycle management
4. Implement basic aism tool with Redis client

## Updated Architecture Understanding
The Docker/Podman layer is simpler than expected. Focus should shift to:
- Redis message protocol design
- Agent bootstrap sequence
- Engine's orchestration logic

Clean up:
```bash
podman stop aism-redis && podman rm aism-redis
```