<div class="alert alert-info mt-3">
    @if (Model.AppendedSourceFieldLabels.Any())
    {
        <p><strong>Appended Fields:</strong></p>
        <ul>
            @foreach (var label in Model.AppendedSourceFieldLabels)
            {
                <li>@label</li>
            }
        </ul>
    }

    @if (Model.DiscardedSourceFieldLabels.Any())
    {
        <p><strong>Discarded Fields:</strong></p>
        <ul>
            @foreach (var label in Model.DiscardedSourceFieldLabels)
            {
                <li>@label</li>
            }
        </ul>
    }
</div>
