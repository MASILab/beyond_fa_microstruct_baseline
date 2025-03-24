import numpy as np
import json
import argparse
import os

def generate_random_vector(output_file):
    # Get output directory and filename
    output_dir = os.path.dirname(output_file)
    filename = os.path.basename(output_file)
    print(f"Output directory: {output_dir}")
    print(f"Output filename: {filename}")
    
    # Ensure output directory exists
    os.makedirs(output_dir, exist_ok=True)
    
    # Generate a random vector of size 128x1 with values between 0 and 1
    random_vector = np.random.rand(128).tolist()
    
    # Save the vector to the output file
    with open(output_file, 'w') as f:
        json.dump(random_vector, f, indent=4)
    
    print(f"Random vector saved to {output_file}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Generate a random vector of size 128x1 with values between 0 and 1.")
    parser.add_argument("output_file", help="Path to output JSON file (random vector)")
    
    args = parser.parse_args()
    generate_random_vector(args.output_file)
