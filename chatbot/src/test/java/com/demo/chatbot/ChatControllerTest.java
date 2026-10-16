package com.demo.chatbot;

import org.junit.jupiter.api.Test;

import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;

class ChatControllerTest {

    private final ChatController controller = new ChatController();

    @Test
    void chatWithValidMessage() {
        Map<String, String> result = controller.chat(Map.of("message", "Hello"));
        assertNotNull(result.get("response"));
        assertFalse(result.get("response").isEmpty());
    }

    @Test
    void chatWithEmptyMessage() {
        Map<String, String> result = controller.chat(Map.of("message", ""));
        assertEquals("I didn't catch that. Could you rephrase?", result.get("response"));
    }

    @Test
    void chatWithWhitespaceOnly() {
        Map<String, String> result = controller.chat(Map.of("message", "   "));
        assertEquals("I didn't catch that. Could you rephrase?", result.get("response"));
    }

    @Test
    void chatWithMissingMessageKey() {
        Map<String, String> result = controller.chat(Map.of("other", "value"));
        assertEquals("I didn't catch that. Could you rephrase?", result.get("response"));
    }

    @Test
    void chatWithNullBody() {
        Map<String, String> result = controller.chat(null);
        assertEquals("I didn't catch that. Could you rephrase?", result.get("response"));
    }

    @Test
    void chatReturnsVariedResponses() {
        java.util.Set<String> responses = new java.util.HashSet<>();
        for (int i = 0; i < 50; i++) {
            Map<String, String> result = controller.chat(Map.of("message", "test"));
            responses.add(result.get("response"));
        }
        assertTrue(responses.size() > 1, "Expected varied responses from canned list");
    }
}
