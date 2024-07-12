#!/bin/bash

# Check if the namespace is provided
if [ -z "$1" ]; then
    echo "Please provide the namespace as an argument"
    exit 1
fi

NAMESPACE=$1

# Get all standard resources
echo "Standard Resources in namespace $NAMESPACE:"
kubectl get all -n $NAMESPACE

# Get all CRDs
# CRDS=$(kubectl get crds -o jsonpath='{.items[*].spec.names.plural}')
CRDS=$(kubectl get crds -o jsonpath='{range .items[?(@.spec.scope=="Namespaced")]}{.spec.names.plural}{" "}{end}')


echo "Custom Resource Definitions:"
for CRD in $CRDS; do
    echo "Resources of type $CRD in namespace $NAMESPACE:"
    kubectl get $CRD -n $NAMESPACE
done