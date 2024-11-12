package com.redhat.docbot;

import jakarta.json.bind.annotation.JsonbProperty;

// "display_name":"${PIPELINE_NAME}_run",
// "description":"This is run from curl",
// "runtime_config": {
//     "parameters": {
//         "param1": "value1",
//     },
// "pipeline_version_reference":{
//     "pipeline_id":"${PIPELINE_ID}"
// }
public class PipelineSpec {
    @JsonbProperty("display_name")
    private String displayName;

    @JsonbProperty("description")
    private String description;
    
    @JsonbProperty("runtime_config")
    private RuntimeConfig runtimeConfig;

    @JsonbProperty("pipeline_version_reference")
    private PipelineVersionReference pipelineVersionReference;

    // Getters and setters

    public String getDisplayName() {
        return displayName;
    }

    public void setDisplayName(String displayName) {
        this.displayName = displayName;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public RuntimeConfig getRuntimeConfig() {
        return runtimeConfig;
    }

    public void setRuntimeConfig(RuntimeConfig runtimeConfig) {
        this.runtimeConfig = runtimeConfig;
    }

    public PipelineVersionReference getPipelineVersionReference() {
        return pipelineVersionReference;
    }

    public void setPipelineVersionReference(PipelineVersionReference pipelineVersionReference) {
        this.pipelineVersionReference = pipelineVersionReference;
    }
 }