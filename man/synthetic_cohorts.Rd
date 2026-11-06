\name{synthetic_cohorts}
\alias{synthetic_cohorts}
\title{Invented Snapshots with a Pure Composition Change}
\description{Creates a small deterministic example in which each district has unchanged values but the observed district shares change. No real properties or market observations are included.}
\usage{synthetic_cohorts()}
\value{A list with \code{before} and \code{after} data frames, each with ten invented observations. Required column names are \code{listing_id}, \code{district}, \code{property_type}, \code{value}, and \code{unit}.}
\examples{
example <- synthetic_cohorts()
nrow(example$before)
}
