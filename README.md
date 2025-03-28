# pfSense Backup Tool

A simple utility for automating backups of pfSense configurations.

## Overview

This tool connects to a pfSense instance via its web interface and creates XML backups of the configuration. It handles authentication, session management, and can optionally include RRD data in the backups.

## Features

- Automated backup of pfSense configurations
- Secure authentication with pfSense web interface
- Option to include or exclude RRD performance data
- Configurable backup destination directory
- Environment variable configuration

## Requirements

- Python 3.6+
- Required Python packages (see `requirements.txt`)

## Configuration

The tool uses environment variables for configuration:

| Variable | Description | Default |
|----------|-------------|---------|
| `PFSENSE_IP` | IP address of pfSense instance | Required |
| `PFSENSE_USER` | Admin username | Required |
| `PFSENSE_PASS` | Admin password | Required |
| `PFSENSE_SCHEME` | HTTP or HTTPS | https |
| `PFSENSE_BACK_UP_RRD_DATA` | Include RRD data (1=yes, 0=no) | 1 |
| `PFSENSE_BACKUP_DESTINATION_DIR` | Where to store backups | /data |

## Usage

### Setting Up a Virtual Environment

```bash
# Create a virtual environment
python -m venv venv

# Activate the virtual environment
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt
```

### Running the Backup

```bash
# Set required environment variables
export PFSENSE_IP="192.168.1.1"
export PFSENSE_USER="admin"
export PFSENSE_PASS="yourpassword"

# Run the backup
python run.py
```

## Building Container Image

This repository includes a Packer template (`pfsense-backup.pkr.hcl`) to build a container image:

```bash
# Initialize packer (first time only)
packer init pfsense-backup.pkr.hcl

# Build the image


```

## Running as a Container

After building the image, you can run it with:

```bash
docker run -e PFSENSE_IP=192.168.1.1 \
           -e PFSENSE_USER=admin \
           -e PFSENSE_PASS=yourpassword \
           -v /local/backup/path:/data \
           pfsense-backup
```
