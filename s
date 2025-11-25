@if (Model.AppendedSourceFieldLabels.Any() || Model.DiscardedSourceFieldLabels.Any())
{
    <div style="border: none; padding: 0; margin-top: 10px;">
        <h4 style="margin:0 0 8px 0;">Unmapped Source Fields</h4>

        <p class="text-muted">
            Unmapped source fields will either be appended to the document description or discarded during migration.
        </p>

        @if (Model.AppendedSourceFieldLabels.Any())
        {
            <strong class="text-success">Appended</strong>
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
            <strong class="text-danger">Discarded</strong>
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
}