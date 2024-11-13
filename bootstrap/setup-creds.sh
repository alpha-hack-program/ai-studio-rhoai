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

# Check if namespace exists
if ! oc get namespace ${DATA_SCIENCE_PROJECT_NAMESPACE} > /dev/null 2>&1; then
  echo "Namespace ${DATA_SCIENCE_PROJECT_NAMESPACE} does not exist"
  exit 1
fi

# Check if .creds file exists and if not, exit with an error
if [ ! -f .creds ]; then
  echo "Please create a .creds file with the S3 and/or GS credentials"
  exit 1
fi

# Load creds from .creds file
. .creds

# If S3 is true, then check if AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_REGION and AWS_S3_BUCKET are set
if [ "${S3}" = true ]; then
  if [ -z "${AWS_ACCESS_KEY_ID}" ] || [ -z "${AWS_SECRET_ACCESS_KEY}" ] || [ -z "${AWS_REGION}" ] || [ -z "${AWS_S3_BUCKET}" ]; then
    echo "Please set the AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_REGION and AWS_S3_BUCKET variables in the .creds file"
    exit 1
  fi
fi

# If GS is true, then check if GS_SERVICE_ACCOUNT_KEY is set
if [ "${GS}" = true ]; then
  if [ -z "${GS_SERVICE_ACCOUNT_KEY}" ]; then
    echo "Please set the GS_SERVICE_ACCOUNT_KEY variable in the .creds file"
    exit 1
  fi
  # Check if the GS_SERVICE_ACCOUNT_KEY file exists and if not, exit with an error
  if [ ! -f ${GS_SERVICE_ACCOUNT_KEY} ]; then
    echo "The file ${GS_SERVICE_ACCOUNT_KEY} does not exist"
    exit 1
  fi
fi

# Check if MINIO_NAMESPACE, MINIO_BUCKET, MINIO_ACCESS_KEY, MINIO_SECRET_KEY and MINIO_REGION are set
if [ -z "${MINIO_NAMESPACE}" ] || [ -z "${MINIO_BUCKET}" ] || [ -z "${MINIO_ACCESS_KEY}" ] || [ -z "${MINIO_SECRET_KEY}" ] || [ -z "${MINIO_REGION}" ]; then
  echo "Please set the MINIO_NAMESPACE, MINIO_BUCKET, MINIO_ACCESS_KEY, MINIO_SECRET_KEY, and MINIO_REGION variables in the .creds file"
  exit 1
fi

# Get the MINIO_ENDPOINT from the minio-service route which should be empty if no route is found
MINIO_ENDPOINT=$(oc get route minio-s3 -n ${MINIO_NAMESPACE} -o jsonpath='{.spec.host}')

# Check if MINIO_ENDPOINT is set and if not, exit with an error
if [ -z "${MINIO_ENDPOINT}" ]; then
  echo "There was a problem when trying to get the MINIO_ENDPOINT"
  exit 1
fi

# Get DSPA_HOST from the ds-pipeline-dspa route which should be empty if no route is found
DSPA_HOST=$(oc get route ds-pipeline-dspa -n ${DATA_SCIENCE_PROJECT_NAMESPACE} -o jsonpath='{.spec.host}')

# Check if DSPA_HOST is set and if not, exit with an error
if [ -z "${DSPA_HOST}" ]; then
  echo "There was a problem when trying to get the DSPA_HOST"
  exit 1
fi

# Set DSPA_URL to https://${DSPA_HOST}
DSPA_URL=https://${DSPA_HOST}

# Check if EVALUATION_KIT_FILENAME and KFP_PIPELINE_DISPLAY_NAME are set
if [ -z "${EVALUATION_KIT_FILENAME}" ] || [ -z "${KFP_PIPELINE_DISPLAY_NAME}" ]; then
  echo "Please set the EVALUATION_KIT_FILENAME and KFP_PIPELINE_DISPLAY_NAME variables in the .creds file"
  exit 1
fi

# Set KFP_PIPELINE_NAMESPACE to the same value as DATA_SCIENCE_PROJECT_NAMESPACE
KFP_PIPELINE_NAMESPACE=${DATA_SCIENCE_PROJECT_NAMESPACE}

# If S3 is true, then create a secret called camel-s3-integration-creds in the namespace ${DATA_SCIENCE_PROJECT_NAMESPACE}
if [ "${S3}" = true ]; then
  oc delete secret camel-s3-integration-creds -n ${DATA_SCIENCE_PROJECT_NAMESPACE} > /dev/null 2>&1
  oc create secret generic camel-s3-integration-creds \
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
fi

# If GS is true, then create a secret called camel-gs-integration-creds in the namespace ${DATA_SCIENCE_PROJECT_NAMESPACE}
if [ "${GS}" = true ]; then
  # Create a secret called camel-gs-service-account-key in the namespace ${DATA_SCIENCE_PROJECT_NAMESPACE}
  # with the GS_SERVICE_ACCOUNT_KEY file
  oc delete secret camel-gs-service-account-key -n ${DATA_SCIENCE_PROJECT_NAMESPACE} > /dev/null 2>&1
  oc create secret generic camel-gs-service-account-key \
    --from-file=GS_SERVICE_ACCOUNT_KEY=${GS_SERVICE_ACCOUNT_KEY} \
    -n ${DATA_SCIENCE_PROJECT_NAMESPACE}

  # Delete the secret if it exists then create it
  oc delete secret camel-gs-integration-creds -n ${DATA_SCIENCE_PROJECT_NAMESPACE} > /dev/null 2>&1
  oc create secret generic camel-gs-integration-creds \
    --from-literal=GS_SERVICE_ACCOUNT_KEY=file:///gs/service-account-key.json \
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
fi
