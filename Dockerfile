# Use the official OpenCTI platform image as base
FROM opencti/platform:5.12.5

# Set environment variables
ENV NODE_ENV=production

# Install additional system dependencies if needed
RUN apt-get update && apt-get install -y \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Create directory for custom configurations
RUN mkdir -p /opt/opencti/config

# Copy any custom configurations
COPY config/ /opt/opencti/config/

# Set working directory
WORKDIR /opt/opencti

# Expose the OpenCTI port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8080/api/health || exit 1

# Use the default entrypoint from the base image
# The base image already includes the proper startup command 