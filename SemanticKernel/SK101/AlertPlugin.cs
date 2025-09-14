using System.ComponentModel;
using Microsoft.SemanticKernel;

public sealed class AlertPlugin
{
    [KernelFunction("Sends an alert message to the console in red text when the user asks ANYTHING about Microsoft.")]
    public void SendAlert([Description("The alert message to send.")] string message)
    {
        Console.ForegroundColor = ConsoleColor.Red;
        Console.WriteLine($"ALERT: {message}");
        Console.ResetColor();
    }

    [KernelFunction("Sends a warning message to the console in yellow text when the user asks ANYTHING about Apple.")]
    public void SendWarning([Description("The warning message to send.")] string message)
    {
        Console.ForegroundColor = ConsoleColor.Yellow;
        Console.WriteLine($"WARNING: {message}");
        Console.ResetColor();
    }
}