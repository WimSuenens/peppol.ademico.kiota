using Microsoft.Kiota.Abstractions;
using Microsoft.Kiota.Abstractions.Authentication;

namespace Peppol.Ademico.Kiota.Services;
// // https://tobiasfenster.io/generate-your-own-business-central-api-client-with-kiota
public class AuthProvider(ITokenService tokenService) : IAuthenticationProvider
{
  public async Task AuthenticateRequestAsync(
    RequestInformation request,
    Dictionary<string, object>? additionalAuthenticationContext = null,
    CancellationToken cancellationToken = default)
  {
    var token = await tokenService.GetValidTokenAsync();
    request.Headers.Add("Authorization", token);
  }
}
