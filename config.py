import os
import json
import logging
from dotenv import load_dotenv

# Load .env file if present
load_dotenv()

logger = logging.getLogger(__name__)

def fetch_aws_secrets(secret_name, region_name="us-east-1"):
    """
    Fetch secrets dynamically from AWS Secrets Manager using boto3.
    This ensures ZERO hardcoded credentials in code or repository.
    """
    try:
        import boto3
        from botocore.exceptions import ClientError

        session = boto3.session.Session()
        client = session.client(
            service_name='secretsmanager',
            region_name=region_name
        )
        get_secret_value_response = client.get_secret_value(SecretId=secret_name)
        if 'SecretString' in get_secret_value_response:
            return json.loads(get_secret_value_response['SecretString'])
    except Exception as e:
        logger.warning(f"AWS Secrets Manager lookup skipped/failed: {e}")
    return {}

class Config:
    SECRET_KEY = os.environ.get('SECRET_KEY', 'default-dev-secret-key-change-in-prod')
    
    # Check if AWS Secrets Manager is specified
    AWS_SECRET_NAME = os.environ.get('AWS_SECRET_NAME')
    aws_secrets = {}
    if AWS_SECRET_NAME:
        aws_secrets = fetch_aws_secrets(AWS_SECRET_NAME)

    MYSQL_USER = aws_secrets.get('MYSQL_USER') or os.environ.get('MYSQL_USER', 'root')
    MYSQL_PASSWORD = aws_secrets.get('MYSQL_PASSWORD') or os.environ.get('MYSQL_PASSWORD', '')
    MYSQL_HOST = aws_secrets.get('MYSQL_HOST') or os.environ.get('MYSQL_HOST', 'localhost')
    MYSQL_PORT = aws_secrets.get('MYSQL_PORT') or os.environ.get('MYSQL_PORT', '3306')
    MYSQL_DB = aws_secrets.get('MYSQL_DB') or os.environ.get('MYSQL_DB', 'devops')

    # Construct Database URI securely
    if os.environ.get('USE_SQLITE', 'false').lower() == 'true' or not MYSQL_PASSWORD:
        SQLALCHEMY_DATABASE_URI = 'sqlite:///messages.db'
    else:
        SQLALCHEMY_DATABASE_URI = f"mysql+pymysql://{MYSQL_USER}:{MYSQL_PASSWORD}@{MYSQL_HOST}:{MYSQL_PORT}/{MYSQL_DB}"

    SQLALCHEMY_TRACK_MODIFICATIONS = False
    
    # Redis configuration
    REDIS_HOST = os.environ.get('REDIS_HOST', 'localhost')
    REDIS_PORT = int(os.environ.get('REDIS_PORT', 6379))
    
    # Security options
    RATELIMIT_DEFAULT = "100 per hour"
    RATELIMIT_STORAGE_URI = f"redis://{REDIS_HOST}:{REDIS_PORT}" if os.environ.get('USE_REDIS', 'false').lower() == 'true' else "memory://"
