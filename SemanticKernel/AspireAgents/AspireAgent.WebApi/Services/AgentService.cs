using System;
using Microsoft.SemanticKernel;
using Microsoft.SemanticKernel.Agents;
using Microsoft.SemanticKernel.Agents.Orchestration.GroupChat;
using Microsoft.SemanticKernel.Agents.Orchestration.Sequential;
using Microsoft.SemanticKernel.Agents.Runtime.InProcess;
using Microsoft.SemanticKernel.ChatCompletion;

namespace AspireAgent.WebApi.Services;

public sealed class AgentService(Kernel kernel, ILogger<AgentService> logger)
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

    public async Task<string> WriteMultiAgentStory(string Theme, string Summary)
    {
        ChatCompletionAgent writer = new ChatCompletionAgent
        {
            Name = "StoryWriter",
            Description = "A story writer",
            Instructions =
            $"""
                You are a story writer with ten years of experience.
                Write a story about ${Summary} with the theme of ${Theme}.
                
                Your goal is to write an award-winning story that captivates readers and leaves a lasting impression.
                Only provide a single proposal per response. You're laser focused on the goal at hand. 
                Don't waste time with chit chat. Consider suggestions when refining an idea.
            """,
            Kernel = kernel,
        };

        ChatCompletionAgent editor = new ChatCompletionAgent
        {
            Name = "Reviewer",
            Description = "An editor.",
            Instructions =
            $"""
                You are an art director who has opinions about story writing born of a love for Star Wars. 
                The goal is to determine if the given copy is acceptable to present to Yoda. If so, state that it is approved.
                If not, provide insight on how to refine suggested copy without example.
            """,
            Kernel = kernel,
        };

        ChatHistory history = new();

        ValueTask responseCallback(ChatMessageContent response)
        {
            history.Add(response);
            return ValueTask.CompletedTask;
        }

        // SequentialOrchestration orchestration = new(writer, editor)
        // {
        //     ResponseCallback = responseCallback
        // };

        GroupChatOrchestration orchestration = new(new RoundRobinGroupChatManager { MaximumInvocationCount = 5 }, writer, editor)
        {
            ResponseCallback = responseCallback
        };

        InProcessRuntime runtime = new();

        await runtime.StartAsync();

        var prompt =
        $"""
        
        Write a story about {Summary} with the theme of {Theme}.
        The goal is not to critique the user's story but to create a story for them.
        The last response should be the final story.

        """;
        var result = await orchestration.InvokeAsync(
            prompt, runtime);

        string output = await result.GetValueAsync(timeout: TimeSpan.FromSeconds(30));

        logger.LogInformation("# MAIN STORY: {Story}", output);

        logger.LogInformation("# CONVERSATION HISTORY: {History}", history);

        return output;

    }
}
