package com.demo;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.JsonNode;
import org.yaml.snakeyaml.Yaml;
import java.util.Map;

public class App {
    public static void main(String[] args) throws Exception {
        System.out.println("Lightwell Java Demo — Minimal App");
        System.out.println("=".repeat(45));

        ObjectMapper mapper = new ObjectMapper();
        String json = "{\"customer\":\"acct-10492\",\"status\":\"active\",\"renewal\":\"2026-12-01\"}";
        JsonNode node = mapper.readTree(json);
        System.out.println("JSON parsing (Jackson " + mapper.version() + "):");
        System.out.println("  Customer: " + node.get("customer").asText());
        System.out.println("  Status:   " + node.get("status").asText());
        System.out.println();

        Yaml yaml = new Yaml();
        String yamlStr = "service:\n  name: customer-support\n  port: 8080\n  replicas: 3";
        Map<String, Object> config = yaml.load(yamlStr);
        System.out.println("YAML parsing (SnakeYAML):");
        System.out.println("  Config: " + config);
        System.out.println();

        System.out.println("These libraries have known CVEs at their current versions.");
        System.out.println("Run 'make scan' to check for vulnerabilities.");
    }
}
