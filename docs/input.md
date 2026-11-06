# Input and exclusion rules

Read CSV data explicitly and inspect numeric types and unit labels before auditing. Values must already be finite positive numerics. IDs/units are character columns; strata are character or factors. Missing or duplicate required column names reject the batch. Column roles must be distinct.

Within each snapshot, first applicable exclusion wins: missing ID, duplicated ID (all occurrences), invalid value, missing unit, missing stratum. Row numbers are positions in that snapshot, not line numbers in a quoted CSV file. A row with several problems appears once under its first reason.

Mixed nonempty unit labels reject the entire comparison even if some affected rows would otherwise be excluded. Blank unit rows are excluded. A wholly empty or invalid sample returns unavailable metrics instead of numeric zero changes. No eligible common cells means no decomposition and plot() raises a clear error.

Stratum keys use length-prefixed UTF-8 tuples so delimiters inside labels do not conflate different combinations. Text is trimmed, not transliterated or case-folded. Two spellings of one district remain separate unless you reconcile them deliberately beforehand.

The returned cells table contains category labels, period counts/means, eligibility, weights and signed components. Exclusions export only period, input row and reason. HTML escapes text; CSV formula protection prefixes dangerous character fields with an apostrophe, so exported presentation CSVs should not be used as lossless source data.
