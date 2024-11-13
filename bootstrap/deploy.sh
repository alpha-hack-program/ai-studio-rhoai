#!/bin/sh

# Load environment variables
. .env

# Arguments: --s3, --gs
S3=false
GS=false
while [ "$1" != "" ]; do
  case $1 in
    --s3 )
      S3=true
      ;;
    --gs )
      GS=true
      ;;
    * )
      echo "Invalid argument: $1"
      exit 1
  esac
  shift
done

# Either --s3 or --gs must be set
if [ "$S3" = false ] && [ "$GS" = false ]; then
  echo "Either --s3 or --gs must be set"
  exit 1
fi

# Create an ArgoCD application to deploy the helm chart at this repository and path ./gitops/fraud-detection
cat <<EOF | kubectl apply -f -
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: ${INSTANCE_NAME}
  namespace: openshift-gitops
  annotations:
    argocd.argoproj.io/compare-options: IgnoreExtraneous
spec:
  project: default
  destination:
    server: 'https://kubernetes.default.svc'
    namespace: ${DATA_SCIENCE_PROJECT_NAMESPACE}
  source:
    path: gitops/fraud-detection
    repoURL: ${REPO_URL}
    targetRevision: main
    helm:
      parameters:
        - name: instanceName
          value: "${INSTANCE_NAME}"
        - name: dataScienceProjectDisplayName
          value: "Project ${DATA_SCIENCE_PROJECT_NAMESPACE}"
        - name: dataScienceProjectNamespace
          value: "${DATA_SCIENCE_PROJECT_NAMESPACE}"
        - name: integrations.gs
          value: "${GS}"
        - name: integrations.s3
          value: "${S3}"
  syncPolicy:
    automated:
      # prune: true
      selfHeal: true
EOF

# Wait for the project to be created
while ! oc get project ${DATA_SCIENCE_PROJECT_NAMESPACE} > /dev/null 2>&1; do
  echo "Waiting for project ${DATA_SCIENCE_PROJECT_NAMESPACE} to be created"
  sleep 5
done

# Project created
echo "Project ${DATA_SCIENCE_PROJECT_NAMESPACE} created"

# Set up credentials
if [ "$S3" = true ]; then
  S3_FLAG="--s3"
fi
if [ "$GS" = true ]; then
  GS_FLAG="--gs"
fi
./setup-creds.sh ${S3_FLAG} ${GS_FLAG}