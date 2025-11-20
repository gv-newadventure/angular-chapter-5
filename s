public async Task<IReadOnlyList<RemapRuleDto>> GetRulesAsync(
    IEnumerable<int> remapIds,
    CancellationToken ct)
{
    var ids = remapIds.Distinct().ToArray();
    if (ids.Length == 0)
        return Array.Empty<RemapRuleDto>();

    var rules =
        await (from r in _ef.RemapFields.AsNoTracking()
               join dc in _ef.ImgDocumentCategories.AsNoTracking()
                    on r.SourceCategoryKey equals dc.CategoryKey          // tbl_IMG_DocumentCategory
               join f in _ef.ImgCategoryFields.AsNoTracking()
                    on new { dc.CategoryKey, r.SourceFieldNumber }
                    equals new { f.CategoryKey, f.FieldNumber }          // tbl_IMG_CategoryFields
               where ids.Contains(r.RemapID)
               orderby r.RemapID, r.TargetFieldNumber
               select new RemapRuleDto(
                   r.RemapID,
                   r.TargetFieldNumber,
                   r.Action,
                   r.SourceFieldNumber,
                   r.DefaultValue,
                   f.FieldLabel                                         // <-- field label for source category
               ))
              .ToListAsync(ct);

    return rules;
}
