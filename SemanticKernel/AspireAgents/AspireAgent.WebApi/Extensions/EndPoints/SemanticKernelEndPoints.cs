using System;
using AspireAgent.WebApi.Services;
using Microsoft.SemanticKernel;

namespace AspireAgent.WebApi.Extensions.EndPoints;

public static class SemanticKernelEndPoints
{
    public static IEndpointRouteBuilder MapSemanticKernelEndPoints(this IEndpointRouteBuilder endpoints)
    {

        endpoints.MapGet("/sk/agent", async (AgentService agentService) =>
                {
                    var question = "What is the capital of Poland?";

                    var response = await agentService.GetSingleAgentResponseAsync(question);

                    return Results.Ok(response);
                });

        endpoints.MapPost("/sk/multi-agent-story", async (AgentService agentService, string Theme, string Summary) =>
        {
            var response = await agentService.WriteMultiAgentStory(Theme, Summary);

            return Results.Ok(response);
        });

        return endpoints;
    }

}
