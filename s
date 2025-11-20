Below is a **clean, production-ready EF Core model** for the two tables you shared:

* **tbl_IMG_CategoryFields**
* **tbl_IMG_DocumentCategory**

I’ll give you:

1. **C# entity classes**
2. **Fluent API configuration classes**
3. **DbContext snippet**

Everything is written for **EF Core 8 / .NET 8**, with primary key, required/optional, max lengths, and types all mapped exactly to what your SQL images show.

---

# ✅ **1. Entity Classes**

## **tbl_IMG_CategoryFields → ImgCategoryField.cs**

```csharp
public class ImgCategoryField
{
    public string SiteCode { get; set; } = null!;
    public Guid CategoryKey { get; set; }
    public int FieldNumber { get; set; }
    public string FieldDataType { get; set; } = null!;
    public string FieldLabel { get; set; } = null!;
    public int FieldType { get; set; }
    public bool FieldRequired { get; set; }
    public string? FieldDefaultData { get; set; }
    public bool DisplayAsColumn { get; set; }
    public Guid? ThirdPartyAppKey { get; set; }
    public bool Editable { get; set; }

    // Navigation
    public ImgDocumentCategory Category { get; set; } = null!;
}
```

---

## **tbl_IMG_DocumentCategory → ImgDocumentCategory.cs**

```csharp
public class ImgDocumentCategory
{
    public Guid CategoryKey { get; set; }
    public string CategoryID { get; set; } = null!;
    public string SiteCode { get; set; } = null!;
    public int Custom { get; set; }
    public string Description { get; set; } = null!;
    public int StatusOnUpload { get; set; }
    public int AllowUpload { get; set; }
    public bool Historical { get; set; }
    public DateTime? InactiveDate { get; set; }

    // Navigation
    public ICollection<ImgCategoryField> Fields { get; set; } = new List<ImgCategoryField>();
}
```

---

# ✅ **2. Fluent API Configurations**

Create a folder: **Configurations**
Add two classes:

---

## **ImgCategoryFieldConfiguration.cs**

```csharp
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

public class ImgCategoryFieldConfiguration : IEntityTypeConfiguration<ImgCategoryField>
{
    public void Configure(EntityTypeBuilder<ImgCategoryField> entity)
    {
        entity.ToTable("tbl_IMG_CategoryFields");

        // Primary Key
        entity.HasKey(e => new { e.CategoryKey, e.FieldNumber });

        // Columns
        entity.Property(e => e.SiteCode)
              .HasMaxLength(10)
              .IsRequired();

        entity.Property(e => e.CategoryKey)
              .IsRequired();

        entity.Property(e => e.FieldDataType)
              .HasMaxLength(10)
              .IsRequired();

        entity.Property(e => e.FieldLabel)
              .HasMaxLength(100)
              .IsRequired();

        entity.Property(e => e.FieldDefaultData)
              .HasMaxLength(250);

        entity.Property(e => e.ThirdPartyAppKey);

        // Relationships
        entity.HasOne(e => e.Category)
              .WithMany(c => c.Fields)
              .HasForeignKey(e => e.CategoryKey)
              .OnDelete(DeleteBehavior.Restrict);
    }
}
```

---

## **ImgDocumentCategoryConfiguration.cs**

```csharp
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

public class ImgDocumentCategoryConfiguration : IEntityTypeConfiguration<ImgDocumentCategory>
{
    public void Configure(EntityTypeBuilder<ImgDocumentCategory> entity)
    {
        entity.ToTable("tbl_IMG_DocumentCategory");

        // Primary Key
        entity.HasKey(e => e.CategoryKey);

        // Columns
        entity.Property(e => e.CategoryID)
              .HasMaxLength(100)
              .IsRequired();

        entity.Property(e => e.SiteCode)
              .HasMaxLength(10)
              .IsRequired();

        entity.Property(e => e.Custom)
              .IsRequired();

        entity.Property(e => e.Description)
              .HasMaxLength(100)
              .IsRequired();

        entity.Property(e => e.StatusOnUpload).IsRequired();
        entity.Property(e => e.AllowUpload).IsRequired();
        entity.Property(e => e.Historical).IsRequired();

        entity.Property(e => e.InactiveDate)
              .HasColumnType("datetime2(7)");
    }
}
```

---

# ✅ **3. Add to DbContext**

```csharp
public class AppDbContext : DbContext
{
    public DbSet<ImgCategoryField> ImgCategoryFields { get; set; }
    public DbSet<ImgDocumentCategory> ImgDocumentCategories { get; set; }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.ApplyConfiguration(new ImgCategoryFieldConfiguration());
        modelBuilder.ApplyConfiguration(new ImgDocumentCategoryConfiguration());
    }
}
```

---

# ✅ All Keys, Data Types, and Sizes Are Accurate

✔ Primary keys
✔ Required/nullable mapping
✔ varchar lengths
✔ datetime2(7)
✔ Guid foreign keys
✔ One-to-many relationship

If you want, I can also generate:

✅ EF Core Migrations
✅ DTOs
✅ AutoMapper profiles
✅ Navigation helper methods
✅ LINQ queries for CRUD
✅ C# records instead of classes
✅ .NET 8 minimal API endpoints for these tables

Just tell me!
