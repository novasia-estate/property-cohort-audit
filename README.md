# Property Cohort Audit

An R package that checks whether two property-listing snapshots are comparable before interpreting their mean values. It reports excluded observations, unsupported groups, common-cohort coverage and an exact descriptive decomposition into within-group and composition changes. No runtime dependencies outside base R's standard packages.

Developed by [NovAsia Estate](https://novasia.estate/). MIT licensed. This is an audit of supplied listing observations, not a market index, valuation, price forecast or causal estimate.

## Install from the NovAsia organization universe

```r
install.packages("propertycohorts", repos = c(
  "https://novasia-estate.r-universe.dev",
  "https://cloud.r-project.org"
))
```

The package source and universe registry both belong to the **novasia-estate** GitHub organization. [Registry configuration](https://github.com/novasia-estate/novasia-estate.r-universe.dev) · [Package source](https://github.com/novasia-estate/property-cohort-audit).

## A change in observed mix can explain the whole mean difference

```r
library(propertycohorts)
example <- synthetic_cohorts()
result <- audit_cohorts(example$before, example$after, "district")
print(result)
write_cohort_report(result, "cohort-report")
plot(result)
```

The deterministic example contains only invented observations. Central has value 3,000 USD/m2 and Outer 1,000 in both periods. Their observed counts change from 2/8 to 8/2. The all-valid mean changes from 1,400 to 2,600, while the within-cell component is zero and the composition component is +1,200. This example establishes an arithmetic possibility, not a statement about any real market.

## Use your own snapshots

```r
before <- read.csv("before.csv", stringsAsFactors = FALSE)
after <- read.csv("after.csv", stringsAsFactors = FALSE)
result <- audit_cohorts(before, after,
  strata = c("district", "property_type"), min_cell_n = 5)
```

Required defaults: character `listing_id`, numeric `value`, character `unit`, and the chosen categorical columns. IDs must be unique within each snapshot; every occurrence of a duplicated ID is excluded. A recurring ID across snapshots is allowed but does not turn this into a paired-property analysis. Invalid/nonpositive values, missing units and missing category labels are excluded with original input row numbers and one primary reason per row.

All nonempty unit labels must match. Convert currencies and measurements explicitly before passing data in; the package cannot establish that an input labelled USD/m2 actually has that meaning. Check dates, asking/sale-price basis, area definitions and inclusion rules yourself. Categories remain case-sensitive after trimming; no city or property-type inference is made.

## Read coverage before the components

Eligible cells have at least `min_cell_n` valid rows in both periods. One-sided and low-count cells stay in `result$cells` with an explicit status. Coverage shows how much of each period's valid sample is represented. Unsupported cells are not imputed or extrapolated.

The decomposition applies to the **eligible common-cell mean difference**. When coverage is incomplete, this can differ from the all-valid raw difference. The minimum count is a user-controlled screening rule, not a confidence or privacy guarantee.

The [method note](https://github.com/novasia-estate/property-cohort-audit/blob/main/docs/method.md) gives the exact identity, weighting convention and interpretation limits. The [input guide](https://github.com/novasia-estate/property-cohort-audit/blob/main/docs/input.md) covers exclusion precedence and empty samples.

## Reports and privacy

`write_cohort_report` creates a local `index.html` and three CSV tables. It escapes HTML and prefixes spreadsheet-formula-like text in CSV presentation copies. No network, telemetry or automatic data upload is implemented. Reports can contain supplied category labels; review them before sharing. Existing output files with the same names are replaced.

## Reproduce and test

```sh
R CMD build .
R CMD check --no-manual propertycohorts_1.0.0.tar.gz
R CMD INSTALL propertycohorts_1.0.0.tar.gz
Rscript examples/run.R
```

Base-R behavioral checks in `tests/behavior.R` cover composition-only changes, within-cell changes, decomposition identity, unsupported coverage, duplicate IDs, malformed/empty inputs, category-key collisions, HTML escaping, CSV formulas and plotting. No test framework is required.
