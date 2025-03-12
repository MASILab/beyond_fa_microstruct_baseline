import json
import argparse

def extract_metric_values(input_file, output_file, metric):
    with open(input_file, 'r') as f:
        data = json.load(f)
    
    metric_values = [tract_info[metric]["mean"] for tract_info in data.values() if metric in tract_info]

    # Zero pad to 128
    #metric_values += [0] * (128 - len(metric_values))
    
    with open(output_file, 'w') as f:
        json.dump(metric_values, f, indent=4)
    
    print(f"Extracted {metric} values saved to {output_file}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Extract mean metric values from scilpy JSON file.")
    parser.add_argument("input_file", help="Path to input JSON file from scil_volume_stats_in_ROI.py")
    parser.add_argument("output_file", help="Path to output JSON file (list of mean metric values in ROIs)")
    parser.add_argument("--metric", required=True, help="Metric to extract (e.g., fa, rd, md)")
    
    args = parser.parse_args()
    extract_metric_values(args.input_file, args.output_file, args.metric)
