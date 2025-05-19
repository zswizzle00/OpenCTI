# OpenCTI Installation Script

This repository contains a script to automate the installation and configuration of OpenCTI (Open Cyber Threat Intelligence Platform) using Docker.

## Prerequisites

- Linux-based operating system (Ubuntu/Debian recommended)
- Root or sudo privileges
- Internet connection
- At least 4GB of RAM
- At least 20GB of free disk space
- Docker Compose V2 or higher (the script will automatically upgrade if needed)

## Quick Start

1. Clone this repository:
```bash
git clone https://github.com/yourusername/opencti-install.git
cd opencti-install
```

2. Make the installation script executable:
```bash
chmod +x open_cti.sh
```

3. Run the installation script:
```bash
sudo ./open_cti.sh
```

## Installation Options

The script supports several command-line options:

```bash
Usage: ./open_cti.sh [options]
Options:
  -h, --help                 Show this help message and exit
  -d, --directory <path>     Specify the installation directory (default: /opt/opencti)
  -s, --skip-docker         Skip Docker and Docker Compose installation
  -e, --env-only            Only generate the .env file, skip installation steps
```

## What Gets Installed

The script will install and configure:

1. **Docker and Docker Compose** (unless skipped with -s)
   - Docker Compose V2 will be installed if an older version is detected
2. **OpenCTI Platform** (version 5.12.5)
3. **Required Services**:
   - Redis 6.2
   - Elasticsearch 7.17.9
   - MinIO (latest stable)
   - RabbitMQ 3.11

## Configuration

### Environment Variables

The script automatically generates a `.env` file with the following default settings:

- Admin Email: admin@opencti.io
- Admin Password: ChangeMePlease
- Base URL: http://localhost:8080
- All other required tokens and credentials are automatically generated

### Service Configurations

1. **Redis**:
   - Persistent storage enabled
   - Health checks configured

2. **Elasticsearch**:
   - Single node configuration
   - Memory settings optimized
   - Thread pool queue size increased
   - Security disabled for development

3. **MinIO**:
   - Console available on port 9001
   - Persistent storage configured

4. **RabbitMQ**:
   - Management interface enabled
   - Custom configuration for message size and timeouts
   - Health checks configured

## Accessing OpenCTI

After installation:

1. Open your browser and navigate to: http://localhost:8080
2. Login with the default credentials:
   - Email: admin@opencti.io
   - Password: ChangeMePlease

**Important**: Change the default password after your first login!

## Service Management

### Starting Services
```bash
cd /opt/opencti
docker-compose up -d
```

### Stopping Services
```bash
cd /opt/opencti
docker-compose down
```

### Viewing Logs
```bash
cd /opt/opencti
docker-compose logs -f
```

## Health Checks

All services include health checks that run every 30 seconds. You can monitor the health status using:

```bash
docker-compose ps
```

## Data Persistence

All data is stored in Docker volumes:
- `redis-data`: Redis data
- `elasticsearch-data`: Elasticsearch indices
- `minio-data`: MinIO object storage
- `rabbitmq-data`: RabbitMQ data
- `opencti-data`: OpenCTI application data

## Troubleshooting

### Common Issues

1. **Docker Compose Version Issues**:
   - If you see "ContainerConfig" errors, ensure you're using Docker Compose V2
   - The script will automatically upgrade Docker Compose if needed
   - Manual upgrade: `sudo curl -SL https://github.com/docker/compose/releases/download/v2.24.5/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose && sudo chmod +x /usr/local/bin/docker-compose`

2. **Elasticsearch fails to start**:
   - Check if `vm.max_map_count` is set correctly
   - Verify available memory
   - Check logs: `docker-compose logs elasticsearch`

3. **Services not starting**:
   - Check logs: `docker-compose logs`
   - Verify all ports are available
   - Check disk space
   - Ensure Docker daemon is running: `sudo systemctl status docker`

4. **Connection issues**:
   - Verify all services are running: `docker-compose ps`
   - Check service logs for specific errors
   - Ensure no firewall is blocking the ports

5. **Installation Directory Issues**:
   - If you get "destination path already exists" error, the script will now automatically clean the directory
   - To start fresh: `sudo rm -rf /opt/opencti/*` before running the script

### Logs Location

- Installation logs: `/var/log/opencti_install.log`
- Service logs: `docker-compose logs [service-name]`

## Security Considerations

1. Change all default passwords after installation
2. Configure proper firewall rules
3. Enable SSL/TLS for production use
4. Review and adjust security settings in Elasticsearch

## Upgrading

To upgrade OpenCTI:

1. Stop the services:
```bash
cd /opt/opencti
docker-compose down
```

2. Update the images in docker-compose.yml
3. Pull new images:
```bash
docker-compose pull
```

4. Start services:
```bash
docker-compose up -d
```

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request. 