#!/bin/bash

# Read the input from Terraform output
input_file=$(terraform output public_ip)
output_file="inventory"

# Remove unnecessary characters from input and write to output file
echo "$input_file" | tr -d '["], ' > "$output_file"

echo "Extracted instances:"
cat "$output_file"

echo "Extraction complete. Output saved to $output_file."