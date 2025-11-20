public TransformedDoc Transform(
    DocumentRecord doc,
    IReadOnlyList<RemapRuleDto> rulesForThisRemap,
    bool appendUnmappedToDocDesc)
{
    // 1) Parse existing positional XML into 1-based dictionary
    var srcVals = ParsePositional(doc.Xml);   // e.g. { 1 => "A", 2 => "B", 3 => "C", ... }

    // 2) Order rules by target field, prepare 1-based target array
    var orderedRules = rulesForThisRemap
        .OrderBy(r => r.TargetFieldNumber)
        .ToList();

    var maxField = orderedRules.Count == 0
        ? 0
        : orderedRules.Max(r => r.TargetFieldNumber);

    var tgtVals = new string[maxField + 1];   // index 0 unused

    // 🔹 Track which *source* fields participate in ANY rule
    var usedSourceFields = new HashSet<int>(
        orderedRules
            .Where(r => r.SourceFieldNumber.HasValue)
            .Select(r => r.SourceFieldNumber.Value));

    var appendParts = new List<string>();

    // 3) Apply rules to build target positional values
    foreach (var rule in orderedRules)
    {
        var action = (rule.Action ?? "MAP").ToUpperInvariant();

        switch (action)
        {
            case "MAP":
            {
                string value = null;

                if (rule.SourceFieldNumber.HasValue &&
                    srcVals.TryGetValue(rule.SourceFieldNumber.Value, out var srcVal) &&
                    !string.IsNullOrWhiteSpace(srcVal))
                {
                    value = srcVal.Trim();
                }
                else if (!string.IsNullOrWhiteSpace(rule.DefaultValue))
                {
                    value = rule.DefaultValue.Trim();
                }

                // If value is null, we still keep an empty node
                tgtVals[rule.TargetFieldNumber] = value ?? string.Empty;
                break;
            }

            case "DISCARD":
            case "APPEND":   // In this design, APPEND behaves like DISCARD for XML
            default:
            {
                // Target node keeps default (or rule.DefaultValue if provided)
                tgtVals[rule.TargetFieldNumber] = rule.DefaultValue ?? string.Empty;
                break;
            }
        }
    }

    // 4) After mapping, optionally append all *unmapped* sources to DocDesc
    if (appendUnmappedToDocDesc && srcVals.Count > 0)
    {
        foreach (var kvp in srcVals)
        {
            var srcFieldNo = kvp.Key;
            var srcVal = kvp.Value;

            // Skip any source field that is already used by a rule
            if (usedSourceFields.Contains(srcFieldNo))
                continue;

            if (string.IsNullOrWhiteSpace(srcVal))
                continue;

            appendParts.Add(srcVal.Trim());
        }
    }

    // 5) Build new positional XML
    var newXml = BuildPositional(tgtVals);

    // 6) Build append note (goes to DocDesc)
    string appendNote = appendParts.Count > 0
        ? string.Join("; ", appendParts)
        : null;

    return new TransformedDoc(
        doc.SiteCode,
        doc.RemapId,
        doc.DocumentKey,
        newXml,
        appendNote,
        "COMPLETED");
}
