#!/usr/bin/env python3

import argparse
import datetime
import logging
import os
import re
import sys
import requests
import typing
import urllib3


def check_required_env_vars() -> None:
  """
  Check if required environment variables are set.
  
  Returns:
    None: Exits with error code 1 if any required variables are missing
  """
  missing_vars = []
  for var in ['PFSENSE_IP', 'PFSENSE_USER', 'PFSENSE_PASS']:
    if not os.environ.get(var):
      missing_vars.append(var)
  
  if missing_vars:
    for var in missing_vars:
      logging.error(f"Must provide {var}")
    sys.exit(1)


def perform_backup() -> bool:
  """
  Perform the pfSense backup process.
  
  Returns:
    bool: True if backup was successful, False otherwise
  """
  # Get environment variables
  pfsense_ip = os.environ.get('PFSENSE_IP', '')
  pfsense_user = os.environ.get('PFSENSE_USER', '')
  pfsense_pass = os.environ.get('PFSENSE_PASS', '')
  pfsense_scheme = os.environ.get('PFSENSE_SCHEME', 'https')
  backup_rrd = os.environ.get('PFSENSE_BACK_UP_RRD_DATA', '1')
  backup_dir = os.environ.get('PFSENSE_BACKUP_DESTINATION_DIR', '/data')
  
  logging.info("Starting pfSense backup")
  url = f"{pfsense_scheme}://{pfsense_ip}"
  timestamp = datetime.datetime.now().strftime("%Y%m%d%H%M%S")
  backup_file = f"{backup_dir}/config-{pfsense_ip}-{timestamp}.xml"
  # Disable warnings for self-signed certificates
  urllib3.disable_warnings()
  
  session = requests.Session()
  session.verify = False
  
  try:
    # Get initial CSRF token
    response = session.get(f"{url}/diag_backup.php")
    csrf_match = re.search(r'name=\'__csrf_magic\'\s+value="(.*?)"', response.text)
    if not csrf_match:
      logging.error("Could not find CSRF token")
      return False
    csrf_token = csrf_match.group(1)
    
    # Login
    login_data = {
      'login': 'Login',
      'usernamefld': pfsense_user,
      'passwordfld': pfsense_pass,
      '__csrf_magic': csrf_token
    }
    response = session.post(f"{url}/diag_backup.php", data=login_data)
    
    # Get new CSRF token after login
    csrf_match = re.search(r'name=\'__csrf_magic\'\s+value="(.*?)"', response.text)
    if not csrf_match:
      logging.error("Login failed or could not find CSRF token after login")
      return False
    csrf_token = csrf_match.group(1)
    
    # Download backup
    download_data = {
      'download': 'download',
      '__csrf_magic': csrf_token
    }
    
    # Add RRD option if requested
    if backup_rrd == '0':
      download_data['donotbackuprrd'] = 'yes'
    
    response = session.post(f"{url}/diag_backup.php", data=download_data, stream=True)
    
    if response.status_code == 200:
      # Ensure directory exists
      os.makedirs(backup_dir, exist_ok=True)
      
      with open(backup_file, 'wb') as f:
        for chunk in response.iter_content(chunk_size=8192):
          f.write(chunk)
      logging.info(f"Backup saved as {backup_file}")
      return True
    else:
      logging.error(f"Backup failed with status code {response.status_code}")
      return False
        
  except Exception as e:
    logging.error(f"Backup failed: {str(e)}")
    return False


def main() -> None:
  """Run the program."""

  parser = argparse.ArgumentParser(description="Run a thing.")

  script_args = parser.parse_args()

  # Configure logging.
  log_level = logging.INFO
  #log_level = logging.DEBUG
  log_format = "%(asctime)s - %(levelname)s - %(message)s"
  logging.basicConfig(stream=sys.stdout, format=log_format, level=log_level)
  check_required_env_vars()
  success: bool = perform_backup()
  sys.exit(0 if success else 1)


if __name__ == "__main__":
  main()
