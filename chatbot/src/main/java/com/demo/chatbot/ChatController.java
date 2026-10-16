package com.demo.chatbot;

import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.Map;
import java.util.concurrent.ThreadLocalRandom;

@RestController
public class ChatController {

    private static final List<String> RESPONSES = List.of(
        "I can help you with that! Let me look up your account details.",
        "Your order #10492 is currently in transit. Expected delivery is Thursday.",
        "I've updated your contact preferences. You'll receive email confirmations only.",
        "Let me transfer you to our billing department for that request. One moment.",
        "Your subscription renews on December 1st. Would you like to make changes?",
        "I've applied a 15% discount to your next invoice as a courtesy.",
        "Our business hours are Monday-Friday, 8 AM to 6 PM Eastern.",
        "I've created support ticket #TK-7291 for your issue. You'll receive updates via email.",
        "Your account security settings have been updated successfully.",
        "Is there anything else I can help you with today?"
    );

    @PostMapping("/chat")
    public Map<String, String> chat(@RequestBody(required = false) Map<String, String> request) {
        if (request == null) {
            return Map.of("response", "I didn't catch that. Could you rephrase?");
        }
        String message = request.getOrDefault("message", "").trim();
        if (message.isEmpty()) {
            return Map.of("response", "I didn't catch that. Could you rephrase?");
        }
        String response = RESPONSES.get(ThreadLocalRandom.current().nextInt(RESPONSES.size()));
        return Map.of("response", response);
    }
}
