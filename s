@if (Model.AppendedSourceFieldLabels.Any() || Model.DiscardedSourceFieldLabels.Any())
{
    <div style="border: 1px solid #ddd; border-radius: 4px; padding: 15px; margin-top: 15px;">
        <h4 style="margin-top:0;">Unmapped Source Fields</h4>

        <p class="text-muted">
            Unmapped source fields will either be appended to the document description
            or discarded during migration.
        </p>

        <div class="row">

            @if (Model.AppendedSourceFieldLabels.Any())
            {
                <div class="col-md-6" style="margin-bottom:10px;">
                    <strong class="text-success">Appended</strong>
                    <ul class="list-unstyled" style="margin-top:8px;">
                        @foreach (var label in Model.AppendedSourceFieldLabels)
                        {
                            <li>
                                <span class="glyphicon glyphicon-plus text-success"></span>
                                @label
                            </li>
                        }
                    </ul>
                </div>
            }

            @if (Model.DiscardedSourceFieldLabels.Any())
            {
                <div class="col-md-6" style="margin-bottom:10px;">
                    <strong class="text-danger">Discarded</strong>
                    <ul class="list-unstyled" style="margin-top:8px;">
                        @foreach (var label in Model.DiscardedSourceFieldLabels)
                        {
                            <li>
                                <span class="glyphicon glyphicon-remove text-danger"></span>
                                @label
                            </li>
                        }
                    </ul>
                </div>
            }

        </div>
    </div>
}
else
{
    <div class="alert alert-info" style="margin-top:10px;">
        No unmapped source fields. All fields are mapped to target fields.
    </div>
}