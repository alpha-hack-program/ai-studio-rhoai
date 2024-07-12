package com.redhat.docbot;

import jakarta.json.bind.annotation.JsonbProperty;

public class PipelineVersionReference {
    @JsonbProperty("pipeline_id")
    private String pipelineId;

    // Getters and setters

    public String getPipelineId() {
        return pipelineId;
    }

    public void setPipelineId(String pipelineId) {
        this.pipelineId = pipelineId;
    }
}