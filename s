@if (Model.AppendedSourceFieldLabels.Any() || Model.DiscardedSourceFieldLabels.Any())
{
    <div class="row" style="margin-top:10px;">
        <!-- label column (same alignment as Source/Target/Status) -->
        <div class="col-xs-3 col-sm-3">
            <label class="control-label">Unmapped Source Fields</label>
        </div>

        <!-- value column -->
        <div class="col-xs-9 col-sm-9">
            <p class="text-muted small" style="margin-bottom:8px;">
                Unmapped source fields will either be appended to the document description
                or discarded during migration.
            </p>

            <div class="row">
                @if (Model.AppendedSourceFieldLabels.Any())
                {
                    <div class="col-sm-6">
                        <div class="small text-success" style="margin-bottom:3px;">
                            <span class="glyphicon glyphicon-plus"></span>
                            <strong>Appended</strong>
                        </div>
                        <ul class="list-unstyled small" style="margin-left:2px;">
                            @foreach (var label in Model.AppendedSourceFieldLabels)
                            {
                                <li>
                                    <span class="label label-success" style="display:inline-block; margin-bottom:2px;">
                                        @label
                                    </span>
                                </li>
                            }
                        </ul>
                    </div>
                }

                @if (Model.DiscardedSourceFieldLabels.Any())
                {
                    <div class="col-sm-6">
                        <div class="small text-danger" style="margin-bottom:3px;">
                            <span class="glyphicon glyphicon-remove"></span>
                            <strong>Discarded</strong>
                        </div>
                        <ul class="list-unstyled small" style="margin-left:2px;">
                            @foreach (var label in Model.DiscardedSourceFieldLabels)
                            {
                                <li>
                                    <span class="label label-default" style="display:inline-block; margin-bottom:2px;">
                                        @label
                                    </span>
                                </li>
                            }
                        </ul>
                    </div>
                }
            </div>
        </div>
    </div>
}
