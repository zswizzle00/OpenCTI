#!/bin/bash

# Exit on error
set -e

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}Setting up Intezer Sandbox integration with OpenCTI...${NC}"

# Create directory for connectors if it doesn't exist
CONNECTORS_DIR="connectors"
if [ ! -d "$CONNECTORS_DIR" ]; then
    echo -e "${GREEN}Creating connectors directory...${NC}"
    mkdir -p "$CONNECTORS_DIR"
fi

# Clone the Intezer Sandbox connector
echo -e "${GREEN}Cloning Intezer Sandbox connector...${NC}"
cd "$CONNECTORS_DIR"
if [ ! -d "intezer-sandbox" ]; then
    git clone https://github.com/OpenCTI-Platform/connectors.git
    mv connectors/internal-enrichment/intezer-sandbox .
    rm -rf connectors
else
    echo -e "${GREEN}Intezer Sandbox connector already exists, skipping clone...${NC}"
fi

# Navigate to the connector directory
cd intezer-sandbox

# Create .env file if it doesn't exist
if [ ! -f ".env" ]; then
    echo -e "${GREEN}Creating .env file...${NC}"
    cat > .env << EOL
OPENCTI_URL=http://localhost:8080
OPENCTI_TOKEN=your-token-here
INTEZER_API_KEY=your-intezer-api-key-here
CONNECTOR_ID=ChangeMe
CONNECTOR_TYPE=INTERNAL_ENRICHMENT
CONNECTOR_NAME=Intezer
CONNECTOR_SCOPE=intezer-sandbox
CONNECTOR_CONFIDENCE_LEVEL=100
CONNECTOR_LOG_LEVEL=info
EOL
    echo -e "${RED}Please edit the .env file and add your OpenCTI token and Intezer API key${NC}"
fi

# Build the Docker image
echo -e "${GREEN}Building Docker image...${NC}"
docker-compose build

echo -e "${GREEN}Setup complete!${NC}"
echo -e "${GREEN}To start the connector, run: docker-compose up -d${NC}"
echo -e "${GREEN}To view logs, run: docker-compose logs -f${NC}"
