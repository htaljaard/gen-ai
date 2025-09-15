using System.Text.Json;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using Microsoft.SemanticKernel;
using Microsoft.SemanticKernel.ChatCompletion;
using Microsoft.SemanticKernel.Connectors.OpenAI;
using SK101;

var config = new ConfigurationBuilder()
    .AddUserSecrets<Program>()
    .Build();

string AOIKEY = config["AOIKEY"]!;
string AOIENDPOINT = config["AOIENDPOINT"]!;

var kernel = Kernel.CreateBuilder()
    .AddAzureOpenAIChatCompletion("gpt-4o", AOIENDPOINT, AOIKEY)
    .Build();

#region BASICS

var prompt = @"What is the capital of France?";

var response = await kernel.InvokePromptAsync(prompt);

Console.WriteLine(response);

#endregion

#region  ADDING INLINE PROMPTS

// var storyKernel = kernel.Clone();

// var inlinePrompt =
//         @$"""
//         Write a short story about a {{$theme}}.

//         Summary: {{$summary}}
//         """;

// KernelArguments storyArgs = new()
// {
//     ["theme"] = "space adventure",
//     ["summary"] = "A group of explorers travel through a wormhole in search of a new home for humanity."
// };

// var storyFunction = storyKernel.CreateFunctionFromPrompt(inlinePrompt);

// var storyRespone = await storyKernel.InvokeAsync(storyFunction, storyArgs);

// Console.WriteLine(storyRespone);

#endregion

#region  ADDING FILE-BASED PROMPTS

// var builder = Kernel.CreateBuilder()
// .AddAzureOpenAIChatCompletion("gpt-4o", AOIENDPOINT, AOIKEY);

// builder.Plugins.AddFromPromptDirectory("prompts", "Story_Plugin");

// var storyKernel = builder.Build();

// Console.ForegroundColor = ConsoleColor.Red;

// Console.WriteLine("""

// ##########

// """);


// foreach (var plugin in storyKernel.Plugins)
// {
//     Console.WriteLine($"Plugin: {plugin.Name}");
//     foreach (var function in plugin)
//     {
//         Console.WriteLine($"  Function: {function.Name}");
//     }
// }

// Console.WriteLine("""

// ##########

// """);


// var editedStory = await storyKernel.InvokeAsync("Story_Plugin", "WriteStory", new KernelArguments
// {
//     ["summary"] = "A developer is giving a presentation about AI when things start to go wrong.",
//     ["theme"] = "Horror",
//     ["narrator"] = "Yoda from Star Wars"
// });

// Console.ForegroundColor = ConsoleColor.Cyan;

// Console.WriteLine(editedStory);



// Console.ForegroundColor = ConsoleColor.Yellow;

// Console.WriteLine("""

// ##########

// """);

// Console.ForegroundColor = ConsoleColor.Cyan;

// PromptExecutionSettings promptExecutionSettings = new()
// {
//     FunctionChoiceBehavior = FunctionChoiceBehavior.Auto()
// };

// var normalStory = await storyKernel.InvokePromptAsync("Write me a story about a developer doing a presentation. The theme needs to be a Horror. Always use your plugins to write and edit the story", new KernelArguments(promptExecutionSettings));


// Console.WriteLine(normalStory);

// Console.ResetColor();

#endregion

#region  LOGGING, MIDDLEWARE, NATIVE FUNCTIONS, ICHATCOMPLETION, RESPONSE FORMATTING


// var builder = Kernel.CreateBuilder()
// .AddAzureOpenAIChatCompletion("gpt-4o", AOIENDPOINT, AOIKEY);

// builder.Services.AddLogging(_ => _.AddConsole().SetMinimumLevel(LogLevel.Information));

// builder.Services.AddSingleton<IAutoFunctionInvocationFilter, FunctionLoggingMiddleware>();
// builder.Plugins.AddFromType<MathPlugin>();

// var mathKernel = builder.Build();

// OpenAIPromptExecutionSettings promptExecutionSettings = new()
// {
//     FunctionChoiceBehavior = FunctionChoiceBehavior.Auto(),
//     ResponseFormat = typeof(MathResponse)
// };

// var chat = kernel.GetRequiredService<IChatCompletionService>();

// //SET UP SYSTEM PROMPT
// var history = new ChatHistory(
//     """
//     You are an expert math tutor. Always use the MathPlugin to answer math questions.
//     """
//     );

// string? userInput;
// do
// {
//     // Collect user input
//     Console.Write("User > ");
//     userInput = Console.ReadLine();

//     // Add user input
//     history.AddUserMessage(userInput);

//     // 3. Get the response from the AI with automatic function calling
//     var result = await chat.GetChatMessageContentAsync(
//         history,
//         executionSettings: promptExecutionSettings,
//         kernel: mathKernel);

//     // Print the results
//     Console.WriteLine("Assistant > " + JsonSerializer.Deserialize<MathResponse>(result.Content ?? string.Empty)?.Response);
//     Console.WriteLine("Reasoning > " + JsonSerializer.Deserialize<MathResponse>(result.Content ?? string.Empty)?.Reasoning);

//     // Add the message from the agent to the chat history
//     history.AddMessage(result.Role, result.Content ?? string.Empty);
// } while (userInput is not null);


#endregion

# region IMAGE PROCESSING

// var builder = Kernel.CreateBuilder()
//  .AddAzureOpenAIChatCompletion("gpt-4o", AOIENDPOINT, AOIKEY);

// builder.Services.AddLogging(_ => _.AddConsole().SetMinimumLevel(LogLevel.Information));

// var imageKernel = builder.Build();

// OpenAIPromptExecutionSettings promptExecutionSettings = new()
// {
//     FunctionChoiceBehavior = FunctionChoiceBehavior.Auto(),
//     ResponseFormat = typeof(ImageResponse)
// };

// var chat = kernel.GetRequiredService<IChatCompletionService>();

// var imageFiles = Directory.GetFiles("imageprocessing/sample");



// foreach (var file in imageFiles)
// {
//     byte[] imageBytes = File.ReadAllBytes(file);

//     var history = new ChatHistory(
//         """
//     You are an expert image analyst. Always use the ImagePlugin to answer questions about images. When Analysing an image, keep you answers brief and to the point.
//     """
//         );

//     history.AddUserMessage(new ChatMessageContentItemCollection()
//     {
//         new TextContent("Analyse this image and describe what you see."),
//         new ImageContent(imageBytes, "image/png"),
//     });

//     var response = await chat.GetChatMessageContentAsync(
//         history,
//         executionSettings: promptExecutionSettings,
//         kernel: imageKernel);

//     Console.WriteLine($"Image Analysis > {response.Content}");


// }





#endregion