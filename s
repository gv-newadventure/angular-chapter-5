function renderPager(totalCount, page, pageSize) {
    var $pager = $('#log-pager').empty();
    var totalPages = Math.max(1, Math.ceil(totalCount / pageSize));

    if (totalPages <= 1) {
        return; // no pager needed
    }

    var maxPagesToShow = 7; // you can tweak this
    var startPage, endPage;

    if (totalPages <= maxPagesToShow) {
        // show all pages
        startPage = 1;
        endPage = totalPages;
    } else {
        // sliding window around current page
        var half = Math.floor(maxPagesToShow / 2);
        startPage = Math.max(1, page - half);
        endPage = Math.min(totalPages, page + half);

        // shift window if we are near the start or end
        if (startPage === 1) {
            endPage = maxPagesToShow;
        } else if (endPage === totalPages) {
            startPage = totalPages - maxPagesToShow + 1;
        }
    }

    function addPageItem(p, text, disabled, active) {
        var li = $('<li/>');
        if (disabled) li.addClass('disabled');
        if (active) li.addClass('active');

        var a = $('<a href="#"/>').text(text);
        if (!disabled && !active) {
            a.on('click', function (e) {
                e.preventDefault();
                loadLog(p);
            });
        }
        li.append(a);
        $pager.append(li);
    }

    // Prev
    addPageItem(page - 1, '«', page === 1, false);

    // First page + leading ellipsis
    if (startPage > 1) {
        addPageItem(1, '1', false, page === 1);
        if (startPage > 2) {
            var liDots = $('<li class="disabled"><span>…</span></li>');
            $pager.append(liDots);
        }
    }

    // Middle pages
    for (var p = startPage; p <= endPage; p++) {
        addPageItem(p, p, false, p === page);
    }

    // Trailing ellipsis + last page
    if (endPage < totalPages) {
        if (endPage < totalPages - 1) {
            var liDots2 = $('<li class="disabled"><span>…</span></li>');
            $pager.append(liDots2);
        }
        addPageItem(totalPages, totalPages, false, page === totalPages);
    }

    // Next
    addPageItem(page + 1, '»', page === totalPages, false);
}
