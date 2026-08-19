#' Alle Dateien eines SharePoint-Ordners delegiert herunterladen
#'
#' Laedt jede Datei des Ordners nach dest_dir und setzt das lokale
#' Aenderungsdatum auf lastModifiedDateTime der SharePoint-Datei (damit
#' "neueste Datei"-Logik wie Billomatics::read_most_recent_data funktioniert).
#'
#' @param folder_path Ordner-Pfad im Drive, beginnend mit /General/...
#' @param auth Liste aus authentication_process()$msgraph_sharepoint.
#' @param dest_dir Lokales Zielverzeichnis (muss existieren).
#' @param file_type Datei-Endung fuer die lokalen Temp-Namen (xlsx, csv, RDS).
#' @return Character-Vektor der lokalen Dateipfade (leer, wenn Ordner leer).
#' @export
download_sharepoint_folder_delegated <- function(folder_path, auth, dest_dir,
                                                 file_type = "xlsx") {
  # ---- start ---- #
  drive_id <- msgraph_delegated_drive_id(auth)
  folder_id <- get_DriveItem_Info_delegated(folder_path, auth)

  page <- msgraph_delegated_get(
    paste0("https://graph.microsoft.com/v1.0/drives/", drive_id,
           "/items/", folder_id, "/children"), auth)
  items <- page[["value"]]
  while (!is.null(page[["@odata.nextLink"]])) {
    page <- msgraph_delegated_get(page[["@odata.nextLink"]], auth)
    items <- c(items, page[["value"]])
  }

  if (length(items) == 0) {
    message("Ordner ist leer: ", folder_path)
    return(character(0))
  }

  token <- msgraph_delegated_token(auth)
  header <- httr::add_headers(authorization = paste("Bearer", token))

  paths <- character(0)
  for (child in items) {
    ## Ordner-Kinder ueberspringen - /content auf einen Ordner liefert einen Fehlerstatus
    if (is.null(child[["file"]])) next
    response <- httr::GET(
      paste0("https://graph.microsoft.com/v1.0/drives/", drive_id,
             "/items/", child[["id"]], "/content"), header)
    if (response$status_code != 200) {
      stop("Download fehlgeschlagen (HTTP ", response$status_code, "): ",
           child[["name"]], call. = FALSE)
    }
    temp_file_path <- tempfile(pattern = sub("\\..*", "_", child[["name"]]),
                               tmpdir = dest_dir,
                               fileext = paste0(".", file_type))
    writeBin(httr::content(response, as = "raw"), temp_file_path)

    ## so that we keep a date time object, this has to be explicit
    modified_DateTime <- lubridate::as_datetime(
      child[["fileSystemInfo"]][["lastModifiedDateTime"]])
    Sys.setFileTime(temp_file_path, modified_DateTime)
    paths <- c(paths, temp_file_path)
  }
  paths
}
