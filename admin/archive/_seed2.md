AISM /

USER: check _seed.md first. I want to setup the git repo, and figure out the container orchestration piece first. on linux, used docker, docker-compose, k8s before, but want to keep this reaaaaally simple to start. docker-compose is out of favour now I think?
Edit

ASSISSTANT:
scanning _seed.md

ah yes. the retrofit nightmare → clean slate energy. git-as-message-bus trauma. I feel this.

container orchestration thoughts cascading...

docker-compose status check:

    not "out of favor" exactly
    docker introduced docker compose (no hyphen) as plugin
    same yaml format, just docker compose up not docker-compose up
    still perfect for local dev orchestration
    k8s = massive overkill for this phase

minimal orchestration path:

bash

# just raw docker initially?
docker network create aism-net

# agent containers
docker run -d \
  --name agent-alice \
  --network aism-net \
  -v $(pwd)/repo:/repo \
  -e AGENT_ID=alice \
  claude-code-image

# engine container  
docker run -d \
  --name aism-engine \
  --network aism-net \
  -v $(pwd)/repo:/repo \
  engine-image

but... manual container management = pain quickly

switching to structured planning mode for clarity
Option Analysis
1. Raw Docker Commands

Pros:

    Zero abstraction
    Direct control
    No extra config files

Cons:

    Repetitive commands
    No declarative state
    Hard to reproduce

2. Simple Bash Scripts

Pros:

    Still minimal
    Can version control
    Easy modification

Cons:

    Reinventing orchestration
    Error handling complexity

3. Docker Compose (modern docker compose)

Pros:

    Declarative
    Built for exactly this
    Single compose.yaml
    Handles networking/volumes/envs
    docker compose logs -f for debugging

Cons:

    One more config file
    (but that's barely a con)

back to stream mode

compose.yaml vision:

yaml

services:
  engine:
    build: ./engine
    volumes:
      - ./repo:/repo
    environment:
      - MODE=development
  
  alice:
    image: claude-code:latest  # need to figure this out
    volumes:
      - ./repo:/repo:rw
    environment:
      - AGENT_ID=alice
    depends_on:
      - engine
    stdin_open: true
    tty: true
    
  bob:
    image: claude-code:latest
    volumes:
      - ./repo:/repo:rw
    environment:
      - AGENT_ID=bob
    depends_on:
      - engine
    stdin_open: true
    tty: true

claude-code containerization question...

    is there official image?
    build our own wrapper?
    or... different approach?

pause

wait. re-reading your base reqs:

    Claude Code cli for running agent instances

hmm. claude-code IN container or ORCHESTRATING containers?

if orchestrating:

    agents run claude-code on host
    each launches container for isolation?
    or claude-code itself provides sufficient isolation?

filesystem structure first might clarify:

bash

aism/
├── compose.yaml
├── repo/
│   ├── agents/
│   │   ├── alice/
│   │   └── bob/
│   ├── protocols/
│   │   ├── bootstrap.md
│   │   └── inbox.md
│   ├── bus/
│   │   ├── messages/
│   │   └── states/
│   └── engine/
│       └── _measurements/
├── engine/
│   ├── Dockerfile
│   └── src/
└── scripts/
    └── init-repo.sh

init script concept:

bash

#!/bin/bash
# init-repo.sh
mkdir -p repo/{agents,protocols,bus/{messages,states},engine/_measurements}
echo "# AISM Repository" > repo/README.md
git init repo/
cd repo && git add . && git commit -m "initial structure"

reconsidering claude-code integration

maybe:

    start without docker isolation for agents
    just filesystem permissions
    engine in container watching filesystem
    agents run via claude-code --workspace ./repo/agents/@alice

simpler? retains tool access. docker later if needed.

thoughts on immediate next steps:

    create git repo with structure
    simple compose.yaml for engine only
    draft tool abstraction layer (python script agents call?)
    bootstrap protocol in markdown

which thread to pull first?

USER: agent image: fairly minimal NodeJS + few other tools + npm install -g @anthropic-ai/claude-code. want engine to easily change/add/remove agents, so maybe we only need that to start - it gets docker socket mount and does the rest.
Edit

ASSISSTANT:
engine-as-orchestrator pattern recognition

YES. engine owns docker socket. spawns/manages agents. much cleaner.

dockerfile

# agent.Dockerfile
FROM node:20-slim
RUN apt-get update && apt-get install -y git curl
RUN npm install -g @anthropic-ai/claude-code
WORKDIR /repo

engine architecture crystallizing:

engine/
├── Dockerfile
├── orchestrator.py    # docker API calls
├── fsm_validator.py   # state machine rules
├── measurement.py     # fourth wall
└── tool_bridge.py     # agent ↔ engine comms

compose.yaml minimal:

yaml

services:
  engine:
    build: ./engine
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - ./repo:/repo
    environment:
      - AGENT_IMAGE=aism-agent:latest

engine spawning logic:

python

# orchestrator.py sketch
docker_client.containers.run(
    image="aism-agent:latest",
    name=f"aism-agent-{agent_id}",
    volumes={'/repo': {'bind': '/repo', 'mode': 'rw'}},
    environment={'AGENT_ID': agent_id},
    stdin_open=True,
    tty=True,
    detach=True,
    command=f"claude-code --workspace /repo/agents/{agent_id}"
)

tool bridge insight:

    agents need call mechanism → engine
    stdin/stdout? named pipes? unix socket?

pause

actually... claude-code interaction pattern?

    runs interactive?
    or scriptable?
    how agents invoke tool calls?

checking assumptions:

    claude-code = conversational interface
    agent (LLM) → claude-code → filesystem/commands
    but... how inject our tool layer?

possible approaches:

    wrapper script

    bash

    # in container
    claude-code --wrapper /engine/tool_wrapper.sh

    filesystem hooks
        agent writes to /repo/agents/@alice/TOOL_CALL
        engine watches, processes, writes response
    custom claude-code plugin
        if extensible?

lean toward (2) - filesystem as API

    simple
    debuggable
    async-friendly

agent workflow:

think → write TOOL_CALL → wait → read TOOL_RESPONSE → continue

markdown

# /repo/agents/alice/TOOL_CALL
action: state.transition
params:
  next: inbox
  context:
    reason: "bootstrap complete"

engine watches all TOOL_CALL files → validates → effects → writes response

bootstrap sequence:

    docker build -t aism-agent:latest -f agent.Dockerfile .
    docker compose up -d engine
    engine reads /repo/protocols/bootstrap.md
    engine spawns alice: orchestrator.spawn_agent('alice')
    alice wakes in bootstrap state
    alice reads protocol, executes
    alice writes TOOL_CALL for state transition
    engine validates, updates /repo/bus/states/alice.state

meta: switching to action mode

immediate todo:

    create repo structure
    write agent.Dockerfile
    basic engine skeleton with docker spawning
    simple TOOL_CALL/RESPONSE filesystem protocol

want me to artifact the initial structure?

USER: overcomplicated - claude code has native tool calling Bash("./aism args") and other tool calls built-in for file read/write/search, know how to use all these. agent sees STDOUT+ERR. Blocking/Synchronous == two way stream. Easy hook up to Model Context Protocol too. We must also send to STDIN of container to "prompt" the agent, can read responses back on STDOUT (but formatting prevents good parsing - actually tailing session json logs seems easiest, but TBD)

ASSISSTANT:
claude-code native tools insight flooding in

ahhhhhh. much cleaner. agent just calls Bash("./aism state transition inbox"). done.

bash

#!/usr/bin/env python3
# /repo/aism - executable in PATH
import sys, json
cmd = sys.argv[1]
# ... routing logic ...
print(json.dumps(response))

native tools:

    Bash() → our hook
    str_replace_editor() → agent workspace
    read_file() → context loading
    built-in everything

stdin/stdout architecture:

    engine → stdin → "check your messages"
    agent thinks → Bash("./aism message read")
    aism script → stdout → agent sees
    agent → more tool calls → work happens

session logs insight ++

    /root/.claude-code/sessions/*.json
    tail -f → real-time agent thoughts
    parse tool calls/responses
    fourth wall measurement

Model Context Protocol...

    future extensibility
    tool ecosystem
    but not needed day-1

simplified flow:

engine.py:
  spawn_agent('alice')
  docker.exec(alice, stdin="bootstrap protocol says check state")
  # watch session logs
  # see Bash("./aism state current")
  # know alice is thinking about state

container simplicity:

dockerfile

FROM node:20-slim
RUN npm install -g @anthropic-ai/claude-code
COPY aism /usr/local/bin/
WORKDIR /repo

aism tool design:

./aism state current
./aism state transition <state> [--context json]
./aism message send <to> <content>
./aism message read [--unread]
./aism measure self

returns json always. agent parses naturally.

engine daemon pattern:

python

# watch all containers
for container in docker.containers(label="aism-agent"):
    # tail session logs
    # track state transitions
    # validate FSM rules
    # measure everything

switching to build mode

next: scaffold this

bash

mkdir -p aism/{repo,engine}
cd aism

# repo structure
mkdir -p repo/{agents,protocols,bus/{messages,states},engine/_measurements}

# aism tool
cat > repo/aism << 'EOF'
#!/usr/bin/env python3
import sys, json, os

agent_id = os.environ.get('AGENT_ID', 'unknown')
cmd = sys.argv[1] if len(sys.argv) > 1 else 'help'

if cmd == 'state':
    if sys.argv[2] == 'current':
        # read from bus
        print(json.dumps({'state': 'bootstrap', 'duration': 0}))
        
# ... more commands ...
EOF

chmod +x repo/aism

want full scaffold artifact? or dive into specific piece first?


Powerful, large model for complex challenges Learn more
Project content
AISM
Created by Daniel DiSisto

        ddisisto/aism

        main

        GITHUB

Content
No content added yet
Add images, PDFs, docs, spreadsheets, and more to summarize, analyze, and query content with Claude.
