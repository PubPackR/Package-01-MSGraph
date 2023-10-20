#' Funktion für den Zugriff auf MS Graph
#'
#' Diese Funktion nimmt die tenant_id, client_id und den client_secret und erstell einen Zugriffstoken
#' für MS Graph
#'
#'
#' @param tenant_id Die tenant_id
#' @param client_id Die client_id
#' @param client_secret NICHT in das Skript schreiben!!!
#'
#' @return Gibt einen Zugriffstoken fuer MS Graph aus
#' @export
#'
#' @examples
#' @importFrom httr POST
#' @importFrom httr add_headers
#' @importFrom httr content
authorize_graph <- function(tenant_id, client_id, client_secret){
  URI <- paste0("https://login.microsoftonline.com/",tenant_id, "/oauth2/v2.0/token")
  headers <- c("Host" = "login.microsoftonline.com",
               "Content-Type" = "application/x-www-form-urlencoded")
  body <- paste0("client_id=",
                 client_id,
                 "&scope=https%3A%2F%2Fgraph.microsoft.com%2F.default",
                 "&client_secret=",
                 client_secret,
                 "&grant_type=client_credentials")

  token <- httr::content(httr::POST(URI,
                        config = httr::add_headers(headers),
                        body = body), as="parsed")$access_token
  return(token)
}
