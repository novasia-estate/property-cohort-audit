#' Write a self-contained local report and formula-safe CSV tables
#' @export
write_cohort_report <- function(x, directory) {
  if (!inherits(x, "cohort_audit")) stop("Expected a cohort_audit result")
  if (length(directory) != 1L || !is.character(directory) || is.na(directory) || !nzchar(directory))
    stop("directory must be one nonempty path")
  dir.create(directory, recursive = TRUE, showWarnings = FALSE)
  if (!dir.exists(directory)) stop("Cannot create report directory")
  escape <- function(v) {
    v <- as.character(v); v[is.na(v)] <- "Not available"
    for (pair in list(c("&", "&amp;"), c("<", "&lt;"), c(">", "&gt;"),
                      c('"', "&quot;"), c("'", "&#39;"))) v <- gsub(pair[1], pair[2], v, fixed = TRUE)
    v
  }
  table_html <- function(df) {
    header <- paste0("<th>", escape(names(df)), "</th>", collapse = "")
    rows <- if (nrow(df)) vapply(seq_len(nrow(df)), function(i)
      paste0("<tr>", paste0("<td>", escape(unlist(df[i, ], use.names = FALSE)), "</td>", collapse = ""), "</tr>"), character(1)) else "<tr><td>No rows</td></tr>"
    paste0('<div class="table"><table><thead><tr>', header,
      "</tr></thead><tbody>", paste(rows, collapse = ""), "</tbody></table></div>")
  }
  csv_safe <- function(df) {
    for (name in names(df)) if (is.character(df[[name]])) {
      dangerous <- !is.na(df[[name]]) & grepl("^[[:space:]]*[=+@-]", df[[name]])
      df[[name]][dangerous] <- paste0("'", df[[name]][dangerous])
    }
    df
  }
  for (name in c("summary", "cells", "exclusions"))
    utils::write.csv(csv_safe(x[[name]]), file.path(directory, paste0(name, ".csv")),
      row.names = FALSE, fileEncoding = "UTF-8", na = "")
  s <- x$summary
  values <- c(s$common_change, s$within_change, s$composition_change)
  max_value <- max(c(abs(values[is.finite(values)]), 1))
  bars <- paste(vapply(seq_along(values), function(i) {
    value <- values[i]; width <- if (is.finite(value)) abs(value) / max_value * 100 else 0
    paste0('<p><strong>', c("Common-cell change", "Within-cell component", "Composition component")[i],
      "</strong>: ", escape(value), " ", escape(s$unit), '</p><div class="track"><span style="width:',
      format(width, scientific = FALSE, decimal.mark = "."), '%"></span></div>')
  }, character(1)), collapse = "")
  html <- paste0('<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Property Cohort Audit</title><style>body{font:16px system-ui;line-height:1.6;max-width:1200px;margin:auto;padding:28px;color:#17353d;background:#f4f7f8}header{background:#17353d;color:white;padding:24px;border-radius:16px}.table{overflow:auto}table{border-collapse:collapse;background:white;width:100%;font-size:14px}th,td{padding:9px;border:1px solid #d1dcdf;text-align:left}.track{background:#dce6e8;height:14px;border-radius:7px}.track span{display:block;background:#2a9d8f;height:14px;border-radius:7px}aside{background:#fff0ca;padding:16px;border-radius:12px}footer{margin-top:25px}</style><header><p>LISTING COMPARABILITY / LOCAL REPORT</p><h1>Property Cohort Audit</h1><p>Separate changes within comparable cells from changes in their observed mix.</p></header><main><h2>Read the coverage first</h2><p>Valid rows: ',
    s$valid_before, " before / ", s$valid_after, " after. Eligible common cells: ", s$eligible_cells,
    ". Coverage of valid observations: ", escape(round(s$coverage_before * 100, 1)), "% before / ",
    escape(round(s$coverage_after * 100, 1)), '% after.</p><aside>Descriptive supplied-listing observations only. This is not a market index, valuation, probability sample or causal estimate. Missing or unsupported cells are not extrapolated. Positive mean changes do not establish price appreciation of the same properties.</aside><h2>Common-cell decomposition</h2><p>Bar lengths show absolute magnitudes; signed numeric values establish direction.</p>',
    bars, "<h2>Summary</h2>", table_html(x$summary), "<h2>Cells and eligibility</h2>",
    table_html(x$cells), "<h2>Excluded rows</h2><p>One primary reason per excluded row. Original row numbers refer to each input snapshot; no private notes are exported.</p>",
    table_html(x$exclusions), '<h2>Method</h2><p>For eligible common cells: within = sum((w0+w1)/2 * (mean1-mean0)); composition = sum((mean0+mean1)/2 * (w1-w0)). Weights are separately normalized eligible-cell counts per period. Within + composition equals the common-cell observed mean difference. This identity need not equal the all-valid raw difference when cells are excluded.</p><p>CSV text beginning with spreadsheet formula markers is prefixed with an apostrophe. Exported CSVs are safe presentation copies, not lossless raw inputs.</p></main><footer>Developed by <a href="https://novasia.estate/">NovAsia Estate</a>. <a href="https://github.com/novasia-estate/property-cohort-audit">Source and method</a>. Local reports can contain your supplied category labels; control access before sharing.</footer></html>')
  writeLines(enc2utf8(html), file.path(directory, "index.html"), useBytes = TRUE)
  invisible(normalizePath(file.path(directory, "index.html"), winslash = "/"))
}
