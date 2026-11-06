# A descriptive repeated-cross-section audit; no population inference.

#' Audit comparability of two listing snapshots
#'
#' See the installed manual for the exact common-cell decomposition.
#' @export
audit_cohorts <- function(before, after, strata, value_col = "value",
                          id_col = "listing_id", unit_col = "unit", min_cell_n = 2L) {
  if (!is.character(strata) || !length(strata) || length(strata) > 6L ||
      anyNA(strata) || any(!nzchar(strata)) || anyDuplicated(strata))
    stop("strata must name 1 to 6 distinct columns")
  roles <- c(value_col, id_col, unit_col)
  if (length(roles) != 3L || anyNA(roles) || any(!nzchar(roles)) ||
      anyDuplicated(c(strata, roles))) stop("Column roles must be distinct names")
  if (length(min_cell_n) != 1L || !is.numeric(min_cell_n) || is.na(min_cell_n) ||
      !is.finite(min_cell_n) || min_cell_n < 1 || min_cell_n != floor(min_cell_n))
    stop("min_cell_n must be a positive integer")
  required <- c(roles, strata)
  for (data in list(before, after)) {
    if (!is.data.frame(data) || anyDuplicated(names(data)) ||
        !all(required %in% names(data))) stop("Inputs must be data frames with distinct required columns")
    if (!is.numeric(data[[value_col]]) || is.complex(data[[value_col]]))
      stop("Values must be numeric; parse numeric text explicitly before auditing")
    if (!is.character(data[[id_col]]) || !is.character(data[[unit_col]]) ||
        !all(vapply(data[strata], function(x) is.character(x) || is.factor(x), logical(1))))
      stop("IDs and units must be character; strata must be character or factor")
  }
  clean_text <- function(x) trimws(as.character(x))
  units <- unique(c(clean_text(before[[unit_col]]), clean_text(after[[unit_col]])))
  units <- units[!is.na(units) & nzchar(units)]
  if (length(units) > 1L) stop("Mixed unit labels: convert and verify units explicitly first")
  unit <- if (length(units)) units else NA_character_
  # A length-prefixed tuple cannot collide when labels contain separators.
  key <- function(data) {
    if (!nrow(data)) return(character())
    vapply(seq_len(nrow(data)), function(i)
      paste(vapply(strata, function(s) {
        x <- enc2utf8(clean_text(data[[s]][i]))
        paste0(nchar(x, type = "bytes"), ":", x)
      }, character(1)), collapse = ""), character(1))
  }
  prepare <- function(data, period) {
    n <- nrow(data); reason <- rep(NA_character_, n)
    id <- clean_text(data[[id_col]])
    add <- function(bad, text) {
      bad[is.na(bad)] <- TRUE
      reason[is.na(reason) & bad] <<- text
    }
    add(is.na(id) | !nzchar(id), "missing_id")
    dup <- duplicated(id) | duplicated(id, fromLast = TRUE)
    add(dup, "duplicate_id")
    v <- data[[value_col]]
    add(!is.finite(v) | v <= 0, "invalid_value")
    u <- clean_text(data[[unit_col]])
    add(is.na(u) | !nzchar(u), "missing_unit")
    for (s in strata) {
      x <- clean_text(data[[s]])
      add(is.na(x) | !nzchar(x), "missing_stratum")
      data[[s]] <- x
    }
    ok <- is.na(reason)
    usable <- data[ok, , drop = FALSE]
    usable$.cohort_key <- key(usable)
    excluded <- data.frame(period = rep(period, sum(!ok)), row = which(!ok),
      reason = reason[!ok], stringsAsFactors = FALSE)
    list(data = usable, excluded = excluded)
  }
  b <- prepare(before, "before"); a <- prepare(after, "after")
  bd <- b$data; ad <- a$data
  all_keys <- sort(unique(c(bd$.cohort_key, ad$.cohort_key)), method = "radix")
  labels <- rbind(bd[, c(strata, ".cohort_key"), drop = FALSE],
                  ad[, c(strata, ".cohort_key"), drop = FALSE])
  labels <- labels[!duplicated(labels$.cohort_key), , drop = FALSE]
  cells <- labels[match(all_keys, labels$.cohort_key), strata, drop = FALSE]
  rownames(cells) <- NULL
  summarize <- function(data) lapply(all_keys, function(k) {
    values <- data[[value_col]][data$.cohort_key == k]
    c(n = length(values), mean = if (length(values)) mean(values) else NA_real_)
  })
  bs <- summarize(bd); as_ <- summarize(ad)
  cells$n_before <- vapply(bs, function(x) x[["n"]], numeric(1))
  cells$n_after <- vapply(as_, function(x) x[["n"]], numeric(1))
  cells$mean_before <- vapply(bs, function(x) x[["mean"]], numeric(1))
  cells$mean_after <- vapply(as_, function(x) x[["mean"]], numeric(1))
  cells$status <- ifelse(cells$n_before == 0, "after_only",
    ifelse(cells$n_after == 0, "before_only",
      ifelse(cells$n_before < min_cell_n | cells$n_after < min_cell_n,
        "below_min_count", "eligible")))
  use <- cells$status == "eligible"
  nb <- sum(cells$n_before[use]); na <- sum(cells$n_after[use])
  cells$weight_before <- cells$weight_after <- cells$within <- cells$composition <- rep(NA_real_, nrow(cells))
  common_before <- common_after <- within <- composition <- NA_real_
  if (any(use)) {
    w0 <- cells$n_before[use] / nb; w1 <- cells$n_after[use] / na
    m0 <- cells$mean_before[use]; m1 <- cells$mean_after[use]
    cells$weight_before[use] <- w0; cells$weight_after[use] <- w1
    cells$within[use] <- (w0 + w1) / 2 * (m1 - m0)
    cells$composition[use] <- (m0 + m1) / 2 * (w1 - w0)
    common_before <- sum(w0 * m0); common_after <- sum(w1 * m1)
    within <- sum(cells$within[use]); composition <- sum(cells$composition[use])
    if (!all(is.finite(c(common_before, common_after, within, composition))))
      stop("Non-finite aggregate: rescale input values")
  }
  safe_mean <- function(x) if (length(x)) mean(x) else NA_real_
  raw_before <- safe_mean(bd[[value_col]]); raw_after <- safe_mean(ad[[value_col]])
  if (any(!is.finite(c(raw_before, raw_after)) & !is.na(c(raw_before, raw_after))))
    stop("Non-finite mean: rescale input values")
  summary <- data.frame(unit = unit, input_before = nrow(before), input_after = nrow(after),
    valid_before = nrow(bd), valid_after = nrow(ad),
    raw_mean_before = raw_before, raw_mean_after = raw_after,
    raw_change = raw_after - raw_before, eligible_cells = sum(use),
    eligible_before = nb, eligible_after = na,
    coverage_before = if (nrow(bd)) nb / nrow(bd) else NA_real_,
    coverage_after = if (nrow(ad)) na / nrow(ad) else NA_real_,
    common_mean_before = common_before, common_mean_after = common_after,
    common_change = common_after - common_before, within_change = within,
    composition_change = composition, stringsAsFactors = FALSE)
  structure(list(summary = summary, cells = cells,
    exclusions = rbind(b$excluded, a$excluded), strata = strata,
    min_cell_n = min_cell_n,
    method = "Symmetric two-period descriptive decomposition on eligible common cells"),
    class = "cohort_audit")
}

#' @export
print.cohort_audit <- function(x, ...) {
  s <- x$summary
  cat("Property listing cohort audit\n")
  cat("Unit:", s$unit, "| valid observations:", s$valid_before, "->", s$valid_after, "\n")
  cat("Eligible common cells:", s$eligible_cells, "| coverage:",
      round(s$coverage_before * 100, 1), "% ->", round(s$coverage_after * 100, 1), "%\n")
  cat("All-valid mean change:", s$raw_change, "\n")
  cat("Common-cell mean change:", s$common_change, "= within", s$within_change,
      "+ composition", s$composition_change, "\n")
  cat("Descriptive supplied-listing audit; not a market index or causal estimate.\n")
  invisible(x)
}

#' @export
plot.cohort_audit <- function(x, ...) {
  s <- x$summary
  if (!s$eligible_cells) stop("No eligible common cells to plot")
  graphics::barplot(c(Common = s$common_change, Within = s$within_change,
    Composition = s$composition_change), col = c("#264653", "#2a9d8f", "#e9c46a"),
    ylab = s$unit, main = "Common-cell descriptive decomposition", ...)
  invisible(x)
}
