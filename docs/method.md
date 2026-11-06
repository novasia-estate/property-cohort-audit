# Descriptive decomposition and boundaries

For each eligible common cell s, let n0/n1 be valid observed counts, m0/m1 the period means, and w0/w1 each period's separately normalized eligible-cell count shares.

The observed common-cell difference is `sum(w1*m1) - sum(w0*m0)`.

- Within component: `sum((w0+w1)/2 * (m1-m0))`.
- Composition component: `sum((m0+m1)/2 * (w1-w0))`.

Their sum equals the common-cell observed mean difference by expansion. The within component is a change at fixed average-of-period-shares weights; it is not an average property's appreciation rate. The composition component describes changes in observed shares, not causes of those changes.

Eligibility is defined on both snapshots using the same min_cell_n. Weights are renormalized after this filter. Raw all-valid means may include additional cells, so do not equate their difference to the common-cell decomposition when coverage is below 100%.

Counts are listing observations, not a census of properties or transactions. Multiple distinct listing IDs may still refer to the same property; the package cannot detect that. No sampling model, confidence interval, significance test, inflation adjustment, exchange-rate conversion, seasonal adjustment or geographic reconciliation is performed. Sparse or unrepresentative data remain sparse or unrepresentative after decomposition.

The synthetic example is deterministic: two cells with unchanged means, shifted counts and complete coverage. Additional tests use varied within-cell values and one-sided groups. These establish code behavior and the arithmetic identity, not real-market accuracy.
