################################################################################-
# ----- Description -------------------------------------------------------------
#
# Delegierter SharePoint-Zugriff (neuer Tenant): Drive-Aufloesung ueber die
# Site-URL statt der alten hardcodierten Gruppen-GUID. Token kommt aus
# Billomatics::msgraph_sharepoint_token_provider() (rotierender Refresh-Store).
# Spec: Billomatics docs/superpowers/specs/2026-08-18-msgraph-sharepoint-
# delegated-design.md
# ------------------------------------------------------------------ #
# Authors@R: Moritz Hemmann
# Date: 2026/08
#

.msgraph_drive_cache <- new.env(parent = emptyenv())

#' Access-Token aus der Billomatics-Auth-Liste holen (intern)
#' @noRd
msgraph_delegated_token <- function(auth) {
  # ---- start ---- #
  provider <- Billomatics::msgraph_sharepoint_token_provider(auth)
  provider()
}

#' Graph-Lookup-URL fuer eine SharePoint-Site-URL bauen (intern)
#' @noRd
msgraph_site_lookup_url <- function(site_url) {
  # ---- start ---- #
  u <- httr::parse_url(site_url)
  path <- sub("/+$", "", paste(u$path, collapse = "/"))
  if (is.null(u$hostname) || !nzchar(path)) {
    stop("site_url muss Hostname UND Site-Pfad enthalten, z. B. ",
         "https://<host>.sharepoint.com/sites/<name> - erhalten: ", site_url,
         call. = FALSE)
  }
  paste0("https://graph.microsoft.com/v1.0/sites/", u$hostname, ":/", path)
}

#' GET gegen Graph mit delegiertem Token (intern) - wirft bei HTTP != 200
#' @noRd
msgraph_delegated_get <- function(url, auth) {
  # ---- start ---- #
  token <- msgraph_delegated_token(auth)
  response <- httr::GET(url, httr::add_headers(
    authorization = paste("Bearer", token)))
  parsed <- httr::content(response)
  if (response$status_code != 200) {
    msg <- if (!is.null(parsed$error$message)) parsed$error$message else "keine Details"
    stop("Graph-GET fehlgeschlagen (HTTP ", response$status_code, "): ",
         url, "\n", msg, call. = FALSE)
  }
  parsed
}

#' Drive-ID der konfigurierten Site aufloesen (intern, Session-Cache)
#' @noRd
msgraph_delegated_drive_id <- function(auth) {
  # ---- start ---- #
  cached <- .msgraph_drive_cache[[auth$site_url]]
  if (!is.null(cached)) return(cached)
  site <- msgraph_delegated_get(msgraph_site_lookup_url(auth$site_url), auth)
  drive <- msgraph_delegated_get(
    paste0("https://graph.microsoft.com/v1.0/sites/", site$id, "/drive"), auth)
  .msgraph_drive_cache[[auth$site_url]] <- drive$id
  drive$id
}
