# DOCS: https://www.kubeflow.org/docs/components/pipelines/user-guides/components/ 

import os

from kfp import local
from kfp.dsl import Input, Output, Dataset, Model, Metrics, OutputPath

from deploy import get_evaluation_kit, test_model, upload_model, pipeline

local.init(runner=local.SubprocessRunner())

os.environ['AWS_ACCESS_KEY_ID'] = 'minio'
os.environ['AWS_SECRET_ACCESS_KEY'] = 'minio123'
os.environ['AWS_DEFAULT_REGION'] = 'none'
os.environ['AWS_S3_ENDPOINT'] = 'https://minio-s3-ic-shared-minio.apps.cluster-pwkqj.sandbox2852.opentlc.com'
os.environ['AWS_S3_BUCKET'] = 'staging'
os.environ['EVALUATION_KIT_S3_KEY'] = 'models/evaluation_kit.zip'
os.environ['EVALUATION_DATA_ZIP_PATH'] = 'artifact/test_data.pkl'
os.environ['SCALER_ZIP_PATH'] = 'artifact/scaler.pkl'
os.environ['MODEL_ZIP_PATH'] = 'models/fraud/1/model.onnx'
os.environ['MODEL_S3_KEY'] = 'models/fraud/1/model.onnx'

evaluation_data_output_dataset = Dataset( name='evaluation_data_output_dataset',
                                             uri='/Users/cvicensa/Projects/openshift/alpha-hack-program/sagemaker-rhoai/pipeline/local_outputs/deploy-2024-06-26-11-18-35-229772/get-evaluation-kit/evaluation_data_output_dataset',
                                             metadata={} )
output_model= Model(name='output_model',
                    uri='/Users/cvicensa/Projects/openshift/alpha-hack-program/sagemaker-rhoai/pipeline/local_outputs/deploy-2024-06-26-11-18-35-229772/get-evaluation-kit/output_model',
                    metadata={} )
scaler_output_model = Model( name='scaler_output_model',
                                uri='/Users/cvicensa/Projects/openshift/alpha-hack-program/sagemaker-rhoai/pipeline/local_outputs/deploy-2024-06-26-11-18-35-229772/get-evaluation-kit/scaler_output_model',
                                metadata={} )

get_evaluation_kit_task = get_evaluation_kit()

# Test the model
test_model_task = test_model(
    evaluation_data_input_dataset=evaluation_data_output_dataset,
    scaler_input_model=scaler_output_model,
    model_input_model=output_model
)

# run pipeline
# pipeline_task = pipeline(accuracy_threshold=0.9, local=True)

