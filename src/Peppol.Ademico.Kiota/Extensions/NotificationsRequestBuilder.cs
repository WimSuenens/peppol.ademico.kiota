using Microsoft.Kiota.Abstractions;
using Microsoft.Kiota.Abstractions.Serialization;
using Peppol.Ademico.Kiota.Models;

namespace Peppol.Ademico.Kiota.Api.Peppol.V1.Notifications
{
  public partial class NotificationsRequestBuilder
  {
    public async Task<AS4NotificationsResponseRO?> GetAsync<T>(
      Action<RequestConfiguration<NotificationsRequestBuilderGetQueryParameters>>? requestConfiguration = default,
      CancellationToken cancellationToken = default) where T : AS4NotificationsResponseRO
    {
      var requestInfo = ToGetRequestInformation(requestConfiguration);
      var errorMapping = new Dictionary<string, ParsableFactory<IParsable>>
      {
        { "400", ApplicationMessage.CreateFromDiscriminatorValue },
        { "401", ApplicationMessage.CreateFromDiscriminatorValue },
      };
      return await RequestAdapter
        .SendAsync(requestInfo,
          AS4NotificationsResponseRO.CreateFromDiscriminatorValue,
          errorMapping,
          cancellationToken)
        .ConfigureAwait(false);
    }
  }
}