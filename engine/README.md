# AISM Engine

The engine is the core orchestrator and measurement harness for the Agent Intent State Machine system.

## Core Responsibilities

1. **Agent Lifecycle Management**
   - Spawn/terminate agent containers via Docker API
   - Monitor agent health and resource usage
   - Handle agent crashes/restarts

2. **State Machine Validation**
   - Read protocol definitions from `/protocols`
   - Validate state transitions against FSM rules
   - Enforce state invariants

3. **Message Bus Operations**
   - Process state transition requests
   - Route inter-agent messages
   - Maintain message ordering and delivery guarantees

4. **Measurement & Observability**
   - Track all state transitions
   - Monitor token usage and timing
   - Provide "fourth wall" view of system behavior
   - Generate metrics and traces

5. **Tool Bridge**
   - Handle agent tool calls
   - Validate and execute allowed operations
   - Return responses to agents

## Architecture

The engine runs as a single Python process with multiple async components:

- **Orchestrator**: Docker container management
- **FSM Validator**: Protocol enforcement
- **Message Router**: Inter-agent communication
- **Measurement Collector**: System observability
- **Tool Handler**: Agent command processing

## Design Principles

- **Simplicity First**: Start with filesystem-based operations
- **Async by Default**: Handle multiple agents concurrently
- **Fail-Safe**: Agents can't bypass validation
- **Observable**: Every action is measured and logged
- **Extensible**: Easy to add new protocols and tools