using System.Text.Json;
using System.Text.Json.Serialization;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Options;
using Microsoft.Kiota.Abstractions.Authentication;
using Microsoft.Kiota.Abstractions.Serialization;
using Microsoft.Kiota.Http.HttpClientLibrary;
using Microsoft.Kiota.Serialization.Json;
using Peppol.Ademico.Kiota.Extensions;
using Peppol.Ademico.Kiota.Services;

namespace Peppol.Ademico.Kiota;
public static class Setup
{
  public static IServiceCollection AddPeppolServices(this IServiceCollection services, IConfiguration configuration)
  {
    var section = configuration.GetSection("Ademico");
    services.Configure<AdemicoSettings>(section);
    services.AddSingleton(sp => sp.GetRequiredService<IOptions<AdemicoSettings>>().Value);

    // Register the JWT handler
    services.AddSingleton<IAuthenticationProvider, AuthProvider>();
    services.AddSingleton<AuthProvider>();
    // Register token service
    services.AddSingleton<ITokenService, TokenService>();
    services.AddSingleton<TokenService>();

    services.AddTransient<UtcDateTimeHandler>();
    services
      .AddHttpClient<PeppolAdemicoApiClient>((sp, client) =>
      {
        // var settings = sp.GetRequiredService<IOptions<AdemicoSettings>>();
        var settings = sp.GetRequiredService<AdemicoSettings>();
        client.BaseAddress = new Uri(settings.ApiBaseUrl);
      })
      .AddHttpMessageHandler<UtcDateTimeHandler>()
      .AddTypedClient((httpClient, sp) =>
      {
        var authProvider = sp.GetRequiredService<IAuthenticationProvider>();
        JsonSerializerOptions _options = new(JsonSerializerDefaults.Web);
        _options.PropertyNamingPolicy = JsonNamingPolicy.CamelCase;
        _options.Converters.Add(new JsonStringEnumConverter());
        _options.Converters.Add(new UtcDateTimeOffsetConverter());
        var kiotaJsonSerializationContext = new KiotaJsonSerializationContext(_options);
        var jsonSerializationWriterFactory = SerializationWriterFactoryRegistry.DefaultInstance;
        jsonSerializationWriterFactory.ContentTypeAssociatedFactories["application/json"] = new JsonSerializationWriterFactory(kiotaJsonSerializationContext);
        var adapter = new HttpClientRequestAdapter(
        authProvider,
        // ParseNodeFactoryRegistry.DefaultInstance,
        serializationWriterFactory: jsonSerializationWriterFactory,
        httpClient: httpClient);
        return new PeppolAdemicoApiClient(adapter);
      })
      .ConfigurePrimaryHttpMessageHandler(_ =>
      {
        var defaultHandlers = KiotaClientFactory.CreateDefaultHandlers();
        var defaultMessageHandler = KiotaClientFactory.GetDefaultHttpMessageHandler();
        return KiotaClientFactory.ChainHandlersCollectionAndGetFirstLink(
          defaultMessageHandler, [.. defaultHandlers]
        )!;
      });
    return services;
  }
}
