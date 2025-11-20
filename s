private string BuildFieldDataXmlForTechnology(int index)
{
    // Every 10th row: <FieldData /> to test blank-path handling
    if (index % 10 == 0)
    {
        return "<FieldData />";
    }

    // ----- Technology (Old) test data -----

    // DeviceType: rotate devices
    string[] deviceTypes = { "Laptop", "Desktop", "Tablet", "Server", "Mobile" };
    var deviceType = deviceTypes[index % deviceTypes.Length];

    // OperatingSystem: rotate OS list
    string[] osList = { "Windows 11", "Windows 10", "macOS", "Linux", "Android", "iOS" };
    var operatingSystem = osList[index % osList.Length];

    // SoftwareVersion: random decimal version (e.g., 1.0, 2.3, 5.7 etc.)
    var softwareVersion = Math.Round(_random.NextDouble() * 10, 2);

    // LastUpdated: base date + index days
    var lastUpdated = new DateTime(2022, 1, 1).AddDays(index);

    // Hostname: e.g., HOST-000123
    var hostname = $"HOST-{index:000000}";

    // ----- Build XML -----
    var sb = new StringBuilder();
    sb.AppendLine("<FieldData>");
    sb.AppendLine($"  <Field1>{deviceType}</Field1>");         // DeviceType
    sb.AppendLine($"  <Field2>{operatingSystem}</Field2>");    // OperatingSystem
    sb.AppendLine($"  <Field3>{softwareVersion}</Field3>");     // SoftwareVersion
    sb.AppendLine($"  <Field4>{lastUpdated:yyyy-MM-dd}</Field4>"); // LastUpdated
    sb.AppendLine($"  <Field5>{hostname}</Field5>");           // Hostname
    sb.AppendLine("</FieldData>");

    return sb.ToString();
}