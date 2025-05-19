#!/usr/bin/env python3

import os
import uuid
import argparse
from pathlib import Path

def generate_uuid():
    """Generate a UUID for OpenCTI configuration."""
    return str(uuid.uuid4())

def create_env_file(output_path: str, custom_values: dict = None):
    """Create the OpenCTI environment configuration file."""
    # Default values
    env_config = {
        "OPENCTI_ADMIN_EMAIL": "admin@opencti.io",
        "OPENCTI_ADMIN_PASSWORD": "ChangeMePlease",
        "OPENCTI_ADMIN_TOKEN": generate_uuid(),
        "OPENCTI_BASE_URL": "http://localhost:8080",
        "OPENCTI_HEALTHCHECK_ACCESS_KEY": generate_uuid(),
        "MINIO_ROOT_USER": generate_uuid(),
        "MINIO_ROOT_PASSWORD": generate_uuid(),
        "RABBITMQ_DEFAULT_USER": "guest",
        "RABBITMQ_DEFAULT_PASS": "guest",
        "ELASTIC_MEMORY_SIZE": "4G",
        "CONNECTOR_HISTORY_ID": generate_uuid(),
        "CONNECTOR_EXPORT_FILE_STIX_ID": generate_uuid(),
        "CONNECTOR_EXPORT_FILE_CSV_ID": generate_uuid(),
        "CONNECTOR_IMPORT_FILE_STIX_ID": generate_uuid(),
        "CONNECTOR_EXPORT_FILE_TXT_ID": generate_uuid(),
        "CONNECTOR_IMPORT_DOCUMENT_ID": generate_uuid(),
        "CONNECTOR_ANALYSIS_ID": generate_uuid(),
        "SMTP_HOSTNAME": "localhost"
    }

    # Update with custom values if provided
    if custom_values:
        env_config.update(custom_values)

    # Create the output directory if it doesn't exist
    output_dir = os.path.dirname(output_path)
    if output_dir and not os.path.exists(output_dir):
        os.makedirs(output_dir)

    # Write the environment file
    with open(output_path, 'w') as f:
        for key, value in env_config.items():
            f.write(f"{key}={value}\n")

    print(f"Environment configuration file created at: {output_path}")
    print("\nImportant: Please review and modify the following values:")
    print("- OPENCTI_ADMIN_PASSWORD: Change the default password")
    print("- OPENCTI_BASE_URL: Update if your setup uses a different URL")
    print("- SMTP_HOSTNAME: Update with your SMTP server details if needed")

def main():
    parser = argparse.ArgumentParser(description="OpenCTI Environment Configuration Generator")
    parser.add_argument("--output", "-o", default=".env",
                      help="Output path for the environment file (default: .env)")
    parser.add_argument("--email", help="Admin email address")
    parser.add_argument("--password", help="Admin password")
    parser.add_argument("--base-url", help="Base URL for OpenCTI")
    parser.add_argument("--elastic-memory", default="4G",
                      help="Elasticsearch memory size (default: 4G)")
    
    args = parser.parse_args()

    # Prepare custom values from arguments
    custom_values = {}
    if args.email:
        custom_values["OPENCTI_ADMIN_EMAIL"] = args.email
    if args.password:
        custom_values["OPENCTI_ADMIN_PASSWORD"] = args.password
    if args.base_url:
        custom_values["OPENCTI_BASE_URL"] = args.base_url
    if args.elastic_memory:
        custom_values["ELASTIC_MEMORY_SIZE"] = args.elastic_memory

    create_env_file(args.output, custom_values)

if __name__ == "__main__":
    main() 