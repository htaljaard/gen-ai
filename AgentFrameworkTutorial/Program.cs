// Copyright (c) Microsoft. All rights reserved.

// This sample shows how to create and use a simple AI agent with Azure OpenAI as the backend.

using System.ComponentModel;
using System.Xml.Schema;
using Azure;
using Azure.AI.OpenAI;
using Microsoft.Agents.AI;
using Microsoft.Extensions.AI;
using OpenAI;

var endpoint = Environment.GetEnvironmentVariable("AZURE_OPENAI_ENDPOINT") ?? throw new InvalidOperationException("AZURE_OPENAI_ENDPOINT is not set.");
var deploymentName = Environment.GetEnvironmentVariable("AZURE_OPENAI_DEPLOYMENT_NAME") ?? "gpt-4o-mini";
var apiKey = Environment.GetEnvironmentVariable("AZURE_OPENAI_API_KEY");

const string AgentName = "Helper";
const string AgentInstructions = "You are a helpful assistant that can provide information about the weather.";

[Description("Get the weather for a given location.")]
static string GetWeather([Description("The location to get the weather for.")] string location)
    => $"The weather in {location} is cloudy with a high of 15°C.";

#pragma warning disable MEAI001 // Type is for evaluation purposes only and is subject to change or removal in future updates. Suppress this diagnostic to proceed.
AIAgent agent = new AzureOpenAIClient(
    new Uri(endpoint),
    new AzureKeyCredential(apiKey!))
     .GetChatClient(deploymentName)
     .CreateAIAgent(AgentInstructions, AgentName, tools: [new ApprovalRequiredAIFunction(AIFunctionFactory.Create(GetWeather))]);


AgentThread thread = agent.GetNewThread();

while (true)
{
    Console.Write("You: ");
    var userInput = Console.ReadLine();
    if (string.IsNullOrEmpty(userInput) || userInput.Equals("exit", StringComparison.OrdinalIgnoreCase))
    {
        break;
    }

    var updates = await agent.RunStreamingAsync(userInput!, thread).ToListAsync();
    var userInputRequests = updates.SelectMany(x => x.UserInputRequests).ToList();

    while (userInputRequests.Count > 0)
    {
        var userInputResponses = userInputRequests.OfType<FunctionApprovalRequestContent>().Select(x =>
        {
            Console.WriteLine();
            Console.WriteLine($"The agent is requesting to call the function '{x.FunctionCall.Name}' with the following arguments:");
            return new ChatMessage(ChatRole.User, [x.CreateResponse(Console.ReadLine()?.Equals("Y", StringComparison.OrdinalIgnoreCase) ?? false)]);


        }).ToList();


        updates = await agent.RunStreamingAsync(userInputResponses, thread).ToListAsync();
        userInputRequests = updates.SelectMany(x => x.UserInputRequests).ToList();

    }

    Console.WriteLine($"\nAgent: {updates.ToAgentRunResponse()}");
    Console.WriteLine();
}


#pragma warning restore MEAI001 // Type is for evaluation purposes only and is subject to change or removal in future updates. Suppress this diagnostic to proceed.