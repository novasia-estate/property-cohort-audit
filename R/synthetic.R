#' Invented listing snapshots demonstrating a pure composition change
#' @export
synthetic_cohorts <- function() {
  make <- function(prefix, counts, prices) {
    district <- rep(c("Example Central", "Example Outer"), counts)
    data.frame(listing_id = paste0(prefix, seq_along(district)),
      district = district, property_type = "Apartment", value = rep(prices, counts),
      unit = "USD/m2", stringsAsFactors = FALSE)
  }
  list(before = make("B-", c(2, 8), c(3000, 1000)),
       after = make("A-", c(8, 2), c(3000, 1000)))
}
