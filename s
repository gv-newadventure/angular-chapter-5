Gotcha – let’s wire in a **Delete** button on the Details page, show it **only when Status = Draft**, and add a **confirmation** before the delete actually happens.

I’ll give you end-to-end pieces:

* Razor view (Details)
* Controller action
* Repository + SQL (if you don’t already have delete)

You can copy/paste and tweak names/namespaces.

---

## 1️⃣ Razor – `Details.cshtml`

You already have **Back** / **Edit** buttons at the top.
Wrap them in a button group and add Delete right next to Edit, but only when the status is Draft.

```csharp
@model DFXWeb.Areas.ADM.Models.ViewModels.CategoryRemapDetailViewModel

@{
    ViewBag.Title = "Category Remap Details";
}

<div class="btn-group">
    @Html.ActionLink("Back", "Index", null, new { @class = "btn btn-default" })

    @Html.ActionLink(
        "Edit",
        "Edit",
        new { id = Model.Master.RemapID },
        new { @class = "btn btn-primary" })

    @* Delete – only when status is DRAFT *@
    @if (Model.Master.Status != null &&
        Model.Master.Status.Equals("DRAFT", StringComparison.OrdinalIgnoreCase))
    {
        using (Html.BeginForm(
            "Delete",
            "ManageCategoryRemap",
            new { id = Model.Master.RemapID },
            FormMethod.Post,
            new
            {
                @class = "inline-form",
                onsubmit = "return confirm('Are you sure you want to delete this remap? This action cannot be undone.');"
            }))
        {
            @Html.AntiForgeryToken()
            <button type="submit" class="btn btn-danger">
                Delete
            </button>
        }
    }
</div>

<hr />

@* Optional: show success/error messages coming from TempData *@
@if (TempData["SuccessMessage"] != null)
{
    <div class="alert alert-success">
        @TempData["SuccessMessage"]
    </div>
}

@if (TempData["ErrorMessage"] != null)
{
    <div class="alert alert-danger">
        @TempData["ErrorMessage"]
    </div>
}

@* …rest of your existing Details markup (RemapMasterCard, tabs, tables, etc.) *@
```

Notes:

* `onsubmit="return confirm(...)"` shows the browser confirm dialog and **cancels** submit if user clicks *Cancel*.
* The form posts to `ManageCategoryRemapController.Delete(int id)` (see next section).
* `inline-form` can be a tiny CSS rule if buttons are dropping to a new line:

```css
.inline-form {
    display: inline;
}
```

(You can put that in your site css if needed.)

---

## 2️⃣ Controller – `ManageCategoryRemapController`

Add a POST Delete action that:

1. Loads the remap
2. Ensures it’s still Draft
3. Deletes via your service/repository
4. Redirects back to Index with a message

```csharp
using System;
using System.Web.Mvc;
using DFXWeb.Areas.ADM.Models.ViewModels;
using DFXWeb.Areas.ADM.Services;   // whatever your service namespace is

namespace DFXWeb.Areas.ADM.Controllers
{
    [Authorize(Roles = "Admin")] // or whatever you use
    public class ManageCategoryRemapController : Controller
    {
        private readonly ICategoryRemapService _remapService;

        public ManageCategoryRemapController(ICategoryRemapService remapService)
        {
            _remapService = remapService;
        }

        // existing actions (Index, Details, Edit, etc.)

        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult Delete(int id)
        {
            var remap = _remapService.GetRemapMaster(id);
            if (remap == null)
            {
                return HttpNotFound();
            }

            if (!string.Equals(remap.Status, "DRAFT", StringComparison.OrdinalIgnoreCase))
            {
                TempData["ErrorMessage"] = "Only remaps in Draft status can be deleted.";
                return RedirectToAction("Details", new { id });
            }

            try
            {
                _remapService.DeleteRemap(id, User.Identity.Name);
                TempData["SuccessMessage"] = "Remap has been deleted.";
                return RedirectToAction("Index");
            }
            catch (Exception ex)
            {
                // log error if you have logging wired up
                TempData["ErrorMessage"] = "Unable to delete remap. Please try again or contact support.";
                return RedirectToAction("Details", new { id });
            }
        }
    }
}
```

Adjust to your actual service names:

* `ICategoryRemapService`
* `GetRemapMaster(int id)`
* `DeleteRemap(int id, string modifiedBy)`

If you don’t pass `User.Identity.Name` anywhere, drop that argument.

---

## 3️⃣ Service / Repository

If you already have delete logic, just call that from `DeleteRemap`.
If not, here’s a simple pattern.

### 3.1 Service

```csharp
public interface ICategoryRemapService
{
    CategoryRemapMasterDto GetRemapMaster(int id);
    void DeleteRemap(int id, string userName);
}
```

Implementation:

```csharp
public class CategoryRemapService : ICategoryRemapService
{
    private readonly ICategoryRemapRepository _repo;

    public CategoryRemapService(ICategoryRemapRepository repo)
    {
        _repo = repo;
    }

    public CategoryRemapMasterDto GetRemapMaster(int id)
        => _repo.GetRemapMaster(id);

    public void DeleteRemap(int id, string userName)
    {
        // optional: audit, logging, etc. here
        _repo.DeleteRemap(id, userName);
    }
}
```

### 3.2 Repository

```csharp
public interface ICategoryRemapRepository
{
    CategoryRemapMasterDto GetRemapMaster(int id);
    void DeleteRemap(int remapId, string userName);
}
```

```csharp
public void DeleteRemap(int remapId, string userName)
{
    using (var conn = new SqlConnection(_connectionString))
    using (var cmd = new SqlCommand("dbo.sp_IMG_DocumentCategoryRemap_Delete", conn))
    {
        cmd.CommandType = CommandType.StoredProcedure;
        cmd.Parameters.AddWithValue("@RemapID", remapId);
        cmd.Parameters.AddWithValue("@ModifiedBy", userName);

        conn.Open();
        cmd.ExecuteNonQuery();
    }
}
```

### 3.3 SQL Stored Procedure (example)

If you don’t have it yet:

```sql
CREATE OR ALTER PROCEDURE dbo.sp_IMG_DocumentCategoryRemap_Delete
    @RemapID    INT,
    @ModifiedBy UNIQUEIDENTIFIER = NULL  -- if you want it, otherwise drop it
AS
BEGIN
    SET NOCOUNT ON;

    -- Delete children first
    DELETE FROM dbo.tbl_IMG_DocumentCategoryRemapField
    WHERE RemapID = @RemapID;

    DELETE FROM dbo.tbl_IMG_DocumentCategoryRemapMigrationLog
    WHERE RemapID = @RemapID;

    -- Then master
    DELETE FROM dbo.tbl_IMG_DocumentCategoryRemap
    WHERE RemapID = @RemapID
      AND Status = 'DRAFT';  -- extra safety on DB side
END;
```

(You can tighten this based on your schema and FK relationships.)

---

### Quick PR comment you can use

> Added a Delete button on the remap details page.
> Delete is only available for Draft remaps and shows a confirmation dialog before calling the new Delete action.

If you want, I can tweak the button text / confirmation text to match your team’s wording style.
