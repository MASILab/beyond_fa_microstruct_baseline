import json
import sys

def extract_bvals_bvecs(json_file, output_bval, output_bvec):
    with open(json_file, 'r') as f:
        data = json.load(f)

    # Initialize lists for bvals and bvecs
    bvals = [entry['BVAL'] for entry in data]
    bvecs = [entry['BVEC'] for entry in data]

    # Save bvals and bvecs to output files
    with open(output_bval, 'w') as bval_file:
        for bval in bvals:
            bval_file.write(f"{bval}\n")

    with open(output_bvec, 'w') as bvec_file:
        for bvec in bvecs:
            bvec_file.write(f"{' '.join(map(str, bvec))}\n")

if __name__ == "__main__":
    if len(sys.argv) != 4:
        print("Usage: python convert_json_to_bvalbvec.py <json_file> <output_bval> <output_bvec>")
        sys.exit(1)

    json_file = sys.argv[1]
    output_bval = sys.argv[2]
    output_bvec = sys.argv[3]

    extract_bvals_bvecs(json_file, output_bval, output_bvec)