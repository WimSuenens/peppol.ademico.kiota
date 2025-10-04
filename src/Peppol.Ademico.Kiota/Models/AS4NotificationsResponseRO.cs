
using Microsoft.Kiota.Abstractions.Extensions;
using Microsoft.Kiota.Abstractions.Serialization;

namespace Peppol.Ademico.Kiota.Models
{
  public class AS4NotificationsResponseRO : NotificationsResponseRO
  {
    public new static AS4NotificationsResponseRO CreateFromDiscriminatorValue(IParseNode parseNode)
    {
      _ = parseNode ?? throw new ArgumentNullException(nameof(parseNode));
      return new AS4NotificationsResponseRO();
    }
    public override IDictionary<string, Action<IParseNode>> GetFieldDeserializers()
    {
      return new Dictionary<string, Action<IParseNode>>
      {
        {
          "notifications",
          n =>
          {
              Notifications = n.GetCollectionOfObjectValues(AS4Notification.CreateFromDiscriminatorValue)?.AsList();
          }
        },
        {
          "pagination",
          n =>
          {
              Pagination = n.GetObjectValue<PageableResponseRO>(PageableResponseRO.CreateFromDiscriminatorValue);
          }
        },
      };
    }

  }
  public partial class AS4Notification : NotificationRO
  {
    public override IDictionary<string, Action<IParseNode>> GetFieldDeserializers()
    {
      if (InvoiceReceivingNotificationRO != null)
        return InvoiceReceivingNotificationRO.GetFieldDeserializers();
      if (InvoiceResponseReceivingNotificationRO != null)
        return InvoiceResponseReceivingNotificationRO.GetFieldDeserializers();
      if (InvoiceResponseSendingNotificationRO != null)
        return InvoiceResponseSendingNotificationRO.GetFieldDeserializers();
      if (InvoiceSendingNotificationRO != null)
        return InvoiceSendingNotificationRO.GetFieldDeserializers();
      if (IrasSendingNotificationRO != null)
        return IrasSendingNotificationRO.GetFieldDeserializers();
      if (LegalEntityCorppassC5NotificationRO != null)
        return LegalEntityCorppassC5NotificationRO.GetFieldDeserializers();
      if (LegalEntityCorppassKycNotificationRO != null)
        return LegalEntityCorppassKycNotificationRO.GetFieldDeserializers();
      if (MLRReceivingNotificationRO != null)
        return MLRReceivingNotificationRO.GetFieldDeserializers();
      if (OrderReceivingNotificationRO != null)
        return OrderReceivingNotificationRO.GetFieldDeserializers();
      if (OrderSendingNotificationRO != null)
        return OrderSendingNotificationRO.GetFieldDeserializers();
      return new Dictionary<string, Action<IParseNode>>();
    }

    public static new NotificationRO CreateFromDiscriminatorValue(IParseNode parseNode)
    {
      _ = parseNode ?? throw new ArgumentNullException(nameof(parseNode));
      var eventTypeValue = parseNode.GetChildNode("eventType")?.GetStringValue();
      var peppolDocumentTypeValue = parseNode.GetChildNode("peppolDocumentType")?.GetStringValue();
      var result = new NotificationRO();
      if (
          nameof(EventTypeRO.DOCUMENT_RECEIVED).Equals(eventTypeValue, StringComparison.OrdinalIgnoreCase)
          && (
              nameof(PeppolDocumentTypeRO.INVOICE).Equals(peppolDocumentTypeValue, StringComparison.OrdinalIgnoreCase)
              || nameof(PeppolDocumentTypeRO.CREDIT_NOTE).Equals(peppolDocumentTypeValue, StringComparison.OrdinalIgnoreCase)
              )
          )
      {
        result.InvoiceReceivingNotificationRO = new InvoiceReceivingNotificationRO();
        return result;
      }
      if (
          nameof(EventTypeRO.DOCUMENT_RECEIVED).Equals(eventTypeValue, StringComparison.OrdinalIgnoreCase)
          && nameof(PeppolDocumentTypeRO.ORDER).Equals(peppolDocumentTypeValue, StringComparison.OrdinalIgnoreCase)
      )
      {
        result.OrderReceivingNotificationRO = new OrderReceivingNotificationRO();
        return result;
      }
      if (
          (
              nameof(EventTypeRO.DOCUMENT_SENT).Equals(eventTypeValue, StringComparison.OrdinalIgnoreCase)
              || nameof(EventTypeRO.DOCUMENT_SEND_FAILED).Equals(eventTypeValue, StringComparison.OrdinalIgnoreCase)
          ) && (
              nameof(PeppolDocumentTypeRO.INVOICE).Equals(peppolDocumentTypeValue, StringComparison.OrdinalIgnoreCase)
              || nameof(PeppolDocumentTypeRO.CREDIT_NOTE).Equals(peppolDocumentTypeValue, StringComparison.OrdinalIgnoreCase)
              )
          )
      {
        result.InvoiceSendingNotificationRO = new InvoiceSendingNotificationRO();
        return result;
      }
      if (
          (
              nameof(EventTypeRO.DOCUMENT_SENT).Equals(eventTypeValue, StringComparison.OrdinalIgnoreCase)
              || nameof(EventTypeRO.DOCUMENT_SEND_FAILED).Equals(eventTypeValue, StringComparison.OrdinalIgnoreCase)
          ) && nameof(PeppolDocumentTypeRO.ORDER).Equals(peppolDocumentTypeValue, StringComparison.OrdinalIgnoreCase)
      )
      {
        result.OrderSendingNotificationRO = new OrderSendingNotificationRO();
        return result;
      }
      if (nameof(EventTypeRO.INVOICE_RESPONSE_RECEIVED).Equals(eventTypeValue, StringComparison.OrdinalIgnoreCase))
      {
        result.InvoiceResponseReceivingNotificationRO = new InvoiceResponseReceivingNotificationRO();
        return result;
      }

      if (
          nameof(EventTypeRO.INVOICE_RESPONSE_SENT).Equals(eventTypeValue, StringComparison.OrdinalIgnoreCase)
          || nameof(EventTypeRO.INVOICE_RESPONSE_SEND_FAILED).Equals(eventTypeValue, StringComparison.OrdinalIgnoreCase)
      )
      {
        result.InvoiceResponseSendingNotificationRO = new InvoiceResponseSendingNotificationRO();
        return result;
      }
      if (nameof(EventTypeRO.MLR_RECEIVED).Equals(eventTypeValue, StringComparison.OrdinalIgnoreCase))
      {
        result.MLRReceivingNotificationRO = new MLRReceivingNotificationRO();
        return result;
      }
      return result;

    }
  }
}
