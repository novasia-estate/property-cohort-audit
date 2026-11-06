\name{write_cohort_report}
\alias{write_cohort_report}
\title{Write a Portable Local Audit Report}
\description{Writes a self-contained HTML report, summary.csv, cells.csv and exclusions.csv. No network request or automatic upload is performed. Existing files with these names are replaced.}
\usage{write_cohort_report(x, directory)}
\arguments{
\item{x}{A \code{cohort_audit} result.}
\item{directory}{Local destination directory. Created recursively if needed.}
}
\details{HTML text is escaped. CSV character values whose trimmed prefix is a spreadsheet formula marker are prefixed with an apostrophe. These CSVs are presentation copies, not lossless raw data. Reports contain supplied category labels; control access before sharing. Bar lengths show absolute component magnitudes and labels show their signed values.}
\value{Invisibly returns the normalized path of the HTML report.}
\examples{
data <- synthetic_cohorts()
result <- audit_cohorts(data$before, data$after, "district")
report <- write_cohort_report(result, tempfile("cohort-report-"))
file.exists(report)
}
