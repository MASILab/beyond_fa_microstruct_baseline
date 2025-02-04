#!/bin/sh

# Source /etc/profile to load environment variables
. /etc/profile

# Activate the virtual environment
. /opt/.venv/bin/activate

# Run the main script with any arguments
echo $METRIC
exec /opt/run_metric.sh "$@"