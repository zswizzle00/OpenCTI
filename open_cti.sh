#!/bin/bash

# Exit immediately if a command fails
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Log file for debugging
LOG_FILE="/var/log/opencti_install.log"

# Defaults for argument parsing
INSTALL_DIR="/opt/opencti"
SKIP_DOCKER_INSTALL=false
ENV_FILE_ONLY=false

# Memory configurations (in MB)
NODE_MEMORY="8096M"  # Platform memory 8GB (default from docs)
ES_MEMORY="8G"     # ElasticSearch memory 8GB (recommended)
REDIS_MEMORY="2G"  # Redis memory 2GB (for stream size)

# Function to log messages
log_message() {
    echo -e "$1" | tee -a "$LOG_FILE"
}

# Function to display help
show_help() {
    echo -e "${YELLOW}Usage: $0 [options]${NC}"
    echo "Options:"
    echo "  -h, --help                Show this help message and exit"
    echo "  -d, --directory <path>    Specify the installation directory (default: /opt/opencti)"
    echo "  -s, --skip-docker         Skip Docker and Docker Compose installation"
    echo "  -e, --env-only            Only generate the .env file, skip installation steps"
    echo "  -n, --node-memory <size>  Set NodeJS memory limit (default: 4G)"
    echo "  -m, --es-memory <size>    Set ElasticSearch memory limit (default: 2G)"
    echo "  -r, --redis-memory <size> Set Redis memory limit (default: 2G)"
    exit 0
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            ;;
        -d|--directory)
            INSTALL_DIR="$2"
            shift 2
            ;;
        -s|--skip-docker)
            SKIP_DOCKER_INSTALL=true
            shift
            ;;
        -e|--env-only)
            ENV_FILE_ONLY=true
            shift
            ;;
        -n|--node-memory)
            NODE_MEMORY="$2"
            shift 2
            ;;
        -m|--es-memory)
            ES_MEMORY="$2"
            shift 2
            ;;
        -r|--redis-memory)
            REDIS_MEMORY="$2"
            shift 2
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            show_help
            ;;
    esac
done

log_message "${GREEN}Starting OpenCTI Installation...${NC}"

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    log_message "${RED}Please run as root (use sudo)${NC}"
    exit 1
fi

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check OS type
get_os_type() {
    case "$(uname -s)" in
        Darwin*) echo "macos" ;;
        Linux*)  echo "linux" ;;
        *)       echo "unknown" ;;
    esac
}

# Function to configure system settings
configure_system() {
    log_message "${YELLOW}Configuring system settings...${NC}"
    
    # Set vm.max_map_count for ElasticSearch (from docs)
    sysctl -w vm.max_map_count=1048575 || { log_message "${RED}Failed to set vm.max_map_count${NC}"; exit 1; }
    
    # Make vm.max_map_count persistent
    if ! grep -q "vm.max_map_count=1048575" /etc/sysctl.conf; then
        echo "vm.max_map_count=1048575" >> /etc/sysctl.conf
    fi

    # Set swappiness to 1 to reduce swapping
    sysctl -w vm.swappiness=1 || { log_message "${RED}Failed to set vm.swappiness${NC}"; exit 1; }
    if ! grep -q "vm.swappiness=1" /etc/sysctl.conf; then
        echo "vm.swappiness=1" >> /etc/sysctl.conf
    fi

    # Set overcommit memory to 1
    sysctl -w vm.overcommit_memory=1 || { log_message "${RED}Failed to set vm.overcommit_memory${NC}"; exit 1; }
    if ! grep -q "vm.overcommit_memory=1" /etc/sysctl.conf; then
        echo "vm.overcommit_memory=1" >> /etc/sysctl.conf
    fi

    # Apply sysctl changes
    sysctl -p || { log_message "${RED}Failed to apply sysctl changes${NC}"; exit 1; }

    # Create swap file if it doesn't exist
    if [ ! -f /swapfile ]; then
        log_message "${YELLOW}Creating swap file...${NC}"
        fallocate -l 8G /swapfile  # Increased to 8GB
        chmod 600 /swapfile
        mkswap /swapfile
        swapon /swapfile
        echo '/swapfile none swap sw 0 0' >> /etc/fstab
    fi
}

# Install required packages
install_prerequisites() {
    log_message "${YELLOW}Checking and installing prerequisites...${NC}"
    
    # Update package list
    apt-get update >> "$LOG_FILE" 2>&1 || { log_message "${RED}Failed to update package list${NC}"; exit 1; }
    
    # Install base packages
    apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release git python3 python3-pip build-essential libssl-dev libffi-dev python3-dev software-properties-common wget >> "$LOG_FILE" 2>&1
    
    # Install Java
    if ! command_exists java; then
        log_message "${YELLOW}Installing Java...${NC}"
        
        # Add OpenJDK repository
        add-apt-repository -y ppa:openjdk-r/ppa >> "$LOG_FILE" 2>&1
        apt-get update >> "$LOG_FILE" 2>&1
        
        # Install OpenJDK 11
        apt-get install -y openjdk-11-jdk >> "$LOG_FILE" 2>&1 || { 
            log_message "${RED}Failed to install OpenJDK 11, trying alternative method...${NC}"
            # Alternative method using official Oracle repository
            wget -qO - https://adoptopenjdk.jfrog.io/adoptopenjdk/api/gpg/key/public | apt-key add - >> "$LOG_FILE" 2>&1
            echo "deb https://adoptopenjdk.jfrog.io/adoptopenjdk/deb $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/adoptopenjdk.list >> "$LOG_FILE" 2>&1
            apt-get update >> "$LOG_FILE" 2>&1
            apt-get install -y adoptopenjdk-11-hotspot >> "$LOG_FILE" 2>&1 || { log_message "${RED}Failed to install Java${NC}"; exit 1; }
        }
        
        # Set JAVA_HOME
        if [ -d "/usr/lib/jvm/java-11-openjdk-amd64" ]; then
            export JAVA_HOME="/usr/lib/jvm/java-11-openjdk-amd64"
        elif [ -d "/usr/lib/jvm/adoptopenjdk-11-hotspot-amd64" ]; then
            export JAVA_HOME="/usr/lib/jvm/adoptopenjdk-11-hotspot-amd64"
        else
            export JAVA_HOME=$(readlink -f /usr/bin/java | sed "s:/bin/java::")
        fi
        
        echo "JAVA_HOME=$JAVA_HOME" >> /etc/environment
        echo "PATH=$PATH:$JAVA_HOME/bin" >> /etc/environment
        source /etc/environment
    fi
    
    # Verify Java installation
    if ! command_exists java; then
        log_message "${RED}Java installation failed${NC}"
        log_message "${YELLOW}Attempting to find Java installation...${NC}"
        find /usr/lib/jvm -name java -type f -exec {} -version \; 2>&1
        exit 1
    fi
    
    java_version=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}')
    log_message "${GREEN}Java version $java_version installed successfully${NC}"
    log_message "${GREEN}JAVA_HOME set to: $JAVA_HOME${NC}"
    
    # Verify Java memory settings
    log_message "${YELLOW}Verifying Java memory settings...${NC}"
    if ! java -Xms${ES_MEMORY} -Xmx${ES_MEMORY} -version 2>&1 >/dev/null; then
        log_message "${RED}Java cannot allocate the required memory${NC}"
        log_message "${YELLOW}Please check your system memory and adjust ES_MEMORY if necessary${NC}"
        exit 1
    fi
    
    log_message "${GREEN}Java memory settings verified${NC}"
}

# Install Docker
install_docker() {
    if ! command_exists docker; then
        log_message "${YELLOW}Installing Docker...${NC}"
        
        # Remove old versions if they exist
        apt-get remove -y docker docker-engine docker.io containerd runc || true
        
        # Install required packages
        apt-get update >> "$LOG_FILE" 2>&1
        apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release >> "$LOG_FILE" 2>&1
        
        # Add Docker's official GPG key
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
        
        # Add Docker repository
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
        
        # Install Docker
        apt-get update >> "$LOG_FILE" 2>&1
        apt-get install -y docker-ce docker-ce-cli containerd.io >> "$LOG_FILE" 2>&1
        
        # Start and enable Docker service
        if command_exists systemctl; then
            log_message "${YELLOW}Using systemd to manage Docker service...${NC}"
            systemctl enable docker
            systemctl start docker
        else
            log_message "${YELLOW}Using service command to manage Docker service...${NC}"
            update-rc.d docker defaults
            service docker start
        fi
        
        # Verify Docker is running
        if ! docker info > /dev/null 2>&1; then
            log_message "${RED}Failed to start Docker service${NC}"
            log_message "${YELLOW}Attempting to start Docker manually...${NC}"
            if command_exists systemctl; then
                systemctl start docker
            else
                service docker start
            fi
            
            # Wait for Docker to start
            for i in {1..30}; do
                if docker info > /dev/null 2>&1; then
                    break
                fi
                sleep 1
            done
            
            if ! docker info > /dev/null 2>&1; then
                log_message "${RED}Failed to start Docker service after multiple attempts${NC}"
                exit 1
            fi
        fi
        
        # Add current user to docker group
        usermod -aG docker $SUDO_USER
        
        # Verify Docker installation
        if ! docker --version; then
            log_message "${RED}Docker installation failed${NC}"
            exit 1
        fi
        
        log_message "${GREEN}Docker installed and started successfully${NC}"
    else
        # Ensure Docker service is running
        if ! docker info > /dev/null 2>&1; then
            log_message "${YELLOW}Starting Docker service...${NC}"
            if command_exists systemctl; then
                systemctl start docker
            else
                service docker start
            fi
            
            # Wait for Docker to start
            for i in {1..30}; do
                if docker info > /dev/null 2>&1; then
                    break
                fi
                sleep 1
            done
            
            if ! docker info > /dev/null 2>&1; then
                log_message "${RED}Failed to start Docker service${NC}"
                exit 1
            fi
        fi
    fi
}

# Install Docker Compose
install_docker_compose() {
    if ! command_exists docker-compose; then
        log_message "${YELLOW}Installing Docker Compose...${NC}"
        
        # Download Docker Compose
        curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        
        # Make it executable
        chmod +x /usr/local/bin/docker-compose
        
        # Create symbolic link
        ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
        
        # Verify installation
        if ! docker-compose --version; then
            log_message "${RED}Docker Compose installation failed${NC}"
            exit 1
        fi
        
        log_message "${GREEN}Docker Compose installed successfully${NC}"
    fi
}

# Securely generate random passwords
generate_password() {
    openssl rand -base64 12
}

# Create environment file
create_env_file() {
    log_message "${YELLOW}Creating environment configuration...${NC}"
    mkdir -p "$INSTALL_DIR/opencti"
    
    # Get the VM's IP address
    VM_IP=$(hostname -I | awk '{print $1}')
    if [ -z "$VM_IP" ]; then
        VM_IP=$(ip addr show | grep -w inet | grep -v 127.0.0.1 | awk '{print $2}' | cut -d/ -f1 | head -n 1)
    fi
    
    if [ -z "$VM_IP" ]; then
        log_message "${RED}Could not determine VM IP address, using localhost${NC}"
        VM_IP="localhost"
    fi
    
    cat > "$INSTALL_DIR/opencti/.env" << EOL
# OpenCTI Configuration
OPENCTI_ADMIN_EMAIL=admin@opencti.io
OPENCTI_ADMIN_PASSWORD=admin@123
OPENCTI_ADMIN_TOKEN=$(uuidgen)
OPENCTI_BASE_URL=http://${VM_IP}:8080
NODE_OPTIONS=--max-old-space-size=${NODE_MEMORY}

# Healthcheck Configuration
HEALTHCHECK_ACCESS_KEY=$(uuidgen)

# RabbitMQ Configuration
RABBITMQ_DEFAULT_USER=opencti
RABBITMQ_DEFAULT_PASS=admin@123
RABBITMQ_MAX_MESSAGE_SIZE=536870912
RABBITMQ_CONSUMER_TIMEOUT=86400000

# Redis Configuration
REDIS_PASSWORD=admin@123
REDIS_MEMORY_LIMIT=${REDIS_MEMORY}

# Elasticsearch Configuration
ELASTICSEARCH_URL=http://elasticsearch:9200
ELASTICSEARCH_USERNAME=elastic
ELASTICSEARCH_PASSWORD=admin@123
ES_JAVA_OPTS=-Xms${ES_MEMORY} -Xmx${ES_MEMORY}
ELASTICSEARCH_THREAD_POOL_SEARCH_QUEUE_SIZE=5000

# MinIO Configuration
MINIO_ROOT_USER=opencti
MINIO_ROOT_PASSWORD=admin@123
EOL
    log_message "${GREEN}.env file created at $INSTALL_DIR/opencti/.env${NC}"
}

# Function to check system memory
check_system_memory() {
    log_message "${YELLOW}Checking system memory...${NC}"
    
    # Get total system memory in MB
    local total_mem=$(free -m | awk '/^Mem:/{print $2}')
    local required_mem=10240  # Minimum 10GB required
    
    if [ "$total_mem" -lt "$required_mem" ]; then
        log_message "${RED}Insufficient system memory. OpenCTI requires at least 10GB of RAM.${NC}"
        log_message "${YELLOW}Available memory: ${total_mem}MB${NC}"
        log_message "${YELLOW}Required memory: ${required_mem}MB${NC}"
        exit 1
    fi
    
    # Export memory variables
    export NODE_MEMORY
    export ES_MEMORY
    export REDIS_MEMORY
    
    log_message "${GREEN}Memory configuration:${NC}"
    log_message "Total system memory: ${total_mem}MB"
    log_message "OpenCTI: ${NODE_MEMORY}"
    log_message "Elasticsearch: ${ES_MEMORY}"
    log_message "Redis: ${REDIS_MEMORY}"
}

# Function to verify port availability
verify_ports() {
    log_message "${YELLOW}Verifying port availability...${NC}"
    local ports=("8080" "6379" "9200" "9000" "5672" "15672")
    local port_in_use=0

    for port in "${ports[@]}"; do
        if lsof -i :$port > /dev/null 2>&1; then
            log_message "${RED}Port $port is already in use${NC}"
            port_in_use=1
        fi
    done

    if [ $port_in_use -eq 1 ]; then
        log_message "${RED}Some required ports are already in use. Please free these ports and try again.${NC}"
        exit 1
    fi
}

# Function to check service health
check_service_health() {
    log_message "${YELLOW}Checking service health...${NC}"
    local max_attempts=60
    local attempt=1
    local services_healthy=0

    while [ $attempt -le $max_attempts ]; do
        # Check Elasticsearch health with detailed logging
        local es_health=$(curl -s "http://localhost:9200/_cluster/health")
        local es_status=$(echo "$es_health" | grep -o '"status":"[^"]*"' | cut -d'"' -f4)
        
        if [ -z "$es_status" ]; then
            log_message "${YELLOW}Waiting for Elasticsearch to respond (attempt $attempt/$max_attempts)...${NC}"
            if [ $attempt -gt 5 ]; then
                log_message "${YELLOW}Checking Elasticsearch logs...${NC}"
                docker-compose logs elasticsearch
                log_message "${YELLOW}Checking Elasticsearch container status...${NC}"
                docker-compose ps elasticsearch
            fi
            sleep 10
            ((attempt++))
            continue
        fi

        if [ "$es_status" != "green" ] && [ "$es_status" != "yellow" ]; then
            log_message "${YELLOW}Elasticsearch status: $es_status (attempt $attempt/$max_attempts)${NC}"
            log_message "${YELLOW}Full health response: $es_health${NC}"
            if [ $attempt -gt 5 ]; then
                log_message "${YELLOW}Checking Elasticsearch logs...${NC}"
                docker-compose logs elasticsearch
            fi
            sleep 10
            ((attempt++))
            continue
        fi

        # Check OpenCTI health
        if ! curl -s http://localhost:8080 > /dev/null; then
            log_message "${YELLOW}Waiting for OpenCTI to start (attempt $attempt/$max_attempts)...${NC}"
            sleep 10
            ((attempt++))
            continue
        fi

        services_healthy=1
        break
    done

    if [ $services_healthy -eq 0 ]; then
        log_message "${RED}Services failed to start within the expected time${NC}"
        log_message "${YELLOW}Checking container logs...${NC}"
        docker-compose logs
        exit 1
    fi
}

# Main function to coordinate the setup
main() {
    if $ENV_FILE_ONLY; then
        create_env_file
        log_message "${GREEN}Environment file generation complete. Exiting as requested.${NC}"
        exit 0
    fi

    # Check system memory before proceeding
    check_system_memory
    
    configure_system
    install_prerequisites

    if ! $SKIP_DOCKER_INSTALL; then
        install_docker
        install_docker_compose
    else
        log_message "${YELLOW}Skipping Docker installation as requested.${NC}"
    fi

    if [ ! -d "$INSTALL_DIR" ]; then
        mkdir -p "$INSTALL_DIR"
    fi

    log_message "${YELLOW}Cloning OpenCTI repository...${NC}"
    cd "$INSTALL_DIR"
    if [ ! -d "opencti" ]; then
        git clone https://github.com/OpenCTI-Platform/opencti.git || { log_message "${RED}Failed to clone repository${NC}"; exit 1; }
    fi

    # Copy necessary configuration files
    log_message "${YELLOW}Copying configuration files...${NC}"
    if [ -f "$INSTALL_DIR/opencti/docker-compose.yml" ]; then
        cp "$INSTALL_DIR/opencti/docker-compose.yml" "$INSTALL_DIR/opencti/docker-compose.yml.bak"
    fi
    
    # Copy the default docker-compose.yml if it doesn't exist
    if [ ! -f "$INSTALL_DIR/opencti/docker-compose.yml" ]; then
        cat > "$INSTALL_DIR/opencti/docker-compose.yml" << EOL
version: '3'
services:
  redis:
    image: redis:7.0
    restart: always
    volumes:
      - redisdata:/data
    command: ["--maxmemory", "\${REDIS_MEMORY_LIMIT}", "--maxmemory-policy", "allkeys-lru"]
    environment:
      - REDIS_PASSWORD=\${REDIS_PASSWORD}
    healthcheck:
      test: ["CMD", "redis-cli", "-a", "\${REDIS_PASSWORD}", "ping"]
      interval: 10s
      timeout: 5s
      retries: 3

  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:7.17.9
    restart: always
    volumes:
      - elasticsearchdata:/usr/share/elasticsearch/data
    environment:
      - discovery.type=single-node
      - xpack.security.enabled=true
      - ELASTIC_PASSWORD=\${ELASTICSEARCH_PASSWORD}
      - ES_JAVA_OPTS=\${ES_JAVA_OPTS}
      - thread_pool.search.queue_size=\${ELASTICSEARCH_THREAD_POOL_SEARCH_QUEUE_SIZE}
    ulimits:
      memlock:
        soft: -1
        hard: -1
    healthcheck:
      test: ["CMD-SHELL", "curl -s -u elastic:\${ELASTICSEARCH_PASSWORD} http://localhost:9200/_cluster/health | grep -q '\"status\":\"green\"' || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 3

  minio:
    image: minio/minio:RELEASE.2023-03-20T20-16-18Z
    restart: always
    volumes:
      - s3data:/data
    ports:
      - "9000:9000"
      - "9001:9001"
    environment:
      - MINIO_ROOT_USER=\${MINIO_ROOT_USER}
      - MINIO_ROOT_PASSWORD=\${MINIO_ROOT_PASSWORD}
    command: server /data --console-address ":9001"
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:9000/minio/health/live"]
      interval: 30s
      timeout: 20s
      retries: 3

  rabbitmq:
    image: rabbitmq:3.11-management
    restart: always
    volumes:
      - rabbitmqdata:/var/lib/rabbitmq
    environment:
      - RABBITMQ_DEFAULT_USER=\${RABBITMQ_DEFAULT_USER}
      - RABBITMQ_DEFAULT_PASS=\${RABBITMQ_DEFAULT_PASS}
    healthcheck:
      test: ["CMD", "rabbitmq-diagnostics", "check_port_connectivity"]
      interval: 30s
      timeout: 10s
      retries: 3

  opencti:
    image: opencti/platform:5.12.4
    restart: always
    depends_on:
      - redis
      - elasticsearch
      - minio
      - rabbitmq
    ports:
      - "8080:8080"
    environment:
      - NODE_OPTIONS=\${NODE_OPTIONS}
      - OPENCTI_ADMIN_EMAIL=\${OPENCTI_ADMIN_EMAIL}
      - OPENCTI_ADMIN_PASSWORD=\${OPENCTI_ADMIN_PASSWORD}
      - OPENCTI_ADMIN_TOKEN=\${OPENCTI_ADMIN_TOKEN}
      - OPENCTI_BASE_URL=\${OPENCTI_BASE_URL}
      - REDIS_HOSTNAME=redis
      - REDIS_PORT=6379
      - REDIS_PASSWORD=\${REDIS_PASSWORD}
      - ELASTICSEARCH_URL=\${ELASTICSEARCH_URL}
      - ELASTICSEARCH_USERNAME=\${ELASTICSEARCH_USERNAME}
      - ELASTICSEARCH_PASSWORD=\${ELASTICSEARCH_PASSWORD}
      - MINIO_ENDPOINT=minio
      - MINIO_PORT=9000
      - MINIO_USE_SSL=false
      - MINIO_ACCESS_KEY=\${MINIO_ROOT_USER}
      - MINIO_SECRET_KEY=\${MINIO_ROOT_PASSWORD}
      - RABBITMQ_HOSTNAME=rabbitmq
      - RABBITMQ_PORT=5672
      - RABBITMQ_USERNAME=\${RABBITMQ_DEFAULT_USER}
      - RABBITMQ_PASSWORD=\${RABBITMQ_DEFAULT_PASS}
      - RABBITMQ_MAX_MESSAGE_SIZE=\${RABBITMQ_MAX_MESSAGE_SIZE}
      - RABBITMQ_CONSUMER_TIMEOUT=\${RABBITMQ_CONSUMER_TIMEOUT}
      - HEALTHCHECK_ACCESS_KEY=\${HEALTHCHECK_ACCESS_KEY}
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
      interval: 30s
      timeout: 10s
      retries: 3

volumes:
  redisdata:
  elasticsearchdata:
  s3data:
  rabbitmqdata:
EOL
    fi

    # Create .env file while preserving .env.sample
    if [ -f "$INSTALL_DIR/opencti/.env.sample" ]; then
        log_message "${YELLOW}Preserving .env.sample file...${NC}"
        cp "$INSTALL_DIR/opencti/.env.sample" "$INSTALL_DIR/opencti/.env.sample.bak"
    fi

    create_env_file

    # Restore .env.sample if it was backed up
    if [ -f "$INSTALL_DIR/opencti/.env.sample.bak" ]; then
        mv "$INSTALL_DIR/opencti/.env.sample.bak" "$INSTALL_DIR/opencti/.env.sample"
        log_message "${GREEN}Restored .env.sample file${NC}"
    fi

    # Verify ports before starting
    verify_ports

    log_message "${YELLOW}Starting OpenCTI...${NC}"
    cd "$INSTALL_DIR/opencti"
    docker-compose up -d || { log_message "${RED}Failed to start OpenCTI${NC}"; exit 1; }

    # Check service health
    check_service_health

    log_message "${GREEN}OpenCTI installation completed!${NC}"
    log_message "${GREEN}OpenCTI is now accessible at: http://localhost:8080${NC}"
    log_message "${YELLOW}Please configure your .env file with the appropriate credentials.${NC}"
}

# Execute main function
main
