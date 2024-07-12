package com.redhat.docbot;

import jakarta.json.bind.annotation.JsonbProperty;

public class RuntimeConfig {
    @JsonbProperty("parameters")
    private Parameters parameters;

    // Getters and setters

    public Parameters getParameters() {
        return parameters;
    }

    public void setParameters(Parameters parameters) {
        this.parameters = parameters;
    }
}