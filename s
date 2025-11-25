@if (Model.AppendedSourceFieldLabels.Any() || Model.DiscardedSourceFieldLabels.Any())
{
    <div class="row" style="margin-top:15px;">
        <!-- label column, same as Source Category / Target Category -->
        <div class="col-md-3">
            <strong>Unmapped Source Fields</strong>
        </div>

        <!-- value column -->
        <div class="col-md-9">
            <p class="text-muted">
                Unmapped source fields will either be appended to the document description or discarded during migration.
            </p>

            @if (Model.AppendedSourceFieldLabels.Any())
            {
                <p class="text-success" style="margin-bottom:3px;">
                    <strong>Appended</strong>
                </p>
                <ul class="list-unstyled">
                    @foreach (var label in Model.AppendedSourceFieldLabels)
                    {
                        <li>
                            <span class="glyphicon glyphicon-plus text-success"></span> @label
                        </li>
                    }
                </ul>
            }

            @if (Model.DiscardedSourceFieldLabels.Any())
            {
                <p class="text-danger" style="margin-bottom:3px;">
                    <strong>Discarded</strong>
                </p>
                <ul class="list-unstyled">
                    @foreach (var label in Model.DiscardedSourceFieldLabels)
                    {
                        <li>
                            <span class="glyphicon glyphicon-remove text-danger"></span> @label
                        </li>
                    }
                </ul>
            }
        </div>
    </div>
}