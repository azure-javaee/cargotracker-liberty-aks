package org.eclipse.pathfinder.api;

import dev.langchain4j.model.azure.AzureOpenAiChatModel;
import dev.langchain4j.service.AiServices;
import jakarta.enterprise.context.ApplicationScoped;

@ApplicationScoped
public class ShortestPathAiImpl implements ShortestPathAi {
    private volatile ShortestPathAi delegate;

    static boolean isConfigured() {
        return isSet("AZURE_OPENAI_KEY")
                && isSet("AZURE_OPENAI_ENDPOINT")
                && isSet("AZURE_OPENAI_DEPLOYMENT_NAME");
    }

    private static boolean isSet(String name) {
        String value = System.getenv(name);
        return value != null && !value.isBlank();
    }

    @Override
    public String chat(String location, String voyage, String carrier_movement, String from, String to) {
        return getDelegate().chat(location, voyage, carrier_movement, from, to);
    }

    private ShortestPathAi getDelegate() {
        if (!isConfigured()) {
            throw new IllegalStateException(
                    "Azure OpenAI is disabled. Set AZURE_OPENAI_KEY, "
                    + "AZURE_OPENAI_ENDPOINT, and AZURE_OPENAI_DEPLOYMENT_NAME to enable it.");
        }

        ShortestPathAi current = delegate;
        if (current == null) {
            synchronized (this) {
                current = delegate;
                if (current == null) {
                    AzureOpenAiChatModel model = AzureOpenAiChatModel.builder()
                            .apiKey(System.getenv("AZURE_OPENAI_KEY"))
                            .endpoint(System.getenv("AZURE_OPENAI_ENDPOINT"))
                            .deploymentName(System.getenv("AZURE_OPENAI_DEPLOYMENT_NAME"))
                            .temperature(0.2)
                            .logRequestsAndResponses(true)
                            .build();
                    current = AiServices.builder(ShortestPathAi.class)
                            .chatLanguageModel(model)
                            .build();
                    delegate = current;
                }
            }
        }
        return current;
    }
}
