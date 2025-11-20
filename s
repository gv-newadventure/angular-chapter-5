private string BuildFieldDataXmlForMarketing(int index)
{
    // Every 10th row: <FieldData /> to test that path
    if (index % 10 == 0)
    {
        return "<FieldData />";
    }

    // ----- Marketing (Old) test data -----

    // CampaignName: "Campaign 000123"
    var campaignName = $"Campaign {index:000000}";

    // TargetAudience: rotate a few audience types
    string[] audiences = { "Retail", "SMB", "Enterprise", "VIP", "Online" };
    var targetAudience = audiences[index % audiences.Length];

    // BudgetAmount: random budget between 5,000 and 50,000
    var budgetAmount = Math.Round(5000 + _random.NextDouble() * 45000, 2);

    // ConversionRate: random 0–50% with 2 decimals
    var conversionRate = Math.Round(_random.NextDouble() * 50, 2);

    // LeadSource: rotate some sources
    string[] sources = { "Email", "Social Media", "Webinar", "SEO", "Referral" };
    var leadSource = sources[index % sources.Length];

    // ----- Build FieldData XML -----
    var sb = new StringBuilder();
    sb.AppendLine("<FieldData>");
    sb.AppendLine($"  <Field1>{campaignName}</Field1>");      // CampaignName
    sb.AppendLine($"  <Field2>{targetAudience}</Field2>");    // TargetAudience
    sb.AppendLine($"  <Field3>{budgetAmount}</Field3>");      // BudgetAmount
    sb.AppendLine($"  <Field4>{conversionRate}</Field4>");    // ConversionRate
    sb.AppendLine($"  <Field5>{leadSource}</Field5>");        // LeadSource
    sb.AppendLine("</FieldData>");

    return sb.ToString();
}