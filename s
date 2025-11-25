@if (Model.AppendedSourceFieldLabels.Any() || Model.DiscardedSourceFieldLabels.Any())
{
    <div class="panel panel-default" style="margin-top:10px;">
        <div class="panel-heading">
            <strong>Unmapped Source Fields</strong>
        </div>
        <div class="panel-body">

            <p class="text-muted" style="margin-bottom:15px;">
                Unmapped source fields will either be appended to the document description
                or discarded during migration.
            </p>

            <div class="row">
                @if (Model.AppendedSourceFieldLabels.Any())
                {
                    <div class="col-md-6">
                        <h5 style="margin-top:0;">
                            <span class="label label-success">Appended</span>
                        </h5>
                        <ul class="list-unstyled">
                            @foreach (var label in Model.AppendedSourceFieldLabels)
                            {
                                <li>
                                    <span class="glyphicon glyphicon-plus" aria-hidden="true"></span>
                                    @label
                                </li>
                            }
                        </ul>
                    </div>
                }

                @if (Model.DiscardedSourceFieldLabels.Any())
                {
                    <div class="col-md-6">
                        <h5 style="margin-top:0;">
                            <span class="label label-default">Discarded</span>
                        </h5>
                        <ul class="list-unstyled">
                            @foreach (var label in Model.DiscardedSourceFieldLabels)
                            {
                                <li>
                                    <span class="glyphicon glyphicon-remove" aria-hidden="true"></span>
                                    @label
                                </li>
                            }
                        </ul>
                    </div>
                }
            </div>
        </div>
    </div>
}
else
{
    <div class="alert alert-info" style="margin-top:10px;">
        No unmapped source fields. All fields are mapped directly to the target category.
    </div>
}