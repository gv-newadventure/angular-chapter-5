var rules = await _ef.RemapFields
    .AsNoTracking()
    .Where(r => ids.Contains(r.RemapID))
    .Join(_ef.ImgDocumentCategories.AsNoTracking(),
          r => r.SourceCategoryKey,
          dc => dc.CategoryKey,
          (r, dc) => new { r, dc })
    .Join(_ef.ImgCategoryFields.AsNoTracking(),
          x => new { x.dc.CategoryKey, FieldNumber = x.r.SourceFieldNumber },
          f => new { f.CategoryKey, f.FieldNumber },
          (x, f) => new { x.r, f })
    .OrderBy(x => x.r.RemapID)
    .ThenBy(x => x.r.TargetFieldNumber)
    .Select(x => new RemapRuleDto(
        x.r.RemapID,
        x.r.TargetFieldNumber,
        x.r.Action,
        x.r.SourceFieldNumber,
        x.r.DefaultValue,
        x.f.FieldLabel))
    .ToListAsync(ct);
