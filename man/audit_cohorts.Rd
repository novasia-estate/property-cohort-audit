\name{audit_cohorts}
\alias{audit_cohorts}
\alias{print.cohort_audit}
\alias{plot.cohort_audit}
\title{Audit the Comparability of Two Listing Snapshots}
\description{Reports common-cell coverage and descriptive within-cell and composition components of an observed mean difference.}
\usage{
audit_cohorts(before, after, strata, value_col = "value",
  id_col = "listing_id", unit_col = "unit", min_cell_n = 2L)
\method{print}{cohort_audit}(x, ...)
\method{plot}{cohort_audit}(x, ...)
}
\arguments{
\item{before, after}{Data frames representing two supplied snapshots. Each requires a character listing ID, positive finite numeric value, explicit character unit label and the chosen strata columns.}
\item{strata}{One to six distinct categorical column names. Character or factor values are trimmed and remain case-sensitive. No geographic or semantic normalization is inferred.}
\item{value_col, id_col, unit_col}{Distinct column names. Numeric-looking text values must be parsed explicitly by the caller. All nonempty unit labels must agree exactly after trimming; no conversion is attempted.}
\item{min_cell_n}{Positive integer count required in both periods for a cell to be eligible. This threshold does not establish statistical reliability or privacy.}
\item{x}{A result returned by \code{audit_cohorts}.}
\item{...}{For plotting, additional arguments to \code{graphics::barplot}. Otherwise unused.}
}
\details{
Duplicate IDs are checked separately within each snapshot. All occurrences of a duplicate are excluded. The same ID may legitimately appear across periods, but this is a repeated-cross-section comparison, not a paired-property estimator. Exclusions contain original row numbers and one primary reason per row.

Eligible cells meet the minimum count in both snapshots. Cell weights are separately normalized eligible observation counts per period. For each eligible cell with means m0 and m1 and weights w0 and w1, the within component is (w0+w1)/2 times (m1-m0), and the composition component is (m0+m1)/2 times (w1-w0). Sums of these components equal the common-cell mean difference. These are descriptive arithmetic components, not causal effects.

Raw means use all valid observations, while common means use only eligible common cells. When coverage is incomplete the common difference need not equal the raw difference. Unsupported cells remain visible and are not extrapolated. Empty or unsupported samples yield unavailable metrics rather than zero effects.

Unit labels are caller-supplied metadata, not verified currency or measurement semantics. Verify valuation basis, dates, currencies and area definitions before analysis. Asking prices do not establish achieved sale prices. This audit is not a market index, valuation or probability-sample inference.
}
\value{An object of class \code{cohort_audit}, with a one-row \code{summary}, \code{cells} including eligibility and components, \code{exclusions}, selected \code{strata}, \code{min_cell_n} and a method description. Print and plot methods return the object invisibly.}
\examples{
data <- synthetic_cohorts()
result <- audit_cohorts(data$before, data$after, "district")
print(result)
stopifnot(result$summary$within_change == 0)
stopifnot(result$summary$composition_change == 1200)
}
