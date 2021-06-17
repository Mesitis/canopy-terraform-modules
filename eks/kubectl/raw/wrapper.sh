#!/usr/bin/env bash
set -e

# Create a temporary file to store the CA Certificate
CA_FILE=$(mktemp)

# Cleanup function to delete file on exit
cleanup() {
  rm -f "$CA_FILE";
}

# Run the cleanup on exit
trap cleanup EXIT

# Write the certificate contents to the file
echo "$CA_CERTIFICATE" > "$CA_FILE"

# Call the kubectl command with the right arguments and passthrough all other arguments
kubectl --certificate-authority="$CA_FILE" --server="$KUBESERVER" --token="$KUBETOKEN" "$@"