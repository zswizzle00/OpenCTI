import os
from google.cloud import securitycenter
from google.cloud import logging
from dotenv import load_dotenv

def initialize_security_center():
    """
    Initialize the Google Cloud Security Center client.
    Returns:
        securitycenter.Client: Initialized Security Center client
    """
    load_dotenv()
    return securitycenter.SecurityCenterClient()

def initialize_logging():
    """
    Initialize the Google Cloud Logging client.
    Returns:
        logging.Client: Initialized Logging client
    """
    load_dotenv()
    return logging.Client()

def get_project_id():
    """
    Get the Google Cloud project ID from environment variables.
    Returns:
        str: Project ID
    """
    load_dotenv()
    project_id = os.getenv('GOOGLE_CLOUD_PROJECT')
    if not project_id:
        raise ValueError("GOOGLE_CLOUD_PROJECT environment variable not set")
    return project_id

def get_organization_id():
    """
    Get the Google Cloud organization ID from environment variables.
    Returns:
        str: Organization ID
    """
    load_dotenv()
    org_id = os.getenv('GOOGLE_CLOUD_ORGANIZATION')
    if not org_id:
        raise ValueError("GOOGLE_CLOUD_ORGANIZATION environment variable not set")
    return org_id 