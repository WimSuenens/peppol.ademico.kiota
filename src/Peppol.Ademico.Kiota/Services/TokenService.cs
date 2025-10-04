using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using Microsoft.Extensions.Logging;
using Peppol.Ademico.Kiota.Extensions;

namespace Peppol.Ademico.Kiota.Services;
public interface ITokenService
{
  Task<string> GetValidTokenAsync();
}
public class TokenResponse
{
    public string AccessToken { get; set; } = string.Empty;
    public int ExpiresIn { get; set; }
    public string TokenType { get; set; } = string.Empty;
}
public class TokenErrorResponse
{
  public string Error { get; set; } = string.Empty;
}
public class TokenService(
  HttpClient httpClient,
  AdemicoSettings settings,
  ILogger<TokenService> logger
): ITokenService
{
  // private readonly AdemicoSettings _config = config.Value;
  private readonly SemaphoreSlim _semaphore = new(1, 1);
  private string? _currentToken = string.Empty;
  private DateTime _tokenExpiry;
  private async Task TrySetTokenFromUserEnvironmentVariable()
  {
    try
    {
      var accessTokenPath = settings.AccessTokenPath;
      if (string.IsNullOrEmpty(accessTokenPath)) return;
      DateTimeOffset dateTime = _tokenExpiry;
      var dateStr = dateTime.ToString("yyyy-MM-ddTHH:mm:ss.fffZ");
      var variable = $"{dateStr}|{_currentToken}";
      await File.WriteAllTextAsync(accessTokenPath, variable);
    }
    catch (Exception ex)
    {
      logger.LogError("TryGetTokenFromUserEnvironmentVariable - {Message}", ex.Message);
    }
  }
  private async Task<(DateTime, string?)> TryGetTokenFromUserEnvironmentVariable()
  {
    try
    {
      var accessTokenPath = settings.AccessTokenPath;
      if (string.IsNullOrEmpty(accessTokenPath)) return (DateTime.MinValue, null);
      if (!File.Exists(accessTokenPath)) return (DateTime.MinValue, null);
      var content = await File.ReadAllTextAsync(accessTokenPath);
      if (string.IsNullOrEmpty(content)) return (DateTime.MinValue, null);
      var splitted = content.Split("|", 2);
      if (!DateTimeOffset.TryParse(splitted[0], out var date)) return (DateTime.MinValue, null);
      return (date.DateTime, splitted[1]);
    }
    catch (Exception ex)
    {
      logger.LogError("TryGetTokenFromUserEnvironmentVariable - {Message}", ex.Message);
      return (DateTime.MinValue, null);
    }
  }
  public async Task<string> GetValidTokenAsync()
  {
    await _semaphore.WaitAsync();
    try
    {
      if (string.IsNullOrEmpty(_currentToken))
        (_tokenExpiry, _currentToken) = await TryGetTokenFromUserEnvironmentVariable();
      // Check if current token is still valid (with 5-minute buffer)
      if (!string.IsNullOrEmpty(_currentToken) && DateTime.UtcNow < _tokenExpiry.AddMinutes(-5))
        return _currentToken;
      // Get new token
      return await RefreshTokenAsync();
    }
    finally
    {
      _semaphore.Release();
    }
  }

  private async Task<string> RefreshTokenAsync()
  {
    try
    {
      var formContent = new FormUrlEncodedContent(new[]
      {
        new KeyValuePair<string, string>("grant_type", "client_credentials"),
        new KeyValuePair<string, string>("scope", "peppol/document"),
      });
      var bytes = Encoding.UTF8.GetBytes($"{settings.Client.Id}:{settings.Client.Secret}");
      var base64Header = Convert.ToBase64String(bytes);
      httpClient.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Basic", base64Header);
      var response = await httpClient.PostAsync(settings.TokenEndpoint, formContent);

      JsonSerializerOptions options = new JsonSerializerOptions()
      {
        PropertyNamingPolicy = JsonNamingPolicy.SnakeCaseLower
      };
      if (!response.IsSuccessStatusCode)
      {
        var error = await response.Content.ReadAsStringAsync();
        var tokenErrorResponse = JsonSerializer.Deserialize<TokenErrorResponse>(error, options);
        throw new Exception($"RefreshTokenAsync - {response.StatusCode} - {tokenErrorResponse?.Error}");
      }
      ;
      var content = await response.Content.ReadAsStringAsync();
      var tokenResponse = JsonSerializer.Deserialize<TokenResponse>(content, options);
      if (tokenResponse is null) throw new Exception($"RefreshTokenAsync - {response.StatusCode} - The token response is empty?");
      _currentToken = tokenResponse.AccessToken;
      _tokenExpiry = DateTime.UtcNow.AddSeconds(tokenResponse.ExpiresIn);
      await TrySetTokenFromUserEnvironmentVariable();
      logger.LogInformation("Token refreshed successfully. Expires at: {ExpiryTime}", _tokenExpiry);
      return _currentToken;
    }
    catch (Exception ex)
    {
      logger.LogError(ex, "Failed to refresh token");
      throw;
    }
  }
}
