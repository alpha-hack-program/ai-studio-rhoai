package com.redhat.docbot;

import java.io.IOException;
import java.nio.file.Paths;

import org.eclipse.microprofile.rest.client.annotation.ClientHeaderParam;
import org.eclipse.microprofile.rest.client.inject.RegisterRestClient;

import jakarta.ws.rs.GET;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.core.Response;

import java.nio.file.Files;

@RegisterRestClient(configKey = "kfp-client")
@ClientHeaderParam(name = "Authorization", value = "{getAuthorizationHeader}")
public interface KubeflowPipelineClient {

    @GET
    @Path("/apis/v2beta1/pipelines")
    Response getPipelines();

    @POST
    @Path("/apis/v2beta1/runs")
    Response runPipeline(PipelineSpec pipelineSpec);

    default String getAuthorizationHeader() {
        try {
            String token = Files.readString(Paths.get("/var/run/secrets/kubernetes.io/serviceaccount/token"));
            return "Bearer " + token.trim();
        } catch (IOException e) {
            throw new RuntimeException("Failed to read the service account token", e);
        }
    }
}
