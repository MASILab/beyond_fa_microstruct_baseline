import json
import argparse

def extract_metric_values(input_file, output_file):
    metric_values = []
    with open(input_file, 'r') as f:
        # Loop through lines
        for line in f:
            # Split line by comma
            bundle_name, value = line.strip().split(',')
            metric_values.append(float(value))

    # Zero pad to 128
    metric_values += [0] * (128 - len(metric_values))
    
    with open(output_file, 'w') as f:
        json.dump(metric_values, f, indent=4)
    
    print(f"Extracted values saved to {output_file}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Extract mean metric values from scilpy JSON file.")
    parser.add_argument("input_file", help="Path to input file bundle_name,value")
    parser.add_argument("output_file", help="Path to output file (list of mean metric values in ROIs)")
    
    args = parser.parse_args()
    extract_metric_values(args.input_file, args.output_file)
