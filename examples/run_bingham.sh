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
TractSeg -i $dwi_path -o $tractseg_dir --raw_diffusion_input --bvals $bvals_path --bvecs $bvecs_path --keep_intermediate_files

# Run Bingham
bingham_dir="${output_dir}/bingham"
mkdir -p $bingham_dir

# Convert SH basis to scilpy/dipy basis
echo "Converting SH basis..."
scil_sh_convert.py $tractseg_dir/WM_FODs.nii.gz $bingham_dir/WM_FODs.nii.gz tournier07 descoteaux07

# Run Bingham fitting
echo "Running Bingham fitting..."
scil_fodf_to_bingham.py $bingham_dir/WM_FODs.nii.gz $bingham_dir/WM_Bingham.nii.gz --mask $tractseg_dir/nodif_brain_mask.nii.gz --processes 18 

# Get Bingham metrics
echo "Getting Bingham metrics..."
scil_bingham_metrics.py --out_fd $bingham_dir/fd.nii.gz --out_fs $bingham_dir/fs.nii.gz --out_ff $bingham_dir/ff.nii.gz --mask $tractseg_dir/nodif_brain_mask.nii.gz $bingham_dir/WM_Bingham.nii.gz --processes 18