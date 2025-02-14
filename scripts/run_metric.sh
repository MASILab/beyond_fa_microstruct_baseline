#!/bin/bash
# Read dwi from inputs/ and write metric to outputs/
# Metric is read from environment variable METRIC

# Define metric
metric=${METRIC:-"fa"}

dwi_files=$(find /input -name "*dwi.nii.gz")

for dwi_file in $dwi_files; do
    dwi_path=$dwi_file
    bval_path="${dwi_path%.nii.gz}.bval"
    bvec_path="${dwi_path%.nii.gz}.bvec"
    basename=$(basename $dwi_path .nii.gz)
    output_name="/output/${basename}.json"

    echo $dwi_path
    echo $bval_path
    echo $bvec_path
    echo $output_name
    echo $metric

    # Define output directory
    output_dir="/tmp/tractseg_fa_output"
    mkdir -p $output_dir

    # Run TractSeg
    tractseg_dir="${output_dir}/${basename}/tractseg"
    mkdir -p $tractseg_dir
    echo "Running TractSeg..."
    TractSeg -i $dwi_path -o $tractseg_dir --raw_diffusion_input --bvals $bval_path --bvecs $bvec_path --keep_intermediate_files

    # Run FA calculation
    fa_dir="${output_dir}/${basename}/metric"
    mkdir -p $fa_dir
    echo "Calculating DTI metrics..."
    scil_dti_metrics.py --not_all --mask $tractseg_dir/nodif_brain_mask.nii.gz \
        --fa $fa_dir/fa.nii.gz --md $fa_dir/md.nii.gz --rd $fa_dir/rd.nii.gz \
        --ad $fa_dir/ad.nii.gz --ga $fa_dir/ga.nii.gz $dwi_path $bval_path $bvec_path -f

    # Get corresponding metrics
    echo "Extracting $metric metrics in bundles..."
    bundle_roi_dir="${tractseg_dir}/bundle_segmentations"
    metric_dir=${fa_dir}

    roi_list=$(find $bundle_roi_dir -name "*.nii.gz" | sort)
    scil_volume_stats_in_ROI.py --metrics_dir ${fa_dir} $roi_list > ${output_dir}/tensor_metrics.json

    # Extract specified metric to JSON
    python extract_metric.py ${output_dir}/tensor_metrics.json $output_dir/$metric.json --metric $metric

    # Save the final metric.json to output directory
    echo "$metric metrics saved to $output_name!"
    mv $output_dir/$metric.json $output_name
done