<%--
    Description: Shared "Showing X-Y of N" line plus Previous / 1 2 3 ... N / Next
    page links, so the participant list and the My Events lists look and behave
    like the event list. Declared with <%! %> because pagerBar() is a stateless
    method, like esc(). Include ONCE per page:

        <%@ include file="/WEB-INF/common/pagination.jsp" %>

    Use it where the bar should appear:

        <%= pagerBar("participants", "list_participants.jsp?filter=all&p=", pageNum, totalPages, pageSize, totalRows) %>

    base      the link up to and including the page parameter, e.g. "...&p="
              (put other parameters BEFORE it; URL-encode any text in them)
    noun      what is being counted, e.g. "participants"
    The page buttons always show, even with one page (Previous and Next are
    then greyed out), so the list looks the same however many rows it has.
--%>
<%!
    private String pagerBar(String noun, String base, int pageNum, int totalPages, int pageSize, int totalRows) {
        String href = base.replace("&", "&amp;");
        StringBuilder sb = new StringBuilder();
        sb.append("<div class=\"d-flex flex-wrap justify-content-between align-items-center gap-2 mb-3\">");

        if (totalRows == 0) {
            sb.append("<div class=\"small text-muted\">Showing 0 of 0 ").append(noun).append("</div>");
        } else {
            int fromRow = (pageNum - 1) * pageSize + 1;
            int toRow = Math.min(totalRows, pageNum * pageSize);
            sb.append("<div class=\"small text-muted\">Showing ").append(fromRow).append("-").append(toRow)
              .append(" of ").append(totalRows).append(" ").append(noun).append("</div>");
        }

        // always shown - with one page, Previous and Next are simply disabled
        {
            int startPage = Math.max(1, pageNum - 2);
            int endPage = Math.min(totalPages, pageNum + 2);
            sb.append("<ul class=\"pagination pagination-sm mb-0\">");
            sb.append("<li class=\"page-item").append(pageNum == 1 ? " disabled" : "").append("\">")
              .append("<a class=\"page-link\" href=\"").append(href).append(pageNum - 1).append("\">Previous</a></li>");
            if (startPage > 1) {
                sb.append("<li class=\"page-item\"><a class=\"page-link\" href=\"").append(href).append("1\">1</a></li>");
                if (startPage > 2) {
                    sb.append("<li class=\"page-item disabled\"><span class=\"page-link\">&hellip;</span></li>");
                }
            }
            for (int i = startPage; i <= endPage; i++) {
                sb.append("<li class=\"page-item").append(i == pageNum ? " active" : "").append("\">")
                  .append("<a class=\"page-link\" href=\"").append(href).append(i).append("\">").append(i).append("</a></li>");
            }
            if (endPage < totalPages) {
                if (endPage < totalPages - 1) {
                    sb.append("<li class=\"page-item disabled\"><span class=\"page-link\">&hellip;</span></li>");
                }
                sb.append("<li class=\"page-item\"><a class=\"page-link\" href=\"").append(href).append(totalPages)
                  .append("\">").append(totalPages).append("</a></li>");
            }
            sb.append("<li class=\"page-item").append(pageNum == totalPages ? " disabled" : "").append("\">")
              .append("<a class=\"page-link\" href=\"").append(href).append(pageNum + 1).append("\">Next</a></li>");
            sb.append("</ul>");
        }

        sb.append("</div>");
        return sb.toString();
    }
%>