using System.Globalization;
using System.Text.Json;
using System.Text.Json.Serialization;

namespace Peppol.Ademico.Kiota.Services;
public class UtcDateTimeOffsetConverter : JsonConverter<DateTimeOffset>
{
  public override DateTimeOffset Read(ref Utf8JsonReader reader, Type typeToConvert, JsonSerializerOptions options)
  {
    var dateString = reader.GetString()!;
    var dateTime = DateTime.ParseExact(dateString, "yyyy-MM-ddTHH:mm:ss.fff", CultureInfo.InvariantCulture);
    return DateTime.SpecifyKind(dateTime, DateTimeKind.Utc);
  }
  public override void Write(Utf8JsonWriter writer, DateTimeOffset value, JsonSerializerOptions options)
  {
    writer.WriteStringValue(value.ToString("yyyy-MM-ddTHH:mm:ss.fff"));
  }
}
