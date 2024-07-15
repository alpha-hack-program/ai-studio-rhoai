#!/bin/sh

# Load environment variables
. .env

# Check if namespace exists
if ! oc get namespace ${DATA_SCIENCE_PROJECT_NAMESPACE} > /dev/null 2>&1; then
  echo "Namespace ${DATA_SCIENCE_PROJECT_NAMESPACE} does not exist"
  exit 1
fi

# Check if .creds file exists and if not, exit with an error
if [ ! -f .creds ]; then
  echo "Please create a .creds file with the Hugging Face API key"
  exit 1
fi

# Load creds from .creds file
. .creds

# Check if AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_REGION and AWS_S3_BUCKET are set
if [ -z "${AWS_ACCESS_KEY_ID}" ] || [ -z "${AWS_SECRET_ACCESS_KEY}" ] || [ -z "${AWS_REGION}" ] || [ -z "${AWS_S3_BUCKET}" ]; then
  echo "Please set the AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_REGION and AWS_S3_BUCKET variables in the .creds file"
  exit 1
fi

# Check if MINIO_BUCKET, MINIO_ENDPOINT, MINIO_ACCESS_KEY, MINIO_SECRET_KEY and MINIO_REGION are set
if [ -z "${MINIO_BUCKET}" ] || [ -z "${MINIO_ENDPOINT}" ] || [ -z "${MINIO_ACCESS_KEY}" ] || [ -z "${MINIO_SECRET_KEY}" ] || [ -z "${MINIO_REGION}" ]; then
  echo "Please set the MINIO_BUCKET, MINIO_ENDPOINT, MINIO_ACCESS_KEY, MINIO_SECRET_KEY and MINIO_REGION variables in the .creds file"
  exit 1
fi

# Get DSPA_HOST from the ds-pipeline-dspa route which should be empty if no route is found
DSPA_HOST=$(oc get route ds-pipeline-dspa -n ${DATA_SCIENCE_PROJECT_NAMESPACE} -o jsonpath='{.spec.host}')

# Check if DSPA_HOST is set and if not, exit with an error
if [ -z "${DSPA_HOST}" ]; then
  echo "There was a problem when trying to get the DSPA_HOST"
  exit 1
fi

DSPA_URL=https://${DSPA_HOST}

# Set the EVALUATION_KIT_FILENAME, KFP_PIPELINE_NAMESPACE and KFP_PIPELINE_DISPLAY_NAME
EVALUATION_KIT_FILENAME=models/evaluation_kit.zip
KFP_PIPELINE_NAMESPACE=${DATA_SCIENCE_PROJECT_NAMESPACE}
KFP_PIPELINE_DISPLAY_NAME=deploy

# Create a secret called camel-s3-integration-creds in the namespace ${DATA_SCIENCE_PROJECT_NAMESPACE}
kubectl delete secret camel-s3-integration-creds -n ${DATA_SCIENCE_PROJECT_NAMESPACE} > /dev/null 2>&1
kubectl create secret generic camel-s3-integration-creds \
  --from-literal=AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID} \
  --from-literal=AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY} \
  --from-literal=AWS_REGION=${AWS_REGION} \
  --from-literal=AWS_S3_BUCKET=${AWS_S3_BUCKET} \
  --from-literal=MINIO_BUCKET=${MINIO_BUCKET} \
  --from-literal=MINIO_ENDPOINT=${MINIO_ENDPOINT} \
  --from-literal=MINIO_ACCESS_KEY=${MINIO_ACCESS_KEY} \
  --from-literal=MINIO_SECRET_KEY=${MINIO_SECRET_KEY} \
  --from-literal=MINIO_REGION=${MINIO_REGION} \
  --from-literal=KFP_PIPELINE_DISPLAY_NAME=${KFP_PIPELINE_DISPLAY_NAME} \
  --from-literal=KFP_PIPELINE_NAMESPACE=${KFP_PIPELINE_NAMESPACE} \
  --from-literal=EVALUATION_KIT_FILENAME=${EVALUATION_KIT_FILENAME} \
  --from-literal=DSPA_URL=${DSPA_URL} \
  -n ${DATA_SCIENCE_PROJECT_NAMESPACE}

