#!/bin/bash

# Check if the namespace and app name are provided
if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Please provide the namespace and app name as arguments"
    exit 1
fi

NAMESPACE=$1
APP_NAME=$2

# # Get all standard resources
echo "Exporting resources in namespace $NAMESPACE with app label $APP_NAME into exported_objects.yaml"
kubectl get deployment,service,configmap,secret,imagestream,buildconfig,route --namespace ${NAMESPACE} -l app=${APP_NAME} -o yaml > exported_objects.yaml


# File containing exported Kubernetes objects
input_file="exported_objects.yaml"
cleaned_file="cleaned_objects.yaml"

# Function to clean YAML objects
clean_yaml() {
  # yq eval '.items[] | del(.metadata.namespace) | del(.metadata.generation) | del(.metadata.resourceVersion) | del(.metadata.uid) | del(.status) | del(.metadata.managedFields) | del(.metadata.creationTimestamp) | "---" + (. | to_yaml)' "$1"
  # yq eval '.items[] | del(.metadata.namespace) | del(.metadata.generation) | del(.metadata.resourceVersion) | del(.metadata.uid) | del(.status) | del(.metadata.managedFields) | del(.metadata.creationTimestamp)' "$1"
  yq eval '.items[] | split_doc' "$1" | yq eval 'del(.metadata.namespace) | del(.metadata.generation) | del(.metadata.resourceVersion) | del(.metadata.uid) | del(.status) | del(.metadata.managedFields) | del(.metadata.creationTimestamp)'
  
}

# Process the exported file and clean it
echo "Cleaning resources in exported_objects.yaml and saving to cleaned_objects.yaml"
clean_yaml "$input_file" > "$cleaned_file"