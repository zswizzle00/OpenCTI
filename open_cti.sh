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
NODE_MEMORY="4096"  # Platform memory 4GB
ES_MEMORY="2g"     # ElasticSearch memory 2GB
REDIS_MEMORY="2g"  # Redis memory 2GB

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

# Function to configure system settings
configure_system() {
    log_message "${YELLOW}Configuring system settings...${NC}"
    
    # Set vm.max_map_count for ElasticSearch
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
        fallocate -l 4G /swapfile
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
    apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release git python3 python3-pip build-essential libssl-dev libffi-dev python3-dev >> "$LOG_FILE" 2>&1
    
    # Install Java
    log_message "${YELLOW}Installing Java...${NC}"
    
    # Check if Java is already installed
    if ! command_exists java; then
        # Add OpenJDK repository
        apt-get install -y openjdk-11-jdk >> "$LOG_FILE" 2>&1 || { log_message "${RED}Failed to install Java${NC}"; exit 1; }
        
        # Set JAVA_HOME
        export JAVA_HOME=$(readlink -f /usr/bin/java | sed "s:/bin/java::")
        echo "JAVA_HOME=$JAVA_HOME" >> /etc/environment
        
        # Verify Java installation
        java_version=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}')
        if [ -z "$java_version" ]; then
            log_message "${RED}Java installation failed${NC}"
            exit 1
        else
            log_message "${GREEN}Java version $java_version installed successfully${NC}"
        fi
    else
        log_message "${GREEN}Java is already installed${NC}"
        java_version=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}')
        log_message "${GREEN}Java version: $java_version${NC}"
    fi
    
    # Verify Java memory settings
    log_message "${YELLOW}Verifying Java memory settings...${NC}"
    if [ -z "$JAVA_HOME" ]; then
        export JAVA_HOME=$(readlink -f /usr/bin/java | sed "s:/bin/java::")
    fi
    
    # Check if JAVA_OPTS is set
    if ! grep -q "JAVA_OPTS" /etc/environment; then
        echo "JAVA_OPTS=\"-Xms${ES_MEMORY} -Xmx${ES_MEMORY}\"" >> /etc/environment
    fi
    
    # Reload environment
    source /etc/environment
    
    # Verify Java can allocate the required memory
    log_message "${YELLOW}Testing Java memory allocation...${NC}"
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
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
        apt-get update >> "$LOG_FILE" 2>&1 || { log_message "${RED}Failed to update Docker package list${NC}"; exit 1; }
        apt-get install -y docker-ce docker-ce-cli containerd.io >> "$LOG_FILE" 2>&1 || { log_message "${RED}Failed to install Docker${NC}"; exit 1; }
        systemctl enable docker
        systemctl start docker
    fi
}

# Install Docker Compose
install_docker_compose() {
    if ! command_exists docker-compose; then
        log_message "${YELLOW}Installing Docker Compose...${NC}"
        curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        chmod +x /usr/local/bin/docker-compose
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
    cat > "$INSTALL_DIR/opencti/.env" << EOL
# OpenCTI Configuration
OPENCTI_ADMIN_EMAIL=admin@opencti.io
OPENCTI_ADMIN_PASSWORD=$(generate_password)
OPENCTI_ADMIN_TOKEN=$(generate_password)
OPENCTI_BASE_URL=http://localhost:8080
NODE_OPTIONS=--max-old-space-size=${NODE_MEMORY}

# RabbitMQ Configuration
RABBITMQ_DEFAULT_USER=opencti
RABBITMQ_DEFAULT_PASS=$(generate_password)
RABBITMQ_MAX_MESSAGE_SIZE=536870912
RABBITMQ_CONSUMER_TIMEOUT=86400000

# Redis Configuration
REDIS_PASSWORD=$(generate_password)
REDIS_MEMORY_LIMIT=${REDIS_MEMORY}

# Elasticsearch Configuration
ELASTICSEARCH_URL=http://elasticsearch:9200
ELASTICSEARCH_USERNAME=elastic
ELASTICSEARCH_PASSWORD=$(generate_password)
ES_JAVA_OPTS=-Xms${ES_MEMORY} -Xmx${ES_MEMORY}
ELASTICSEARCH_THREAD_POOL_SEARCH_QUEUE_SIZE=5000

# MinIO Configuration
MINIO_ROOT_USER=opencti
MINIO_ROOT_PASSWORD=$(generate_password)
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
    
    # Adjust memory allocations based on available system memory
    if [ "$total_mem" -lt 16384 ]; then  # Less than 16GB
        NODE_MEMORY="3072"  # 3GB
        ES_MEMORY="2g"     # 2GB
        REDIS_MEMORY="1g"  # 1GB
        log_message "${YELLOW}Limited memory mode: Adjusting service memory allocations${NC}"
    elif [ "$total_mem" -lt 32768 ]; then  # Less than 32GB
        NODE_MEMORY="4096"  # 4GB
        ES_MEMORY="4g"     # 4GB
        REDIS_MEMORY="2g"  # 2GB
        log_message "${YELLOW}Standard memory mode: Using default allocations${NC}"
    else  # 32GB or more
        NODE_MEMORY="8192"  # 8GB
        ES_MEMORY="8g"     # 8GB
        REDIS_MEMORY="4g"  # 4GB
        log_message "${GREEN}High memory mode: Using increased allocations${NC}"
    fi
    
    # Verify Java can handle the allocated memory
    if ! java -Xms${ES_MEMORY} -Xmx${ES_MEMORY} -version 2>&1 >/dev/null; then
        log_message "${RED}Java cannot handle the allocated Elasticsearch memory${NC}"
        log_message "${YELLOW}Reducing Elasticsearch memory allocation${NC}"
        ES_MEMORY="2g"  # Fallback to 2GB
        if ! java -Xms${ES_MEMORY} -Xmx${ES_MEMORY} -version 2>&1 >/dev/null; then
            log_message "${RED}Java cannot handle even the minimum memory allocation${NC}"
            exit 1
        fi
    fi
}

# Create docker-compose.yml with memory limits
create_docker_compose() {
    log_message "${YELLOW}Creating docker-compose.yml with memory limits...${NC}"
    cat > "$INSTALL_DIR/opencti/docker-compose.yml" << EOL
version: '3'
services:
  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:7.17.0
    ports:
      - "9200:9200"
    environment:
      - discovery.type=single-node
      - ES_JAVA_OPTS=-Xms${ES_MEMORY} -Xmx${ES_MEMORY}
      - thread_pool.search.queue_size=5000
      - xpack.security.enabled=false
      - cluster.name=opencti
      - http.host=0.0.0.0
      - transport.host=0.0.0.0
      - bootstrap.memory_lock=true
      - action.destructive_requires_name=true
      - indices.query.bool.max_clause_count=1024
      - indices.memory.index_buffer_size=10%
      - indices.breaker.total.limit=50%
      - indices.breaker.fielddata.limit=40%
      - indices.breaker.request.limit=40%
      - indices.breaker.total.use_real_memory=false
      - node.name=opencti-es
      - cluster.initial_master_nodes=opencti-es
      - network.host=0.0.0.0
      - http.cors.enabled=true
      - http.cors.allow-origin=*
      - http.cors.allow-headers=X-Requested-With,X-Auth-Token,Content-Type,Content-Length,Authorization
      - http.cors.allow-credentials=true
      - path.repo=/usr/share/elasticsearch/data/backup
      - discovery.seed_hosts=opencti-es
      - cluster.routing.allocation.disk.threshold_enabled=false
    deploy:
      resources:
        limits:
          memory: ${ES_MEMORY}
        reservations:
          memory: ${ES_MEMORY}
    ulimits:
      memlock:
        soft: -1
        hard: -1
      nofile:
        soft: 65536
        hard: 65536
    volumes:
      - esdata:/usr/share/elasticsearch/data
    healthcheck:
      test: ["CMD-SHELL", "curl -s http://localhost:9200/_cluster/health | grep -q '\"status\":\"green\\|yellow\"'"]
      interval: 30s
      timeout: 20s
      retries: 10
      start_period: 60s
    restart: unless-stopped
    networks:
      - opencti_network

  redis:
    image: redis:6.2
    ports:
      - "6379:6379"
    command: redis-server --maxmemory ${REDIS_MEMORY} --maxmemory-policy allkeys-lru
    deploy:
      resources:
        limits:
          memory: ${REDIS_MEMORY}
        reservations:
          memory: 512m
    volumes:
      - redisdata:/data
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 30s
      timeout: 10s
      retries: 5

  opencti:
    image: opencti/platform:latest
    environment:
      - NODE_OPTIONS=--max-old-space-size=${NODE_MEMORY}
      - OPENCTI_URL=http://localhost:8080
      - OPENCTI_ADMIN_EMAIL=admin@opencti.io
      - OPENCTI_ADMIN_PASSWORD=\${OPENCTI_ADMIN_PASSWORD}
      - OPENCTI_ADMIN_TOKEN=\${OPENCTI_ADMIN_TOKEN}
      - ELASTIC_URL=http://elasticsearch:9200
      - REDIS_URL=redis://redis:6379
      - REDIS_PASSWORD=\${REDIS_PASSWORD}
      - RABBITMQ_URL=amqp://rabbitmq:5672
      - RABBITMQ_USERNAME=opencti
      - RABBITMQ_PASSWORD=\${RABBITMQ_DEFAULT_PASS}
      - MINIO_URL=http://minio:9000
      - MINIO_ACCESS_KEY=\${MINIO_ROOT_USER}
      - MINIO_SECRET_KEY=\${MINIO_ROOT_PASSWORD}
    ports:
      - "8080:8080"
    deploy:
      resources:
        limits:
          memory: ${NODE_MEMORY}M
        reservations:
          memory: 1024M
    depends_on:
      elasticsearch:
        condition: service_healthy
      redis:
        condition: service_healthy
      rabbitmq:
        condition: service_healthy
      minio:
        condition: service_started

  worker:
    image: opencti/worker:latest
    environment:
      - OPENCTI_URL=http://opencti:8080
      - OPENCTI_TOKEN=\${OPENCTI_ADMIN_TOKEN}
      - WORKER_LOG_LEVEL=info
    deploy:
      resources:
        limits:
          memory: 768M
        reservations:
          memory: 512M
    depends_on:
      opencti:
        condition: service_started

  minio:
    image: minio/minio
    ports:
      - "9000:9000"
    command: server /data
    environment:
      - MINIO_ROOT_USER=\${MINIO_ROOT_USER}
      - MINIO_ROOT_PASSWORD=\${MINIO_ROOT_PASSWORD}
    volumes:
      - s3data:/data
    deploy:
      resources:
        limits:
          memory: 512M
        reservations:
          memory: 256M
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:9000/minio/health/live"]
      interval: 30s
      timeout: 10s
      retries: 5

  rabbitmq:
    image: rabbitmq:3.9-management
    ports:
      - "5672:5672"
      - "15672:15672"
    environment:
      - RABBITMQ_DEFAULT_USER=opencti
      - RABBITMQ_DEFAULT_PASS=\${RABBITMQ_DEFAULT_PASS}
      - RABBITMQ_MAX_MESSAGE_SIZE=536870912
      - RABBITMQ_CONSUMER_TIMEOUT=86400000
    volumes:
      - amqpdata:/var/lib/rabbitmq
    deploy:
      resources:
        limits:
          memory: 1G
        reservations:
          memory: 512M
    healthcheck:
      test: ["CMD", "rabbitmq-diagnostics", "-q", "ping"]
      interval: 30s
      timeout: 10s
      retries: 5

volumes:
  esdata:
  redisdata:
  s3data:
  amqpdata:

networks:
  opencti_network:
    driver: bridge
EOL
    log_message "${GREEN}docker-compose.yml created with memory limits${NC}"
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

    create_env_file
    create_docker_compose

    # Verify ports before starting
    verify_ports

    log_message "${YELLOW}Starting OpenCTI...${NC}"
    cd "$INSTALL_DIR/opencti"
    docker-compose up -d || { log_message "${RED}Failed to start OpenCTI${NC}"; exit 1; }

    # Check service health
    check_service_health

    log_message "${GREEN}OpenCTI installation completed!${NC}"
    log_message "${GREEN}OpenCTI is now accessible at: http://localhost:8080${NC}"
    log_message "${YELLOW}Default credentials:${NC}"
    log_message "Email: admin@opencti.io"
    log_message "Password: (Generated in the .env file)"
    log_message "${YELLOW}Please change these credentials after your first login!${NC}"
}

# Execute main function
main
