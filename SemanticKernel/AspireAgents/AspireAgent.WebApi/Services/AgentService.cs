using System;
using Microsoft.SemanticKernel;
using Microsoft.SemanticKernel.Agents;

namespace AspireAgent.WebApi.Services;

public sealed class AgentService(Kernel kernel)
{
    public async Task<string> GetSingleAgentResponseAsync(string question)
    {
        var agentKernel = kernel.Clone();

        var agent = new ChatCompletionAgent()
        {
            Name = "FAQAgent",
            Description = "An agent that answers questions about Semantic Kernel.",
            Instructions = "You are a helpful assistant that provides accurate information about user queries.",
            Kernel = agentKernel
        };

        var responseText = "";

        await foreach (ChatMessageContent response in agent.InvokeAsync(question))
        {
            responseText += response.Content;
        }

        return responseText;

    }

}
