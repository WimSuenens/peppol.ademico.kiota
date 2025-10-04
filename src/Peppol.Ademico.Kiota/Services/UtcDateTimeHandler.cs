using System.Text;
using System.Text.RegularExpressions;

namespace Peppol.Ademico.Kiota.Services;
public class UtcDateTimeHandler : DelegatingHandler
{
  protected override async Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken cancellationToken)
  {
    var response = await base.SendAsync(request, cancellationToken);
    if (response.Content?.Headers?.ContentType?.MediaType == "application/json")
    {
      var json = await response.Content.ReadAsStringAsync();
      // Add 'Z' suffix to datetime strings without timezone info
      var modifiedJson = Regex.Replace(json,
          @"""(\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3})""",
          @"""$1Z""");

      response.Content = new StringContent(modifiedJson, Encoding.UTF8, "application/json");
    }
    return response;
  }
}