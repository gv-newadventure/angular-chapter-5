;WITH ToUpsert AS
(
    SELECT t.SiteCode,
           t.RemapID,
           t.DocumentKey,
           dd.FieldData
    FROM #ToClaim t
    JOIN dbo.tbl_IMG_DocumentData dd ON dd.DocumentKey = t.DocumentKey
    JOIN dbo.tbl_IMG_DocumentKeys dk ON dk.DocumentKey = t.DocumentKey
                                    AND dk.SiteCode    = t.SiteCode   -- tenant guard
)
-- 1) UPDATE existing log rows (retries)
UPDATE ml
SET ml.Status                  = 'PROCESSING',
    ml.ModifiedOn              = SYSUTCDATETIME(),
    ml.ModifiedBy              = '00000000-0000-0000-0000-000000000000',
    ml.FieldDataBeforeMigration = tu.FieldData   -- optional: refresh backup XML
FROM dbo.tbl_IMG_DocumentCategoryRemapMigrationLog ml
JOIN ToUpsert tu
  ON tu.SiteCode    = ml.SiteCode
 AND tu.RemapID     = ml.RemapID
 AND tu.DocumentKey = ml.DocumentKey;

-- 2) INSERT new rows (first-time claims)
INSERT dbo.tbl_IMG_DocumentCategoryRemapMigrationLog
    (SiteCode, RemapID, DocumentKey, FieldDataBeforeMigration, Status, ModifiedOn, ModifiedBy)
SELECT tu.SiteCode,
       tu.RemapID,
       tu.DocumentKey,
       tu.FieldData,
       'PROCESSING',
       SYSUTCDATETIME(),
       '00000000-0000-0000-0000-000000000000'
FROM ToUpsert tu
LEFT JOIN dbo.tbl_IMG_DocumentCategoryRemapMigrationLog ml
  ON tu.SiteCode    = ml.SiteCode
 AND tu.RemapID     = ml.RemapID
 AND tu.DocumentKey = ml.DocumentKey
WHERE ml.RemapID IS NULL;     -- only those with no existing log row