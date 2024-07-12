package com.redhat.docbot;

import jakarta.json.bind.annotation.JsonbProperty;

public class Pipeline {
    @JsonbProperty("pipeline_id")
    private String pipelineId;

    @JsonbProperty("display_name")
    private String displayName;
    
    @JsonbProperty("created_at")
    private String createdAt;

    // Getters and setters

    public String getPipelineId() {
        return pipelineId;
    }

    public void setPipelineId(String pipelineId) {
        this.pipelineId = pipelineId;
    }

    public String getDisplayName() {
        return displayName;
    }

    public void setDisplayName(String displayName) {
        this.displayName = displayName;
    }

    public String getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(String createdAt) {
        this.createdAt = createdAt;
    }

    @Override
    public String toString() {
        return "Pipeline [pipelineId=" + pipelineId + ", displayName=" + displayName + ", createdAt=" + createdAt + "]";
    }
}
