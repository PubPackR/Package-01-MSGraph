#' Wandelt eine Dezimalzahl in eine Excel-Zahl um
#'
#' @param zahl Die umzuwandelnde Dezimalzahl
#'
#' @return Gibt die Excel-Zahl aus
#' @export
#'
#' @examples
#' numeric_to_excel_column(30)
numeric_to_excel_column <- function(zahl) {
  spalte <- ""
  while (zahl > 0) {
    rest <- (zahl - 1) %% 26
    spalte <- paste0(LETTERS[rest + 1], spalte)
    zahl <- (zahl - rest) %/% 26
  }
  return(spalte)
}
