using System;
using Microsoft.SemanticKernel;

namespace AspireAgent.WebApi.Extensions;

public static class SemanticKernelExtensions
{
    public static IServiceCollection AddSemanticKernel(this IServiceCollection services, IConfiguration configuration)
    {
        var modelName = configuration.GetValue("OpenAI:ModelName", "gpt-4o");
        var endpoint = configuration.GetValue("OpenAI:Endpoint", string.Empty);
        var apiKey = configuration.GetValue("OpenAI:ApiKey", string.Empty);

        services.AddAzureOpenAIChatCompletion(
            deploymentName: modelName,
            endpoint: endpoint,
            apiKey: apiKey
        );

        services.AddTransient<Kernel>(sp =>
        {
            return new Kernel(sp); //Allows you to manage all kernel services and plugins from DI and not create a new DI container for each kernel instance.
        });

        return services;
    }

}


// https://blog.antosubash.com/posts/ollama-semantic-kernal-connector