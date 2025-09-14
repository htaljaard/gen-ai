var builder = DistributedApplication.CreateBuilder(args);

var ollama = builder.AddOllama("ollama")
                    .WithDataVolume()
                    .WithLifetime(ContainerLifetime.Persistent)
                    .WithContainerRuntimeArgs("--gpus=all")
                    .WithOpenWebUI();

var llm = ollama.AddModel("llama3");

builder.AddProject<Projects.AspireAgent_WebApi>("API")
       .WithReference(llm)
       .WithUrl("/scalar/v1", "Scalar")
       .WaitFor(llm);

builder.Build().Run();
