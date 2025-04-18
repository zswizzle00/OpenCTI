#!/bin/bash

# CrowdStrike OpenCTI Connector Setup Script

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Function to print colored messages
print_message() {
    echo -e "${2}${1}${NC}"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    print_message "Please run as root" "$RED"
    exit 1
fi

# Check if OpenCTI is installed
if [ ! -d "/opt/opencti" ]; then
    print_message "OpenCTI installation not found. Please install OpenCTI first." "$RED"
    exit 1
fi

# Create connectors directory if it doesn't exist
CONNECTORS_DIR="/opt/opencti/connectors"
if [ ! -d "$CONNECTORS_DIR" ]; then
    mkdir -p "$CONNECTORS_DIR"
fi

# Clone the CrowdStrike connector
print_message "Cloning CrowdStrike connector..." "$YELLOW"
cd "$CONNECTORS_DIR" || exit 1
if [ ! -d "crowdstrike-endpoint-security" ]; then
    git clone https://github.com/OpenCTI-Platform/connectors.git
    mv connectors/stream/crowdstrike-endpoint-security .
    rm -rf connectors
else
    print_message "CrowdStrike connector already exists. Updating..." "$YELLOW"
    cd crowdstrike-endpoint-security || exit 1
    git pull
fi

# Create .env file
print_message "Creating .env file..." "$YELLOW"
cd crowdstrike-endpoint-security || exit 1
cat > .env << EOL
OPENCTI_URL=http://localhost:8080
OPENCTI_TOKEN=your_opencti_token
CONNECTOR_ID=your_connector_id
CONNECTOR_TYPE=STREAM
CONNECTOR_NAME=CrowdStrike
CONNECTOR_SCOPE=indicator
CONNECTOR_CONFIDENCE_LEVEL=100
CONNECTOR_LOG_LEVEL=info
CROWDSTRIKE_CLIENT_ID=your_crowdstrike_client_id
CROWDSTRIKE_CLIENT_SECRET=your_crowdstrike_client_secret
CROWDSTRIKE_BASE_URL=https://api.crowdstrike.com
CROWDSTRIKE_PERMANENT_DELETE=false
CROWDSTRIKE_FALCON_FOR_MOBILE=false
EOL

print_message "CrowdStrike connector setup complete!" "$GREEN"
print_message "Please edit the .env file with your credentials:" "$YELLOW"
print_message "1. OPENCTI_TOKEN: Your OpenCTI API token" "$YELLOW"
print_message "2. CONNECTOR_ID: A unique identifier for this connector" "$YELLOW"
print_message "3. CROWDSTRIKE_CLIENT_ID: Your CrowdStrike API client ID" "$YELLOW"
print_message "4. CROWDSTRIKE_CLIENT_SECRET: Your CrowdStrike API client secret" "$YELLOW"

print_message "\nTo start the connector, run:" "$GREEN"
print_message "cd /opt/opencti/connectors/crowdstrike-endpoint-security" "$GREEN"
print_message "docker-compose up -d" "$GREEN"
