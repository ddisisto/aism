# Docker Discovery Findings

## Container Communication Patterns

### 1. Basic I/O
- `docker run -i` enables stdin interaction
- Simple echo/cat pipes work well for testing
- Direct stdin attachment is complex with running containers

### 2. Signal Handling
- Containers need proper SIGTERM handling for graceful shutdown
- Shell scripts should trap signals to clean up resources

### 3. Volume Mounting
- Agent workspaces at `/agents/{id}/` mount cleanly
- Read/write permissions work as expected
- Files persist after container stops

## Recommended Approach for AISM

### Container Launch Pattern
```bash
docker run -d \
  --name "aism-agent-${AGENT_ID}" \
  --label "aism.agent.id=${AGENT_ID}" \
  --label "aism.agent.type=${AGENT_TYPE}" \
  -v "/home/daniel/prj/aism/agents/${AGENT_ID}:/workspace" \
  -v "/home/daniel/prj/aism/protocols:/protocols:ro" \
  -e "REDIS_URL=redis://host.docker.internal:6379" \
  -i \
  alpine:latest \
  /agent-bootstrap.sh
```

### Communication Strategy
1. Engine writes command to Redis queue
2. Agent polls Redis for commands
3. Agent publishes responses to Redis
4. Engine monitors response channels

This avoids complex stdin/stdout management while maintaining clear boundaries.

## Next Steps
- Test Redis connectivity from containers
- Design message format for Redis queues
- Create agent bootstrap script
- Implement minimal aism CLI tool