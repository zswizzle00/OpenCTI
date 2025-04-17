# OpenCTI Installation Script

This script automates the installation and configuration of the OpenCTI platform, including all its dependencies and services.

## Features

- Automated installation of OpenCTI and all required components
- Automatic system configuration for optimal performance
- Memory management for all services
- Secure password and token generation
- Health monitoring and checks
- Docker and Docker Compose setup
- Preserves original configuration samples

## Prerequisites

- Linux-based operating system (Ubuntu recommended)
- Root or sudo access
- Minimum 10GB of RAM
- Internet connection
- Git

## Default Configuration

- Installation Directory: `/opt/opencti`
- Default Admin Password: `admin@123`
- Service Ports:
  - OpenCTI: 8080
  - Elasticsearch: 9200
  - Redis: 6379
  - MinIO: 9000
  - RabbitMQ: 5672, 15672

## Memory Configuration

- OpenCTI (NodeJS): 8GB
- Elasticsearch: 8GB
- Redis: 2GB

<<<<<<< HEAD
1. Clone the repository:
```bash
git clone <repository-url>
cd OpenCTI
```

2. Make the script executable:
```bash
chmod +x open_cti.sh
```

3. Run the installation script:
```bash
sudo ./open_cti.sh
```

### Optional Parameters

The script accepts several optional parameters:
=======
## Usage
>>>>>>> 441bd3c (Enhance open_cti.sh to automatically determine the VM's IP address for configuration. Update .env file generation with fixed default passwords and UUIDs for admin token and healthcheck access key. Preserve original .env.sample during creation and restore it if backed up. Update README.md to reflect changes in installation and configuration processes.)

```bash
sudo ./open_cti.sh [options]
```

### Options

- `-h, --help`: Show help message and exit
- `-d, --directory <path>`: Specify installation directory (default: /opt/opencti)
- `-s, --skip-docker`: Skip Docker and Docker Compose installation
- `-e, --env-only`: Only generate the .env file, skip installation steps
- `-n, --node-memory <size>`: Set NodeJS memory limit (default: 8G)
- `-m, --es-memory <size>`: Set ElasticSearch memory limit (default: 8G)
- `-r, --redis-memory <size>`: Set Redis memory limit (default: 2G)

### Examples

Basic installation:
```bash
sudo ./open_cti.sh
```

Custom installation directory:
```bash
sudo ./open_cti.sh -d /custom/path
```

Skip Docker installation (if already installed):
```bash
sudo ./open_cti.sh -s
```

Custom memory settings:
```bash
sudo ./open_cti.sh -n 4G -m 4G -r 1G
```

## Post-Installation

After installation:
1. Access OpenCTI at `http://<your-ip>:8080`
2. Login with:
   - Email: `admin@opencti.io`
   - Password: `admin@123`
3. Change the default password after first login

## Troubleshooting

### Common Issues

1. **Port Conflicts**
   - Ensure required ports (8080, 9200, 6379, 9000, 5672, 15672) are not in use
   - Check with `netstat -tuln | grep <port>`

2. **Memory Issues**
   - Verify system has sufficient RAM
   - Adjust memory settings if needed using the options

3. **Docker Issues**
   - Ensure Docker is running: `systemctl status docker`
   - Check Docker logs: `docker-compose logs`

### Logs

- Installation log: `/var/log/opencti_install.log`
- Docker logs: `docker-compose logs`
- OpenCTI logs: `docker-compose logs opencti`

## Security Notes

- Default passwords are set to `admin@123` for all services
- Admin token is automatically generated as a UUID
- Healthcheck access key is automatically generated as a UUID
- It is recommended to change all default passwords after installation

## Support

For issues and feature requests, please open an issue in the repository.

## License

This script is provided under the MIT License. 
