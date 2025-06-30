# Build stage
FROM swift:5.9-jammy AS build

# Install dependencies
RUN apt-get update && apt-get install -y \
    libcurl4-openssl-dev \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy package files
COPY Package.swift ./
COPY Sources ./Sources
COPY Tests ./Tests

# Build in release mode
RUN swift build -c release

# Runtime stage
FROM swift:5.9-jammy-slim

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    libcurl4 \
    && rm -rf /var/lib/apt/lists/*

# Create app user
RUN useradd -m -s /bin/bash appuser

# Copy built binary
COPY --from=build /app/.build/release/gemini-cli /usr/local/bin/gemini-cli

# Switch to app user
USER appuser

# Set entrypoint
ENTRYPOINT ["gemini-cli"]