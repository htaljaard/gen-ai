using System.ComponentModel;
using Microsoft.SemanticKernel;

namespace SK101;

public class MathPlugin
{
    [KernelFunction, Description("Adds two integers and returns the result.")]
    public int Add(int a, int b) => a + b;

    [KernelFunction, Description("Subtracts the second integer from the first and returns the result.")]
    public int Subtract(int a, int b) => a - b;

    [KernelFunction, Description("Multiplies two integers and returns the result.")]
    public int Multiply(int a, int b) => a * b;

    [KernelFunction, Description("Divides the first double by the second and returns the result. Throws an exception if the divider is zero.")]
    public double Divide(double a, double b)
    {
        if (b == 0)
            throw new DivideByZeroException("Divider cannot be zero.");
        return a / b;
    }

    [KernelFunction, Description("Returns the remainder of dividing the first integer by the second. Throws an exception if the divider is zero.")]
    public int Modulo(int a, int b)
    {
        if (b == 0)
            throw new DivideByZeroException("Divider cannot be zero.");
        return a % b;
    }
}