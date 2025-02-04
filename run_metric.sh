#!/bin/bash

# Ensure at least the essential arguments are provided
if [ "$#" -lt 4 ]; then
    echo "Usage: $0 --metric <metric> <dwi_path> <bvals_path> <bvecs_path>"
    exit 1
fi

# Parse the --metric argument
metric=$1
shift  # Shift all arguments to the left, so the rest are positional arguments

# Positional arguments
dwi_path=$1
bvals_path=$2
bvecs_path=$3

# Define output directory
output_dir="/tmp/tractseg_fa_output"
mkdir -p $output_dir

# Run TractSeg
tractseg_dir="${output_dir}/tractseg"
mkdir -p $tractseg_dir
echo "Running TractSeg..."
TractSeg -i $dwi_path -o $tractseg_dir --raw_diffusion_input --bvals $bvals_path --bvecs $bvecs_path --keep_intermediate_files

# Run FA calculation
fa_dir="${output_dir}/fa"
mkdir -p $fa_dir
echo "Running FA..."
scil_dti_metrics.py --not_all --mask $tractseg_dir/nodif_brain_mask.nii.gz \
    --fa $fa_dir/fa.nii.gz --md $fa_dir/md.nii.gz --rd $fa_dir/rd.nii.gz \
    --ad $fa_dir/ad.nii.gz --ga $fa_dir/ga.nii.gz $dwi_path $bvals_path $bvecs_path -f

# Extract specified metric to JSON
echo "Extracting $metric metrics..."
python extract_metric.py $fa_dir/$metric.nii.gz $output_dir/$metric.json --metric $metric

# Output the final metric.json to stdout
echo "$metric metrics (json) output to stdout:"
cat $output_dir/$metric.json