Default Configuration
The script creates a .env file with the following default values (auto-generated securely when the script runs):

OpenCTI Configuration
OPENCTI_ADMIN_EMAIL: admin@opencti.io
OPENCTI_ADMIN_PASSWORD: Secure password
OPENCTI_ADMIN_TOKEN: Secure token
OPENCTI_BASE_URL: http://localhost:8080
RabbitMQ Configuration
RABBITMQ_DEFAULT_USER: opencti
RABBITMQ_DEFAULT_PASS: Secure password
Redis Configuration
REDIS_PASSWORD: Secure password
Elasticsearch Configuration
ELASTICSEARCH_URL: http://elasticsearch:9200
ELASTICSEARCH_USERNAME: elastic
ELASTICSEARCH_PASSWORD: Secure password
MinIO Configuration
MINIO_ROOT_USER: opencti
MINIO_ROOT_PASSWORD: Secure password
Logging
All actions are logged to /var/log/opencti_install.log.

Post-Installation
After running the script:

Wait a few minutes for all services to start.
Access OpenCTI at http://localhost:8080.
Log in using the default credentials:
Email: admin@opencti.io
Password: Auto-generated (check the .env file in the installation directory).
Important: Change the default credentials immediately after logging in.

Troubleshooting
Ensure you are running the script as root or with sudo.
Check the log file at /var/log/opencti_install.log for errors.
Verify that Docker and Docker Compose are installed and running correctly.
License
This script is open-source and distributed under the MIT License. See the LICENSE file for details.

For more information about OpenCTI, visit https://www.opencti.io/.
