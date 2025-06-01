# AISM Container Naming & Labeling Strategy

## Container Names
Format: `aism-{agent_type}-{agent_id}`

Examples:
- `aism-architect-a1b2c3`
- `aism-engineer-d4e5f6`
- `aism-analyst-g7h8i9`

## Labels
Standard labels for all agent containers:

```
aism.version=1.0
aism.agent.id={unique_id}
aism.agent.type={architect|engineer|analyst|...}
aism.agent.state={inbox|deep_work|distill}
aism.agent.created={iso8601_timestamp}
aism.protocol.current={protocol_name}
aism.protocol.version={protocol_version}
```

## Benefits
1. Easy filtering: `docker ps --filter label=aism.agent.type=architect`
2. State tracking: `docker ps --filter label=aism.agent.state=deep_work`
3. Cleanup: `docker rm $(docker ps -aq --filter label=aism.version)`
4. Monitoring: Labels accessible to monitoring tools

## Engine Usage
```bash
# List all AISM agents
docker ps --filter label=aism.version

# Find agents in specific state
docker ps --filter label=aism.agent.state=inbox

# Get agent metadata
docker inspect -f '{{.Config.Labels}}' aism-architect-a1b2c3
```