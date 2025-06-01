# Protocol and Flow Schema Design

## Terminology

- **Protocol**: Defines behavior within a single state (how to act when in "inbox")
- **Flow**: Defines paths through multiple states (which states to visit and when)

## Protocol Structure

Each protocol defines behavior for a single state:
- Description and purpose
- Expected actions and behaviors
- Available capabilities
- Exit conditions (when to transition)
- Measurement points

## Example Protocol (Single State Behavior)

```yaml
# protocols/inbox.md
protocol: inbox
version: 1.0

purpose: "Process messages and decide next actions"

behaviors:
  - Check messages in priority order
  - Evaluate tasks against current goals  
  - Identify most important work
  - Decide on state transition

exit_conditions:
  to_deep_work:
    when: "Focused task identified"
    context_required:
      - task_description
      - estimated_duration
  
  to_idle:
    when: "No actionable items"
    
  to_distill:
    when: "Context pressure high"

constraints:
  max_duration: 300  # seconds
  
measurements:
  - message_processing_time
  - decision_quality
  - transition_rationale
```

## Example Flow (Multi-State Pattern)

```yaml
# flows/work_cycle.md
flow: work_cycle
version: 1.0

description: "Standard work pattern for productive agents"

states:
  - inbox      # Entry point
  - deep_work  # Focused execution
  - distill    # Context management

transitions:
  inbox_to_deep_work:
    frequency: "When tasks available"
    
  deep_work_to_inbox:
    frequency: "After task completion"
    
  any_to_distill:
    frequency: "When context pressure > 80%"
    
  distill_to_inbox:
    frequency: "After context compressed"

patterns:
  - "Spend most time in deep_work"
  - "Check inbox regularly but not obsessively"
  - "Distill before context overflow"
```

## Types of Protocols

### 1. Bootstrap Protocol
Special protocol for agent initialization
- Sets up agent identity and context
- Performs initial health checks
- Transitions to inbox when ready

### 2. Work Protocols  
Define how agents behave in work states
- inbox: Message processing and planning
- deep_work: Focused task execution
- distill: Context compression

### 3. Coordination Protocols
Define multi-agent interaction behaviors
- handshake: Initial agent introduction
- collaborate: Joint task execution
- delegate: Task handoff

## Types of Flows

### 1. Linear Flows
One-time sequences (rare in AISM)
- bootstrap_flow: Initialize → Configure → Enter work_cycle

### 2. Cyclic Flows  
Repeating patterns (common)
- work_cycle: inbox ↔ deep_work with periodic distill
- context_refresh: distill → clear → bootstrap → inbox

### 3. Reactive Flows
Event-driven patterns
- emergency_response: any → alert → coordinate → resolve

## Validation Rules

### State Validation
- Agent must be in valid state
- State constraints must be satisfied
- Capabilities match attempted actions

### Transition Validation
- From-state must match current
- To-state must be in allowed list
- Conditions must be met
- Required context must be provided

### Temporal Validation
- Min/max duration constraints
- Transition cooldowns
- Deadline enforcement

## Extension Mechanism

Protocols can inherit from others:

```yaml
protocol: specialized_worker
extends: base_worker
version: 1.0

states:
  # Inherits all base states
  specialized_analysis:
    description: "Domain-specific analysis"
    # ...

transitions:
  # Inherits base transitions
  # Adds new ones
```

## Discovery and Negotiation

Agents can:
1. Query available protocols
2. Propose protocol extensions
3. Negotiate protocol versions with peers

## Open Questions

1. **Dynamic Protocol Loading?**
   - Can protocols be added at runtime?
   - How to handle version conflicts?

2. **Protocol Composition?**
   - Can an agent follow multiple protocols?
   - How to resolve conflicts?

3. **Enforcement Mechanism?**
   - Hard enforcement (blocked operations)?
   - Soft enforcement (warnings)?
   - Measurement only?