package com.redhat.docbot;

import java.io.IOException;
import java.nio.file.Paths;

import org.eclipse.microprofile.config.ConfigProvider;
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

    // Looks for service account token first in the k8s location /var/run/secrets/kubernetes.io/serviceaccount/token
    // If not found, it looks for the token in the configuration property kfp-client.token if not found in neither location, 
    // it throws a runtime exception
    default String getAuthorizationHeader() {
        String authorizationHeader = null;
        try {
            authorizationHeader = "Bearer " + Files.readString(Paths.get("/var/run/secrets/kubernetes.io/serviceaccount/token"));
        } catch (IOException e) {
            authorizationHeader = "Bearer " + ConfigProvider.getConfig().getValue("kfp-client.token", String.class);
        }
        System.out.println("Authorization header: >>>" + authorizationHeader + "<<<");
        return authorizationHeader;
    }
}
