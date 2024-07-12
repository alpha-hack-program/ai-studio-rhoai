package com.redhat.docbot;

import java.util.Optional;

import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.ws.rs.core.Response;
import org.apache.camel.LoggingLevel;
import org.apache.camel.builder.RouteBuilder;
import org.apache.camel.component.aws2.s3.AWS2S3Constants;
import org.apache.camel.component.minio.MinioConstants;

import org.eclipse.microprofile.config.inject.ConfigProperty;
import org.eclipse.microprofile.rest.client.inject.RestClient;

@ApplicationScoped 
public class S3EventListener extends RouteBuilder {

    @ConfigProperty(name = "bucket.name")
    String bucketName;

    @ConfigProperty(name = "kfp.pipeline.namespace")
    String kfpNamespace;

    @ConfigProperty(name = "kfp.pipeline.display-name")
    String pipelineDisplayName;

    @ConfigProperty(name = "evaluation-kit.filename")
    String evaluationKitFilename;

    @Inject
    @RestClient
    KubeflowPipelineClient kfpClient;

    @Override
    public void configure() throws Exception {
        from("aws2-s3://{{bucket.name}}?deleteAfterRead=false")
            .routeId("s3-event-listener")
            .log(LoggingLevel.DEBUG, "Received S3 event: ${header.CamelAwsS3EventType}")            
            .filter(header(AWS2S3Constants.KEY).endsWith(evaluationKitFilename))
            .setHeader(MinioConstants.OBJECT_NAME, simple("${header.CamelAwsS3Key}")) 
            .log("Processing file: ${header.CamelMinioObjectName}")
            .to("minio://{{minio.bucket-name}}?accessKey={{minio.access-key}}&secretKey={{minio.secret-key}}&region={{minio.region}}&endpoint={{minio.endpoint}}&autoCreateBucket=true")
            .process(exchange -> {
                // Log the S3 object key
                String key = exchange.getIn().getHeader(AWS2S3Constants.KEY, String.class);
                log.info("Processing file: " + key + " from bucket: " + bucketName);

                // Run the pipeline
                String pipelineId = fetchPipelineId();
                log.info("Running pipeline: " + pipelineId + " for display name " + pipelineDisplayName);
                String result = runPipeline(pipelineId);
                log.info("Pipeline Run: " + result);
            })
            .log("File processed: ${header.CamelMinioObjectName}") // delete the file
            .to("aws2-s3://{{bucket.name}}?operation=deleteObject")
            .log("File deleted: ${header.CamelMinioObjectName}")
            .end();
    }

    private String fetchPipelineId() {
        Response response = kfpClient.getPipelines();
        if (response.getStatus() != 200) {
            throw new RuntimeException("Failed to fetch pipelines from Kubeflow");
        }

        PipelineResponse pipelineResponse = response.readEntity(PipelineResponse.class);
        log.info("Pipeline list: " + pipelineResponse.getPipelines());
        Optional<Pipeline> pipelineOpt = pipelineResponse.getPipelines().stream()
            .filter(p -> pipelineDisplayName.equals(p.getDisplayName()))
            .findFirst();

        String pipelineId = null;
        if (pipelineOpt.isPresent()) {
            pipelineId = pipelineOpt.get().getPipelineId();
            log.info("Pipeline ID for display name " + pipelineDisplayName + ": " + pipelineId);
        } else {
            throw new RuntimeException("Pipeline with display name " + pipelineDisplayName + " not found");
        }
        return pipelineId;
    }

    private String runPipeline(String pipelineId) {
        PipelineSpec pipelineSpec = new PipelineSpec();
        pipelineSpec.setDisplayName(pipelineDisplayName + "_run");
        pipelineSpec.setDescription("Fraud Detection Pipeline run from Camel S3 Integration");
        RuntimeConfig runtimeConfig = new RuntimeConfig();
        // runtimeConfig.setParameters(Map.of("param1", "value1"));
        pipelineSpec.setRuntimeConfig(runtimeConfig);
        PipelineVersionReference pipelineVersionReference = new PipelineVersionReference();
        pipelineVersionReference.setPipelineId(pipelineId);
        pipelineSpec.setPipelineVersionReference(pipelineVersionReference);

        Response response = kfpClient.runPipeline(pipelineSpec);
        if (response.getStatus() != 200) {
            throw new RuntimeException("Failed to run pipeline " + pipelineId + " in Kubeflow");
        }

        return response.readEntity(String.class);
    }
}
