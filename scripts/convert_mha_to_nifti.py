import SimpleITK as sitk
import sys

def convert_mha_to_nifti(mha_file, nifti_file):
    # Read the MHA file
    image = sitk.ReadImage(mha_file)
    # Write to NIfTI format
    sitk.WriteImage(image, nifti_file)

if __name__ == "__main__":
    # Get input and output filenames from arguments
    mha_file = sys.argv[1]
    nifti_file = sys.argv[2]
    convert_mha_to_nifti(mha_file, nifti_file)