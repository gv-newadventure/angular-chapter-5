;WITH SourceCat AS
(
    -- the source category for this remap
    SELECT TOP (1) SourceCategoryKey
    FROM #RemapField
    WHERE RemapID = @RemapID
),
SourceFields AS
(
    -- all fields defined for the source category
    SELECT f.CategoryKey,
           f.FieldNumber,
           f.FieldLabel,
           f.FieldDataType
    FROM dbo.tbl_IMG_CategoryFields f
    JOIN SourceCat sc
        ON sc.SourceCategoryKey = f.CategoryKey
),
MappedSourceFields AS
(
    -- all source field numbers that are referenced in this remap
    SELECT DISTINCT rf.SourceFieldNumber
    FROM #RemapField rf
    WHERE rf.RemapID = @RemapID
      AND rf.SourceFieldNumber IS NOT NULL
)
SELECT
    sf.FieldNumber,
    sf.FieldLabel,
    sf.FieldDataType
FROM SourceFields sf
LEFT JOIN MappedSourceFields m
    ON m.SourceFieldNumber = sf.FieldNumber
WHERE m.SourceFieldNumber IS NULL       -- => **unmapped**
ORDER BY sf.FieldNumber;
