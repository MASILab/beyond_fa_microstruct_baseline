#!/bin/bash
data_dir="/nfs/masi/MASIver/data/production/MASiVar_PRODUCTION_v2.0.0/derivatives/prequal-v1.0.0"
subject="sub-cIVs001"
session="ses-s1Bx2"

input_dir="${data_dir}/${subject}/${session}/dwi"
output_dir="/fs5/p_masi/saundam1/outputs/beyond_fa/${subject}/${session}"
dwi_path="${input_dir}/sub-cIVs001_ses-s1Bx2_acq-b1000n40r21x21x22peAPP_run-113_dwi.nii.gz"
bvecs_path="${input_dir}/sub-cIVs001_ses-s1Bx2_acq-b1000n40r21x21x22peAPP_run-113_dwi.bvec"
bvals_path="${input_dir}/sub-cIVs001_ses-s1Bx2_acq-b1000n40r21x21x22peAPP_run-113_dwi.bval"

# Run TractSeg
tractseg_dir="${output_dir}/tractseg"
mkdir -p $tractseg_dir

echo "Running TractSeg..."
# TractSeg -i $dwi_path -o $tractseg_dir --raw_diffusion_input --bvals $bvals_path --bvecs $bvecs_path --keep_intermediate_files

# Run FA
fa_dir="${output_dir}/fa"
mkdir -p $fa_dir

echo "Running FA..."
# scil_dti_metrics.py --not_all --mask $tractseg_dir/nodif_brain_mask.nii.gz --fa $fa_dir/fa.nii.gz --md $fa_dir/md.nii.gz --rd $fa_dir/rd.nii.gz --ad $fa_dir/ad.nii.gz --ga $fa_dir/ga.nii.gz $dwi_path $bvals_path $bvecs_path -f

# Get corresponding metrics
bundle_roi_dir="${tractseg_dir}/bundle_segmentations"
metric_dir=${fa_dir}

roi_list=$(find $bundle_roi_dir -name "*.nii.gz" | sort)
scil_volume_stats_in_ROI.py --metrics_dir ${fa_dir} $roi_list > $output_dir/tensor_metrics.json

# Extract metrics to json
echo "Extracting metrics to json..."
metric="fa"
python extract_metric.py $output_dir/tensor_metrics.json $output_dir/fa.json --metric $metric

echo "Done!"