@if (Model.AppendedSourceFieldLabels.Any() || Model.DiscardedSourceFieldLabels.Any())
{
    <div class="row" style="margin-top:15px;">
        <div class="col-md-12">

            <h4>Unmapped Source Fields</h4>

            <p class="text-muted">
                Unmapped source fields will either be appended to the document description or discarded during migration.
            </p>

            @if (Model.AppendedSourceFieldLabels.Any())
            {
                <p><strong class="text-success">Appended</strong></p>
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
                <p><strong class="text-danger">Discarded</strong></p>
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