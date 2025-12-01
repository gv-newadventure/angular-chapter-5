IF OBJECT_ID('dbo.sp_IMG_DocumentCategoryRemap_Update', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_IMG_DocumentCategoryRemap_Update;
GO

CREATE PROCEDURE dbo.sp_IMG_DocumentCategoryRemap_Update
(
      @RemapID           INT
    , @Name              NVARCHAR(300) = NULL
    , @SiteCode          NVARCHAR(10)
    , @SourceCategoryKey UNIQUEIDENTIFIER
    , @TargetCategoryKey UNIQUEIDENTIFIER
    , @AppendUnmapped    BIT = 0
    , @Status            VARCHAR(25)   -- 'DRAFT' | 'READY'
    , @ModifiedBy        UNIQUEIDENTIFIER
    , @Fields            dbo.UTT_DocumentCategoryRemapField READONLY
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Err      INT;
    DECLARE @ProcName SYSNAME = OBJECT_NAME(@@PROCID);

    ----------------------------------------------------------------------
    -- 0. Basic validations (no transaction needed)
    ----------------------------------------------------------------------
    IF NOT EXISTS
    (
        SELECT 1
        FROM dbo.tbl_IMG_DocumentCategoryRemap WITH (UPDLOCK, HOLDLOCK)
        WHERE RemapID = @RemapID
    )
    BEGIN
        RAISERROR('RemapID %d not found.', 16, 1, @RemapID);
        RETURN;
    END

    -- Validate to make sure the Source Category Key is not already remapped
    IF EXISTS
    (
        SELECT 1
        FROM dbo.tbl_IMG_DocumentCategoryRemap WITH (NOLOCK)
        WHERE SourceCategoryKey = @SourceCategoryKey
          AND RemapID <> @RemapID   -- ensure not another mapping
          AND Status IN ('DRAFT', 'READY')
          AND IsActive = 1
    )
    BEGIN
        RAISERROR('A remap for this source category already exists in an active state.', 16, 1);
        RETURN;
    END

    ----------------------------------------------------------------------
    -- 1. Start transactional work
    ----------------------------------------------------------------------
    BEGIN TRAN;

    ----------------------------------------------------------------------
    -- 1a. Recalculate TotalDocuments
    ----------------------------------------------------------------------
    DECLARE @TotalDocuments INT;

    SELECT @TotalDocuments = COUNT(*)
    FROM tbl_IMG_DocumentKeys dk
    INNER JOIN tbl_IMG_DocumentData dd
        ON dd.DocumentKey = dk.DocumentKey
    INNER JOIN tbl_IMG_DocumentCategory dc
        ON dc.CategoryKey = dk.CategoryKey
    WHERE dc.SiteCode     = @SiteCode
      AND dc.CategoryKey  = @SourceCategoryKey;

    SELECT @Err = @@ERROR;
    IF @Err <> 0 GOTO ErrorHandler;

    ----------------------------------------------------------------------
    -- 1b. Update MASTER row
    ----------------------------------------------------------------------
    UPDATE dbo.tbl_IMG_DocumentCategoryRemap
    SET     SourceCategoryKey         = @SourceCategoryKey,
            TargetCategoryKey         = @TargetCategoryKey,
            AppendUnmappedCategories  = @AppendUnmapped,
            [Status]                  = @Status,
            [Name]                    = @Name,
            ModifiedBy                = @ModifiedBy,
            ModifiedOn                = SYSDATETIME(),
            TotalDocuments            = @TotalDocuments
    WHERE   RemapID = @RemapID;

    SELECT @Err = @@ERROR;
    IF @Err <> 0 GOTO ErrorHandler;

    ----------------------------------------------------------------------
    -- 1c. Replace DETAIL rows for this RemapID
    ----------------------------------------------------------------------
    DELETE FROM dbo.tbl_IMG_DocumentCategoryRemapField
    WHERE RemapID = @RemapID;

    SELECT @Err = @@ERROR;
    IF @Err <> 0 GOTO ErrorHandler;

    ----------------------------------------------------------------------
    -- 1d. Re-insert DETAIL rows (same logic as your WITH/INSERT)
    --     If you had extra normalization on SortOrder in the CTE,
    --     keep that inside the WITH block here.
    ----------------------------------------------------------------------
    ;WITH N AS
    (
        SELECT
              SourceFieldNumber
            , TargetFieldNumber
            , [Action]
            , DefaultValue
            , SortOrder
        FROM @Fields
        -- add any ROW_NUMBER() / normalization here if you had it
    )
    INSERT INTO dbo.tbl_IMG_DocumentCategoryRemapField
    (
          SiteCode
        , RemapID
        , SourceCategoryKey
        , TargetCategoryKey
        , SourceFieldNumber
        , TargetFieldNumber
        , [Action]
        , SortOrder
        , DefaultValue
        , ModifiedBy
        , ModifiedOn
    )
    SELECT
          @SiteCode
        , @RemapID
        , @SourceCategoryKey
        , @TargetCategoryKey
        , N.SourceFieldNumber
        , N.TargetFieldNumber
        , N.[Action]
        , N.SortOrder
        , N.DefaultValue
        , @ModifiedBy
        , SYSDATETIME()
    FROM N;

    SELECT @Err = @@ERROR;
    IF @Err <> 0 GOTO ErrorHandler;

    ----------------------------------------------------------------------
    -- SUCCESS
    ----------------------------------------------------------------------
    COMMIT TRAN;
    RETURN 0;

    ----------------------------------------------------------------------
    -- CENTRAL ERROR HANDLER (old-school pattern)
    ----------------------------------------------------------------------
ErrorHandler:
    IF @@TRANCOUNT > 0
        ROLLBACK TRAN;

    IF @Err IS NULL
        SET @Err = -1;

    DECLARE @Msg NVARCHAR(2048);
    SET @Msg = @ProcName + N' failed with error code ' + CONVERT(NVARCHAR(20), @Err) + N'.';

    RAISERROR(@Msg, 16, 1);
    RETURN @Err;
END
GO
