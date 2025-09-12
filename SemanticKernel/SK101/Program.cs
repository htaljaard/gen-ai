using Microsoft.Extensions.Configuration;
using Microsoft.SemanticKernel;

var config = new ConfigurationBuilder()
    .AddUserSecrets<Program>() // or your main class type
    .Build();

string AOIKEY = config["AOIKEY"]!;
string AOIENDPOINT = config["AOIENDPOINT"]!;

var kernel = Kernel.CreateBuilder()
    .AddAzureOpenAIChatCompletion("gpt-4o", AOIENDPOINT, AOIKEY)
    .Build();
    
#region Basic Invocation

    var prompt = @"What is the capital of France?";
    
    var response = await kernel.InvokePromptAsync(prompt);
    
    Console.WriteLine(response);

#endregion


