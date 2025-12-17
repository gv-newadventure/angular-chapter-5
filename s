Got it — since you’re in testing, I’ll rewrite the stored proc **as a whole** with a clean **UNION ALL** design:

* **Source A (new work)** = `DocumentKeys` rows with **no MigrationLog row**
* **Source B (retries)** = `MigrationLog` rows that are **FAILED** or **stale PROCESSING**
* Claim batch into `#ToClaim`
* Flip `tbl_IMG_DocumentCategoryRemap` to **IN_PROGRESS** for any remap in the batch
* Pull `FieldData` into `#ToUpsert`
* **Update** existing log rows for retries, **Insert** new ones for first-time claims
* Return the batch

Below is a full drop-in rewrite.

---

## ✅ Full Stored Proc Rewrite (UNION-based)

> Replace your current one with this. (Adjust schema/table names only if yours differ.)

```sql
CREATE OR ALTER PROC dbo.usp_Remap_ClaimNextGlobalBatch
    @BatchSize INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @NowUtc DATETIME2(7) = SYSUTCDATETIME();

    -- Clean up temp tables just in case
    IF OBJECT_ID('tempdb..#ToClaim')  IS NOT NULL DROP TABLE #ToClaim;
    IF OBJECT_ID('tempdb..#ToUpsert') IS NOT NULL DROP TABLE #ToUpsert;

    ;WITH EligibleRemaps AS
    (
        SELECT
            r.RemapID,
            r.SourceCategoryKey,
            r.SiteCode,
            r.AppendUnmappedCategories
        FROM dbo.tbl_IMG_DocumentCategoryRemap r WITH (READCOMMITTEDLOCK)
        WHERE r.Status IN ('READY', 'IN_PROGRESS')  -- only active remaps
    ),

    -- A) brand new work (no MigrationLog row exists)
    NewCandidates AS
    (
        SELECT
            er.SiteCode,
            er.RemapID,
            dk.DocumentKey,
            er.AppendUnmappedCategories
        FROM EligibleRemaps er
        JOIN dbo.tbl_IMG_DocumentKeys dk WITH (READCOMMITTEDLOCK)
            ON dk.CategoryKey = er.SourceCategoryKey
           AND dk.SiteCode    = er.SiteCode
        LEFT JOIN dbo.tbl_IMG_DocumentCategoryRemapMigrationLog ml WITH (READCOMMITTEDLOCK)
            ON ml.SiteCode    = er.SiteCode
           AND ml.RemapID     = er.RemapID
           AND ml.DocumentKey = dk.DocumentKey
        WHERE ml.RemapID IS NULL
    ),

    -- B) retries (drive directly from MigrationLog)
    RetryCandidates AS
    (
        SELECT
            ml.SiteCode,
            ml.RemapID,
            ml.DocumentKey,
            er.AppendUnmappedCategories
        FROM dbo.tbl_IMG_DocumentCategoryRemapMigrationLog ml WITH (READCOMMITTEDLOCK)
        JOIN EligibleRemaps er
            ON er.SiteCode = ml.SiteCode
           AND er.RemapID  = ml.RemapID
        WHERE
            ml.Status = 'FAILED'
            OR (ml.Status = 'PROCESSING' AND ml.ModifiedOn < DATEADD(MINUTE, -15, @NowUtc))
    ),

    -- Combine both streams
    AllCandidates AS
    (
        SELECT SiteCode, RemapID, DocumentKey, AppendUnmappedCategories
        FROM NewCandidates

        UNION ALL

        SELECT SiteCode, RemapID, DocumentKey, AppendUnmappedCategories
        FROM RetryCandidates
    )
    SELECT TOP (@BatchSize)
        c.SiteCode,
        c.RemapID,
        c.DocumentKey,
        c.AppendUnmappedCategories
    INTO #ToClaim
    FROM
    (
        -- DISTINCT to protect against any accidental duplicates
        SELECT DISTINCT SiteCode, RemapID, DocumentKey, AppendUnmappedCategories
        FROM AllCandidates
    ) c
    ORDER BY c.RemapID, c.DocumentKey;

    IF NOT EXISTS (SELECT 1 FROM #ToClaim)
    BEGIN
        RETURN;
    END

    /* Flip READY -> IN_PROGRESS for remaps in this batch */
    ;WITH FirstClaim AS
    (
        SELECT DISTINCT RemapID FROM #ToClaim
    )
    UPDATE r
        SET r.Status     = 'IN_PROGRESS',
            r.ModifiedOn = @NowUtc,
            r.ModifiedBy = '00000000-0000-0000-0000-000000000000'
    FROM dbo.tbl_IMG_DocumentCategoryRemap r
    JOIN FirstClaim fc
      ON fc.RemapID = r.RemapID
    WHERE r.Status = 'READY';

    /* Pull FieldData (and enforce tenant guard with DocumentKeys) */
    ;WITH ToUpsert AS
    (
        SELECT
            t.SiteCode,
            t.RemapID,
            t.DocumentKey,
            dd.FieldData
        FROM #ToClaim t
        JOIN dbo.tbl_IMG_DocumentData dd WITH (READCOMMITTEDLOCK)
            ON dd.DocumentKey = t.DocumentKey
        JOIN dbo.tbl_IMG_DocumentKeys dk WITH (READCOMMITTEDLOCK)
            ON dk.DocumentKey = t.DocumentKey
           AND dk.SiteCode    = t.SiteCode  -- tenant guard
    )
    SELECT
        u.SiteCode,
        u.RemapID,
        u.DocumentKey,
        u.FieldData
    INTO #ToUpsert
    FROM ToUpsert u;

    /* 1) UPDATE existing log rows (retries) */
    UPDATE ml
        SET ml.Status                 = 'PROCESSING',
            ml.ModifiedOn             = @NowUtc,
            ml.ModifiedBy             = '00000000-0000-0000-0000-000000000000',
            ml.FieldDataBeforeMigration = tu.FieldData   -- optional: refresh backup XML
    FROM dbo.tbl_IMG_DocumentCategoryRemapMigrationLog ml
    JOIN #ToUpsert tu
      ON tu.SiteCode    = ml.SiteCode
     AND tu.RemapID     = ml.RemapID
     AND tu.DocumentKey = ml.DocumentKey;

    /* 2) INSERT new log rows (first-time claims only) */
    INSERT dbo.tbl_IMG_DocumentCategoryRemapMigrationLog
        (SiteCode, RemapID, DocumentKey, FieldDataBeforeMigration, Status, ModifiedOn, ModifiedBy)
    SELECT
        tu.SiteCode,
        tu.RemapID,
        tu.DocumentKey,
        tu.FieldData,
        'PROCESSING',
        @NowUtc,
        '00000000-0000-0000-0000-000000000000'
    FROM #ToUpsert tu
    LEFT JOIN dbo.tbl_IMG_DocumentCategoryRemapMigrationLog ml
      ON ml.SiteCode    = tu.SiteCode
     AND ml.RemapID     = tu.RemapID
     AND ml.DocumentKey = tu.DocumentKey
    WHERE ml.RemapID IS NULL;

    /* Return batch */
    SELECT
        t.RemapID,
        t.DocumentKey,
        t.SiteCode,
        t.AppendUnmappedCategories
    FROM #ToClaim t
    ORDER BY t.RemapID, t.DocumentKey;
END
GO
```

---

## One more thing (very likely needed)

If your MigrationLog can have duplicates, the **UPDATE** step can update multiple rows for the same doc/remap/site. In testing, you should enforce uniqueness if possible:

```sql
-- ideal uniqueness if the design allows it
CREATE UNIQUE INDEX UX_MigrationLog_Site_Rem_ डॉक
ON dbo.tbl_IMG_DocumentCategoryRemapMigrationLog (SiteCode, RemapID, DocumentKey);
```

(If you already have it, great.)

---

If you want, paste your table definitions (or just keys/indexes) for these 3 tables and I’ll tailor:

* the best clustered/nonclustered index layout for this proc
* and the safest concurrency hints (`UPDLOCK/READPAST`) if multiple workers will claim at the same time.
