package com.redhat.docbot;

import java.util.ArrayList;
import java.util.List;

public class PipelineResponse {
    private List<Pipeline> pipelines = new ArrayList<Pipeline>();
    private int totalSize;

    // Getters and setters

    public List<Pipeline> getPipelines() {
        return pipelines;
    }

    public void setPipelines(List<Pipeline> pipelines) {
        this.pipelines = pipelines;
    }

    public int getTotalSize() {
        return totalSize;
    }

    public void setTotalSize(int totalSize) {
        this.totalSize = totalSize;
    }

    @Override
    public String toString() {
        return "PipelineResponse [pipelines=" + pipelines + ", totalSize=" + totalSize + "]";
    }

}