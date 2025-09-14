using AspireAgent.WebApi.Extensions;
using AspireAgent.WebApi.Extensions.EndPoints;
using AspireAgent.WebApi.Services;
using Microsoft.Extensions.Hosting;
using Scalar.AspNetCore;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
// Learn more about configuring OpenAPI at https://aka.ms/aspnet/openapi
builder.Services.AddOpenApi();

builder.AddServiceDefaults();

builder.Services.AddSemanticKernel(builder.Configuration);

builder.Services.AddSingleton<AgentService>();


var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
    app.MapScalarApiReference();
}

app.UseHttpsRedirection();

app.MapWeatherEndPoints();
app.MapSemanticKernelEndPoints();


app.MapDefaultEndpoints();//Aspire


app.Run();


