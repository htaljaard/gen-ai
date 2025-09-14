using System;
using AspireAgent.WebApi.Services;
using Microsoft.SemanticKernel;

namespace AspireAgent.WebApi.Extensions.EndPoints;

public static class SemanticKernelEndPoints
{
    public static IEndpointRouteBuilder MapSemanticKernelEndPoints(this IEndpointRouteBuilder endpoints)
    {
        endpoints.MapGet("/sk/test", async (Kernel kernel) =>
        {
            var response = await kernel.InvokePromptAsync("What is the capital of France?");

            return Results.Ok(response.GetValue<string>());
        });
        

        endpoints.MapGet("/sk/agent", async (AgentService agentService) =>
        {
            var question = "What is the capital of Poland?";
            
            var response = await agentService.GetSingleAgentResponseAsync(question);

            return Results.Ok(response);
        });

        return endpoints;
    }

}
