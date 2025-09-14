var builder = DistributedApplication.CreateBuilder(args);

//ADD EXISTING FOUNDRY
var foundryEndPoint = builder.AddParameter("ExistingFoundryInstance");
var foundryKey = builder.AddParameter("ExistingFoundryResourceGroup");
var foundryModel = builder.AddParameter("FoundryModel");


var api = builder.AddProject<Projects.AspireAgent_WebApi>("API")
                .WithUrlForEndpoint("https", url =>
                    {
                        url.DisplayText = "Scalar";
                        url.Url = "/scalar";
                    })
                .WithEnvironment("OpenAI:ModelName", foundryModel)
                .WithEnvironment("OpenAI:Endpoint", foundryEndPoint)
                .WithEnvironment("OpenAI:ApiKey", foundryKey);

builder.Build().Run();
