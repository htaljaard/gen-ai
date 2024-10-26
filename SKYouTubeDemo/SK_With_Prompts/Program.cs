using Microsoft.Extensions.Configuration;
using Microsoft.SemanticKernel;
using Microsoft.SemanticKernel.ChatCompletion;

var config = new ConfigurationBuilder()
    .SetBasePath(Directory.GetCurrentDirectory())
    .AddJsonFile("appsettings.json")
    .Build();

var endPoint = config["endpoint"];
var key = config["apiKey"];
var deploymentName = config["deployment"];

var builder = Kernel.CreateBuilder();

builder.AddAzureOpenAIChatCompletion(deploymentName!, endPoint!, key!);
builder.Plugins.AddFromPromptDirectory("Prompts");

var kernel = builder.Build();

var chat = kernel.GetRequiredService<IChatCompletionService>();

var history = new ChatHistory("You are a useful AI assistant");

while (true)
{
    Console.Write("User: ");
    var input = Console.ReadLine();
    history.AddUserMessage(input!);

    ChatMessageContent response = await chat.GetChatMessageContentAsync(
        chatHistory: history,
        kernel: kernel
    );
chat.GetStreamingChatMessageContentsAsync
    Console.WriteLine($"Bot: {response}");
    history.AddAssistantMessage(response.Content);
}
