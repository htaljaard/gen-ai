var builder = DistributedApplication.CreateBuilder(args);


// var ollama = builder.AddContainer("ollama", "ollama/ollama")
//                     // .WithBindMount("ollama", "/root/.ollama")
//                     // .WithBindMount("./ollamaconfig", "/usr/config")
//                     .WithHttpEndpoint(port: 11434, targetPort: 11434, name: "ollama")
//                     // .WithEntrypoint("/usr/config/entrypoint.sh")
//                     .WithContainerRuntimeArgs("--gpus=all");


var ollama = builder.AddOllama("ollama")
                    .WithDataVolume()
                    .WithLifetime(ContainerLifetime.Persistent)
                    .AddModel("llama3");

builder.AddProject<Projects.AspireAgent_WebApi>("API")
       .WaitFor(ollama);

builder.Build().Run();
