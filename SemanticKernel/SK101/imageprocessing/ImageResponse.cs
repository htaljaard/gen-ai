using System.ComponentModel;

public sealed class ImageResponse
{
    [Description("The Type of animal in the image.")]
    public string AnimalType { get; set; } = string.Empty;

    [Description("The color of the animal in the image. Only use one colour based on the primary colour of the animal. E.g., brown, black, white.")]
    public string Color { get; set; } = string.Empty;

    [Description("The background setting of the image.")]
    public string Background { get; set; } = string.Empty;

    [Description("The action the animal is performing in the image. E.g., sitting, running, jumping.")]
    public string Action { get; set; } = string.Empty;
}