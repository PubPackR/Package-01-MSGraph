#' DriveItem-Info ueber den delegierten SharePoint-Zugriff
#'
#' Delegiertes Pendant zu get_DriveItem_Info(): loest einen absoluten Pfad
#' (beginnend mit /General/...) im Drive der konfigurierten Site auf.
#' Wirft bei Nicht-Fund einen Fehler (FlowForce soll Fehlversuche flaggen).
#'
#' @param absolute_path Pfad beginnend mit /General/... (Backslashes vorher zu / aendern).
#' @param auth Liste aus authentication_process()$msgraph_sharepoint.
#' @param info Die Info, z. B. "name", "webUrl", "parentReference" - Default "id".
#' @return Der gewaehlte Info-Wert des DriveItems.
#' @export
#' @importFrom utils URLencode
get_DriveItem_Info_delegated <- function(absolute_path, auth, info = "id") {
  # ---- start ---- #
  drive_id <- msgraph_delegated_drive_id(auth)
  clean_path <- utils::URLencode(absolute_path)
  item <- msgraph_delegated_get(
    paste0("https://graph.microsoft.com/v1.0/drives/", drive_id, "/root:", clean_path),
    auth)
  item[[info]]
}
