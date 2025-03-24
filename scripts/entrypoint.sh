#!/bin/bash

# Source /etc/profile to load environment variables
. /etc/profile

# Activate the virtual environment
. /code/.venv/bin/activate

# Run the main script with any arguments
cd /code/scripts
exec ./run_metric.sh