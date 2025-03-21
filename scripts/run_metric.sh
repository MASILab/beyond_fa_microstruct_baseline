#!/bin/bash
# Read dwi from inputs/ and write metric to outputs/
# Metric is read from environment variable METRIC

echo "Running BeyondFA baseline..."
echo "Listing /input..."
ls /input
echo "Listing /input/*..."
ls /input/*
echo "Listing /output..."
ls /output/

# Define metric
metric="fa"

# Find all dwi.mha files in /input
dwi_mha_files=$(find /input/images/dwi-4d-brain-mri -name "*.mha")

for dwi_mha_file in $dwi_mha_files; do
    # Set up file names
    json_file="/input/dwi-4d-acquisition-metadata.json"

    basename=$(basename $dwi_mha_file .mha)
    bval_path="/tmp/${basename}.bval"
    bvec_path="/tmp/${basename}.bvec"
    nifti_file="/tmp/${basename}.nii.gz"
    output_name="/output/features-128.json"

    # Convert dwi.mha to nii.gz
    echo "Converting $dwi_mha_file to $nifti_file..."
    python convert_mha_to_nifti.py $dwi_mha_file $nifti_file

    # Convert json to bval and bvec
    echo "Converting $json_file to $bval_path and $bvec_path..."
    python convert_json_to_bvalbvec.py $json_file $bval_path $bvec_path

    # Define output directory
    output_dir="/tmp/tractseg_fa_output"
    mkdir -p $output_dir

    # Run TractSeg
    tractseg_dir="${output_dir}/${basename}/tractseg"
    mkdir -p $tractseg_dir
    echo "Running TractSeg..."
    TractSeg -i $nifti_file -o $tractseg_dir --raw_diffusion_input --bvals $bval_path --bvecs $bvec_path --keep_intermediate_files

    # Run FA calculation
    fa_dir="${output_dir}/${basename}/metric"
    mkdir -p $fa_dir
    echo "Calculating DTI metrics..."
    scil_dti_metrics.py --not_all --mask $tractseg_dir/nodif_brain_mask.nii.gz \
        --fa $fa_dir/fa.nii.gz $nifti_file $bval_path $bvec_path -f

    # Get corresponding metrics
    echo "Calculating average $metric metric in bundles..."
    bundle_roi_dir="${tractseg_dir}/bundle_segmentations"
    metric_dir=${fa_dir}

    # Make json with json["fa"]["mean"] = mena of fa in bundle
    roi_list=$(find $bundle_roi_dir -name "*.nii.gz" | sort)
    for roi in $roi_list; do
        bundle_name=$(basename $roi .nii.gz)
        echo "Calculating $metric in $bundle_name..."

        # Is sum of mask > 0?
        mask_sum=$(fslstats $roi -V | awk '{print $1}')
        if [ $mask_sum -eq 0 ]; then
            echo "$bundle_name,0" >> ${output_dir}/tensor_metrics.json
        else
            mean_metric=$(fslstats $fa_dir/$metric.nii.gz -k $roi -m)
            echo "$bundle_name,$mean_metric" >> ${output_dir}/tensor_metrics.json
        fi
    done
    # scil_volume_stats_in_ROI.py --metrics_dir ${fa_dir} $roi_list > ${output_dir}/tensor_metrics.json

    # Extract specified metric to JSON
    echo "Extracting $metric metrics to $output_dir..."
    python extract_metric.py ${output_dir}/tensor_metrics.json $output_dir/fa.json

    # Save the final metric.json to output directory
    echo "$metric metrics saved to $output_name!"
    mv $output_dir/fa.json $output_name

done
