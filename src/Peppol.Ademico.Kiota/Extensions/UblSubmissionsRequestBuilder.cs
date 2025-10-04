using Microsoft.Kiota.Abstractions;
using Microsoft.Kiota.Abstractions.Serialization;
using Peppol.Ademico.Kiota.Models;

namespace Peppol.Ademico.Kiota.Api.Peppol.V1.Invoices.UblSubmissions
{
  public partial class UblSubmissionsRequestBuilder
  {
    public async Task<DocumentSubmissionResult?> PostAsync(
        MultipartBody body,
        Action<RequestConfiguration<DefaultQueryParameters>>? requestConfiguration = default,
        CancellationToken cancellationToken = default)
    {
      _ = body ?? throw new ArgumentNullException(nameof(body));
      var requestInfo = ToPostRequestInformation(body, requestConfiguration);
      var errorMapping = new Dictionary<string, ParsableFactory<IParsable>>
            {
                { "400", FileSubmissionResultError.CreateFromDiscriminatorValue },
                { "401", ApplicationMessage.CreateFromDiscriminatorValue },
            };
      return await RequestAdapter
          .SendAsync(requestInfo,
              DocumentSubmissionResult.CreateFromDiscriminatorValue,
              errorMapping,
              cancellationToken)
          .ConfigureAwait(false);
    }

    public RequestInformation ToPostRequestInformation(MultipartBody body, Action<RequestConfiguration<DefaultQueryParameters>>? requestConfiguration = default)
    {
      _ = body ?? throw new ArgumentNullException(nameof(body));
      var requestInfo = new RequestInformation(Method.POST, UrlTemplate, PathParameters);
      requestInfo.Configure(requestConfiguration);
      requestInfo.Headers.TryAdd("Accept", "application/json");
      requestInfo.SetContentFromParsable(RequestAdapter, "multipart/form-data", body);
      return requestInfo;
    }
  }
}
