#!/usr/bin/env python3

import os
import secrets
import string
from pathlib import Path

def generate_secure_token(length=32):
    """Generate a secure random token."""
    alphabet = string.ascii_letters + string.digits
    return ''.join(secrets.choice(alphabet) for _ in range(length))

def create_env_file():
    """Create or update the .env file with OpenCTI configuration."""
    env_path = Path('.env')
    
    # Default values
    default_config = {
        'OPENCTI_ADMIN_EMAIL': 'admin@opencti.io',
        'OPENCTI_ADMIN_PASSWORD': 'admin',
        'OPENCTI_ADMIN_TOKEN': generate_secure_token(),
        'MINIO_ROOT_USER': 'minio',
        'MINIO_ROOT_PASSWORD': 'minio',
        'RABBITMQ_DEFAULT_USER': 'opencti',
        'RABBITMQ_DEFAULT_PASS': 'opencti'
    }
    
    # Check if .env exists
    if env_path.exists():
        print("Found existing .env file")
        response = input("Do you want to overwrite it? (y/N): ").lower()
        if response != 'y':
            print("Keeping existing .env file")
            return
    
    # Get user input for configuration
    print("\nOpenCTI Environment Configuration")
    print("=================================")
    
    config = {}
    for key, default_value in default_config.items():
        if key == 'OPENCTI_ADMIN_TOKEN':
            # Always generate a new token
            config[key] = generate_secure_token()
            print(f"Generated new {key}: {config[key]}")
        else:
            user_input = input(f"Enter {key} [{default_value}]: ").strip()
            config[key] = user_input if user_input else default_value
    
    # Write configuration to .env file
    try:
        with open(env_path, 'w') as f:
            f.write("# OpenCTI Environment Configuration\n\n")
            for key, value in config.items():
                f.write(f"{key}={value}\n")
        print(f"\nSuccessfully created {env_path}")
        print("Please make sure to keep these credentials secure!")
    except Exception as e:
        print(f"Error creating .env file: {e}")

if __name__ == "__main__":
    create_env_file() 