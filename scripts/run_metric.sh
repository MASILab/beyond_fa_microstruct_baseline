#!/bin/bash
# Read dwi from /input/ and write metric to /output/
# METRIC is an environment variable

echo "Generating random vectors..."
echo "Listing /input..."
ls /input
echo "Listing /input/*..."
ls /input/*
echo "Listing /output..."
ls /output

output_dir="/output"
python generate_random_vector.py "${output_dir}/features-128.json"

