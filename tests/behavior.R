library(propertycohorts)
passed <- 0L
check <- function(name, code) { force(code); passed <<- passed + 1L; cat("PASS:", name, "\n") }
fails <- function(expr) inherits(tryCatch({force(expr); NULL}, error = identity), "error")
fixture <- synthetic_cohorts()
audit <- function(b = fixture$before, a = fixture$after, ...) audit_cohorts(b, a, "district", ...)
check("synthetic raw increase is entirely composition", {
  x <- audit(); stopifnot(x$summary$raw_change == 1200,
    x$summary$within_change == 0, x$summary$composition_change == 1200)
})
check("unchanged snapshot has zero components", {
  x <- audit(fixture$before, fixture$before); stopifnot(x$summary$within_change == 0, x$summary$composition_change == 0)
})
check("uniform within-cell shift is preserved", {
  a <- fixture$before; a$value <- a$value + 100
  x <- audit(fixture$before, a); stopifnot(abs(x$summary$within_change - 100) < 1e-9, abs(x$summary$composition_change) < 1e-9)
})
check("decomposition identity on nontrivial observations", {
  a <- fixture$after; a$value <- a$value + seq_len(nrow(a))*13
  x <- audit(fixture$before, a); s <- x$summary
  stopifnot(abs(s$common_change-s$within_change-s$composition_change) < 1e-9)
})
check("mixed unit labels reject without FX guesses", {
  a <- fixture$after; a$unit[1] <- "THB/m2"; stopifnot(fails(audit(a = a)))
})
check("all duplicate identifiers in each snapshot excluded", {
  b <- fixture$before; b$listing_id[2] <- b$listing_id[1]
  x <- audit(b = b, min_cell_n = 1); stopifnot(sum(x$exclusions$reason == "duplicate_id") == 2)
})
check("same identifiers across periods are allowed", {
  x <- audit(fixture$before, fixture$before); stopifnot(nrow(x$exclusions) == 0)
})
check("invalid numeric values excluded", {
  b <- fixture$before; b$value[1:3] <- c(NA_real_, Inf, -1)
  x <- audit(b = b, min_cell_n = 1); stopifnot(sum(x$exclusions$reason == "invalid_value") == 3)
})
check("missing labels excluded rather than assigned a district", {
  b <- fixture$before; b$district[1] <- NA_character_
  x <- audit(b = b, min_cell_n = 1); stopifnot(x$exclusions$reason == "missing_stratum")
})
check("one-sided cell reduces coverage and is not extrapolated", {
  a <- fixture$after; a$district[1:2] <- "Only after"
  x <- audit(a = a); stopifnot(any(x$cells$status == "after_only"), x$summary$coverage_after == .8)
})
check("low-count common cells remain visible but unsupported", {
  x <- audit(min_cell_n = 3); stopifnot(all(x$cells$status == "below_min_count"), x$summary$eligible_cells == 0, is.na(x$summary$common_change))
})
check("empty snapshots return explicit unavailable metrics", {
  x <- audit(fixture$before[FALSE, ], fixture$after[FALSE, ]); stopifnot(nrow(x$cells) == 0, is.na(x$summary$raw_change))
})
check("numeric-looking text is not silently parsed", {
  b <- fixture$before; b$value <- as.character(b$value); stopifnot(fails(audit(b = b)))
})
check("factor strata and trimmed labels accepted", {
  b <- fixture$before; b$district <- factor(paste0(" ", b$district, " "))
  stopifnot(audit(b = b)$summary$eligible_cells == 2)
})
check("column role collisions and invalid thresholds reject", {
  stopifnot(fails(audit_cohorts(fixture$before, fixture$after, "listing_id")), fails(audit(min_cell_n = 1.5)))
})
check("tuple keys preserve separator-containing distinct categories", {
  b <- fixture$before; b$district <- rep(c("a|b", "a"), each = 5); b$property_type <- rep(c("c", "b|c"), each = 5)
  x <- audit_cohorts(b, b, c("district", "property_type")); stopifnot(nrow(x$cells) == 2)
})
check("standalone report escapes HTML and neutralizes CSV formulas", {
  b <- fixture$before; b$district <- "=<script>alert(1)</script>"
  x <- audit(b, b); d <- tempfile(); write_cohort_report(x, d)
  h <- paste(readLines(file.path(d, "index.html"), warn = FALSE), collapse = "")
  csv <- paste(readLines(file.path(d, "cells.csv"), warn = FALSE), collapse = "")
  stopifnot(!grepl("<script>", h, fixed = TRUE), grepl("&lt;script&gt;", h, fixed = TRUE), grepl("'=", csv, fixed = TRUE))
})
check("base plot writes without optional packages", {
  f <- tempfile(fileext = ".pdf"); grDevices::pdf(f); plot(audit()); grDevices::dev.off(); stopifnot(file.info(f)$size > 100)
})
cat("Behavioral checks passed:", passed, "\n")
