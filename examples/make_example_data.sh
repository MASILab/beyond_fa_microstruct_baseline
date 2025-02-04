prequal_dir="/nfs/masi/MASIver/data/production/MASiVar_PRODUCTION_v2.0.0/derivatives/prequal-v1.0.0"
subject="sub-cIVs001"
data_dir="${prequal_dir}/${subject}"

# grep for dwi that has b1000 and n40
dwi_paths=$(find $data_dir -name "*dwi.nii.gz" | grep "b1000n40")
output_dir="/fs5/p_masi/saundam1/outputs/beyond_fa/inputs"

for dwi_path in $dwi_paths; do
    bvals_path="${dwi_path%.nii.gz}.bval"
    bvecs_path="${dwi_path%.nii.gz}.bvec"
    session=$(basename $(dirname $(dirname $dwi_path)))
    mkdir -p $output_dir

    ln -s $dwi_path $output_dir
    ln -s $bvecs_path $output_dir
    ln -s $bvals_path $output_dir
done