namespace Peppol.Ademico.Kiota.Extensions;
public class AdemicoClient
{
  public string? Id { get; set; }
  public string? Secret { get; set; }
}
public class AdemicoSettings
{
  public string TokenEndpoint { get; set; } = string.Empty;
  public string ApiBaseUrl { get; set; } = string.Empty;
  public AdemicoClient Client { get; set; } = new();
  public string? AccessTokenPath { get; set; } =  string.Empty;
}
