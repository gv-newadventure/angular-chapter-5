private string BuildFieldDataXml(int index)
{
    // Every 10th row: <FieldData /> to test that path
    if (index % 10 == 0)
    {
        return "<FieldData />";
    }

    // ----- Insurance (Old) test data -----

    // PolicyNumber: e.g. P000123
    var policyNumber = $"P{index:000000}";

    // CoverageType: rotate a few sample coverage types
    string[] coverageTypes = { "Auto", "Home", "Life", "Health" };
    var coverageType = coverageTypes[index % coverageTypes.Length];

    // PremiumAmount: random premium between 250 and 1,000
    var premiumAmount = Math.Round(250 + _random.NextDouble() * 750, 2);

    // ClaimNumber: simple numeric claim id
    var claimNumber = 100000 + index;

    // ClaimStatus: rotate a few statuses
    string[] statuses = { "Open", "Closed", "Pending", "Denied" };
    var claimStatus = statuses[index % statuses.Length];

    // ----- Build FieldData XML -----
    var sb = new StringBuilder();
    sb.AppendLine("<FieldData>");
    sb.AppendLine($"  <Field1>{policyNumber}</Field1>");   // PolicyNumber
    sb.AppendLine($"  <Field2>{coverageType}</Field2>");   // CoverageType
    sb.AppendLine($"  <Field3>{premiumAmount}</Field3>");  // PremiumAmount
    sb.AppendLine($"  <Field4>{claimNumber}</Field4>");    // ClaimNumber
    sb.AppendLine($"  <Field5>{claimStatus}</Field5>");    // ClaimStatus
    sb.AppendLine("</FieldData>");

    return sb.ToString();
}