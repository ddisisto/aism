# CONTEXT.md Structure Proposal

## Purpose
Living document that maintains architectural coherence across sessions, acting as the architect's persistent memory and decision log.

## Proposed Structure

### 1. Current State Summary (Top)
- Where we are RIGHT NOW
- Next immediate priorities
- Active design tensions
- Always updated to reflect latest understanding

### 2. Core Patterns (Persistent)
- Fundamental principles that rarely change
- References to detailed docs (not duplicated)
- Why decisions were made, not just what

### 3. Decision Log (Append-Only)
- Major decisions with context
- Format: Decision, Rationale, Session#, Date
- Grouped by architectural area
- Never delete, mark as superseded if changed

### 4. Active Explorations
- Current experiments/unknowns
- Questions needing answers
- Temporary - promote to decisions or remove

### 5. Meta Instructions (Bottom)
- How to read this file
- When/how to update
- What belongs here vs other docs

## Key Principles

### What Goes Here
- Architectural decisions and their WHY
- Current state and next steps
- Patterns discovered through use
- Pointers to detailed implementations

### What Doesn't
- Implementation details (link instead)
- Code examples (link instead)
- Historical narratives (just decisions)
- Speculative ideas (use separate docs)

### Update Protocol
1. Start of session: Read entire file
2. During session: Note decisions as they happen
3. End of session: Update current state & priorities
4. Keep it under 200 lines (link for details)

## Example Entry

```markdown
### Decision: Redis for Agent Communication (Session #2, 2024-01-06)
**Choice**: Single request queue with per-agent reply channels
**Rationale**: 
- Simplifies engine (single polling point)
- Natural serialization of state changes
- Aligns with tool's synchronous nature
**Details**: `/experiments/redis/interface-first-design.md`
**Supersedes**: Direct stdin/stdout (Session #1)
```

## Benefits
- New sessions can quickly orient
- Decisions have traceable history
- Patterns emerge from decision log
- Easy to see what's current vs historical

## Questions for Discussion
1. Should we version the CONTEXT.md file itself?
2. How to handle conflicting decisions across sessions?
3. Should we track "almost decisions" that we backed away from?
4. Is 200 lines too restrictive? Too generous?