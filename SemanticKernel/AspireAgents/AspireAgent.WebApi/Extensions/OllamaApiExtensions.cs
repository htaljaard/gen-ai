using Microsoft.Extensions.AI;
using OllamaSharp;
using OllamaSharp.Models.Chat;

namespace AspireAgent.WebApi.Extensions;

public static class OllamaApiExtensions
{
    public static WebApplication MapOllamaEndPoints(this WebApplication app)
    {

        app.MapGet("/ollama/chat/OllamaClient", async (IOllamaApiClient chatClient) =>
         {
             var responses = new List<string>();

             await foreach (var response in chatClient.ChatAsync(new ChatRequest()
             {
                 Messages = new List<Message>
                 {
                    new Message(OllamaSharp.Models.Chat.ChatRole.User, "What is 1 + 1?"),
                 }
             }))
             {
                 responses.Add(response?.Message.Content ?? "");
             }

             var fullResponse = string.Join("", responses);
             return Results.Ok(fullResponse);

         }).WithDescription("Get all chat messages from Ollama")
           .WithName("GetOllamaChat")
           .WithOpenApi();


        app.MapGet("/ollama/chat/IChatClient", async (IChatClient chatClient) =>
        {

            var response = await chatClient.GetResponseAsync("What is 1 + 1?");
            return Results.Ok(response);

        }).WithDescription("Get all chat messages from Ollama using IChatClient")
          .WithName("GetOllamaChatMS")
          .WithOpenApi();

        return app;
    }

}
