FROM node:20-slim

# Install base tools
RUN apt-get update && apt-get install -y \
    git \
    curl \
    python3 \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

# Install Claude Code CLI
RUN npm install -g @anthropic-ai/claude-code

# Create agent user (non-root)
RUN useradd -m -s /bin/bash agent

# Copy aism tool
COPY aism /usr/local/bin/
RUN chmod +x /usr/local/bin/aism

# Set working directory
WORKDIR /workspace

# Switch to agent user
USER agent

# Default to bash for now (will be overridden by engine)
CMD ["/bin/bash"]