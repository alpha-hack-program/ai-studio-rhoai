package com.redhat.docbot;

import java.util.Optional;

import javax.naming.ConfigurationException;

import org.apache.camel.LoggingLevel;
import org.apache.camel.builder.RouteBuilder;
import org.apache.camel.component.minio.MinioConstants;
import org.apache.camel.component.google.storage.GoogleCloudStorageConstants;

import jakarta.inject.Inject;
import jakarta.ws.rs.core.Response;
import jakarta.annotation.PostConstruct;
import jakarta.enterprise.context.ApplicationScoped;

import org.eclipse.microprofile.config.inject.ConfigProperty;
import org.eclipse.microprofile.rest.client.inject.RestClient;

@ApplicationScoped 
public class GSEventListener extends RouteBuilder {

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

    @PostConstruct
    void init() throws ConfigurationException {
        try {
            fetchPipelineId();
        } catch (Exception e) {
            log.error("Failed to fetch pipeline ID", e);
            throw new ConfigurationException("Failed to fetch pipeline ID");
        }
    }

    // @Override
    // public void configure() throws Exception {
    //     from("google-storage://{{bucket.name}}?autoCreateBucket=false&moveAfterRead=false")
    //         .routeId("gcs-listener")
    //         .log("Detected file: ${header.CamelGoogleCloudStorageObjectName}")
    //         .process(exchange -> {
    //             String fileName = exchange.getIn().getHeader("CamelGoogleCloudStorageObjectName", String.class);
    //             if ("model.onnx".equals(fileName)) {
    //                 log.info("model.onnx detected, triggering Kubeflow Pipeline");
    //                 runPipeline();
    //             }
    //         });
    // }

    @Override
    public void configure() throws Exception {
        from("google-storage://{{bucket.name}}?autoCreateBucket=false&deleteAfterRead=false&delay=1000")
            .routeId("gcs-listener")
            .log(LoggingLevel.DEBUG, "Received GCS event: ${headers} for file: ${header.CamelGoogleCloudStorageObjectName}")            
            .filter(header(GoogleCloudStorageConstants.OBJECT_NAME).endsWith(evaluationKitFilename))
            .log(LoggingLevel.INFO, "Filter passed for file: ${header.CamelGoogleCloudStorageObjectName}") 
            .setHeader(MinioConstants.OBJECT_NAME, simple("${header.CamelGoogleCloudStorageObjectName}")) 
            .log("Processing file: ${header.CamelMinioObjectName}")
            .to("minio://{{minio.bucket-name}}?accessKey={{minio.access-key}}&secretKey={{minio.secret-key}}&region={{minio.region}}&endpoint={{minio.endpoint}}&autoCreateBucket=true")
            .process(exchange -> {
                // Log the GCS object name
                String key = exchange.getIn().getHeader(GoogleCloudStorageConstants.OBJECT_NAME, String.class);
                log.info("Processing file: " + key + " from bucket: " + bucketName);

                // Run the pipeline
                String pipelineId = fetchPipelineId();
                log.info("Running pipeline: " + pipelineId + " for display name " + pipelineDisplayName);
                String result = runPipeline(pipelineId);
                log.info("Pipeline Run: " + result);
            })
            .log("File processed: ${header.CamelMinioObjectName}") // delete the file
            .to("google-storage://{{bucket.name}}?operation=deleteObject")
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
