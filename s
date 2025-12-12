Got it — if adding parentheses didn’t change the result, then **that wasn’t the limiting factor in *your* environment**. Let’s narrow what *is* limiting it, using **queries that will tell you exactly which filter is excluding the rows**.

From your proc, rows can only be returned if ALL of these are true:

1. `tbl_IMG_DocumentCategoryRemap` row is **eligible**

   ```sql
   r.Status IN ('READY','IN_PROGRESS')
   ```
2. There are document keys for that remap’s **SourceCategoryKey + SiteCode**

   ```sql
   tbl_IMG_DocumentKeys dk ON dk.CategoryKey = r.SourceCategoryKey AND dk.SiteCode = r.SiteCode
   ```
3. The log row is either missing, FAILED, or PROCESSING **older than 15 min**

   ```sql
   ml is null OR ml.Status='FAILED' OR (ml.Status='PROCESSING' AND ml.ModifiedOn < now-15)
   ```

If you have “a lot of rows in MigrationLog” but you only get 185 back, it’s almost always because **#1 or #2 is blocking** (not the ml predicate).

---

## 1) First check: are those “lots of rows” even tied to eligible remaps?

Run this:

```sql
SELECT r.Status, COUNT(*) RemapCount
FROM dbo.tbl_IMG_DocumentCategoryRemap r
GROUP BY r.Status
ORDER BY RemapCount DESC;
```

If most remaps are `DRAFT`, `COMPLETED`, etc., then the proc will never touch them.

Also check the remaps that are actually contributing to PROCESSING rows:

```sql
SELECT TOP 50 ml.RemapID, r.Status, COUNT(*) RowsInLog
FROM dbo.tbl_IMG_DocumentCategoryRemapMigrationLog ml
JOIN dbo.tbl_IMG_DocumentCategoryRemap r ON r.RemapID = ml.RemapID
GROUP BY ml.RemapID, r.Status
ORDER BY RowsInLog DESC;
```

If you see your big RemapIDs are **not** `READY/IN_PROGRESS`, that’s your answer.

---

## 2) Second check: do you even have matching DocumentKeys for those log rows?

This is a *huge* common issue: MigrationLog can have DocumentKeys that don’t match `DocumentKeys` on CategoryKey/SiteCode anymore.

Pick one RemapID that you expect to be picked, and run:

```sql
DECLARE @RemapID int = 43; -- change

SELECT
    r.RemapID,
    r.SiteCode,
    r.SourceCategoryKey,
    DocKeysCount = COUNT(dk.DocumentKey)
FROM dbo.tbl_IMG_DocumentCategoryRemap r
LEFT JOIN dbo.tbl_IMG_DocumentKeys dk
    ON dk.SiteCode = r.SiteCode
   AND dk.CategoryKey = r.SourceCategoryKey
WHERE r.RemapID = @RemapID
GROUP BY r.RemapID, r.SiteCode, r.SourceCategoryKey;
```

If `DocKeysCount` is low (or 0), the proc can’t return 5000 no matter how big MigrationLog is.

---

## 3) Third check: are your PROCESSING rows actually “timed out”?

You showed 108,659 PROCESSING rows. If their `ModifiedOn` is being refreshed (by worker or retries), they will **never** qualify for reclaim.

Run:

```sql
SELECT
  COUNT(*) AS ProcessingRows,
  MIN(ModifiedOn) AS Oldest,
  MAX(ModifiedOn) AS Newest,
  SUM(CASE WHEN ModifiedOn < DATEADD(MINUTE,-15,SYSUTCDATETIME()) THEN 1 ELSE 0 END) AS TimedOutRows
FROM dbo.tbl_IMG_DocumentCategoryRemapMigrationLog
WHERE Status = 'PROCESSING';
```

If `TimedOutRows` is small, then the proc is behaving correctly — it refuses to re-claim “fresh” PROCESSING rows.

---

## 4) The *real* reason you can get only ~185 back

This happens when only a small number of remaps are eligible **AND** for those remaps, only ~185 documents satisfy:

* no log row, or
* FAILED, or
* PROCESSING older than 15 mins

To prove it, run a “candidate size by remap” query:

```sql
SELECT TOP 20
    r.RemapID,
    r.SiteCode,
    EligibleDocs =
      SUM(CASE
            WHEN ml.RemapID IS NULL THEN 1
            WHEN ml.Status = 'FAILED' THEN 1
            WHEN ml.Status = 'PROCESSING' AND ml.ModifiedOn < DATEADD(MINUTE,-15,SYSUTCDATETIME()) THEN 1
            ELSE 0
          END)
FROM dbo.tbl_IMG_DocumentCategoryRemap r
JOIN dbo.tbl_IMG_DocumentKeys dk
  ON dk.CategoryKey = r.SourceCategoryKey
 AND dk.SiteCode = r.SiteCode
LEFT JOIN dbo.tbl_IMG_DocumentCategoryRemapMigrationLog ml
  ON ml.RemapID = r.RemapID
 AND ml.SiteCode = r.SiteCode
 AND ml.DocumentKey = dk.DocumentKey
WHERE r.Status IN ('READY','IN_PROGRESS')
GROUP BY r.RemapID, r.SiteCode
ORDER BY EligibleDocs DESC;
```

If this shows the top remap has ~185 eligible docs, you’ve found exactly why you’re only getting 185.

---

## 5) One more serious thing to check: duplicates in MigrationLog

If your MigrationLog has duplicate rows for the same `(SiteCode, RemapID, DocumentKey)`, the LEFT JOIN can behave “weird” and make rows look “already claimed”.

Check:

```sql
SELECT TOP 50 SiteCode, RemapID, DocumentKey, COUNT(*) Dupes
FROM dbo.tbl_IMG_DocumentCategoryRemapMigrationLog
GROUP BY SiteCode, RemapID, DocumentKey
HAVING COUNT(*) > 1
ORDER BY Dupes DESC;
```

If duplicates exist, you should add a unique index/constraint and fix the insert logic.

---

# If you paste results, I’ll tell you the exact fix

Paste outputs of these 3 (just the result grid numbers are enough):

1. `Status counts from tbl_IMG_DocumentCategoryRemap`
2. `ProcessingRows / TimedOutRows` query
3. `Top 20 EligibleDocs by remap` query

Then I’ll tell you **which specific condition** is blocking and what change to make in the proc (or data) to get full batches.
