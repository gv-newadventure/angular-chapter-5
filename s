private string BuildFieldDataXmlForFinance(int index)
{
    // Every 10th row: <FieldData /> to test blank-path handling
    if (index % 10 == 0)
    {
        return "<FieldData />";
    }

    // ----- Finance (Old) field values -----

    // TransactionAmount: random between -5000 and +5000 (credits and debits)
    double transactionAmount = Math.Round(_random.NextDouble() * 10000 - 5000, 2);

    // PostingDate: rotate dates by adding <index> days from a base date
    var postingDate = new DateTime(2020, 1, 1).AddDays(index);

    // AccountNumber: numeric, padded left (e.g. 000123456)
    long accountNumber = 100000000 + index;

    // CurrencyCode: rotate through major currencies
    string[] currencies = { "USD", "CAD", "EUR", "GBP", "JPY" };
    string currencyCode = currencies[index % currencies.Length];

    // Balance: running-style balance with randomness
    double balance = Math.Round(10000 + (_random.NextDouble() * 50000) - index, 2);

    // ----- Build XML -----
    var sb = new StringBuilder();
    sb.AppendLine("<FieldData>");
    sb.AppendLine($"  <Field1>{transactionAmount}</Field1>");      // TransactionAmount
    sb.AppendLine($"  <Field2>{postingDate:yyyy-MM-dd}</Field2>"); // PostingDate
    sb.AppendLine($"  <Field3>{accountNumber}</Field3>");          // AccountNumber
    sb.AppendLine($"  <Field4>{currencyCode}</Field4>");           // CurrencyCode
    sb.AppendLine($"  <Field5>{balance}</Field5>");                // Balance
    sb.AppendLine("</FieldData>");

    return sb.ToString();
}