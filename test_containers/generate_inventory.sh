#!/bin/bash

# Retrieve the public IPs from Terraform output
public_ips_example_1=$(terraform output -raw example_1_public_ips)
public_ips_example_2=$(terraform output -raw example_2_public_ips)

# Generate the Ansible inventory file in the desired format
echo "[example_1]"
for ip in $public_ips_example_1; do
    echo "${ip}"
done

echo "[example_2]"
for ip in $public_ips_example_2; do
    echo "${ip}"
done
