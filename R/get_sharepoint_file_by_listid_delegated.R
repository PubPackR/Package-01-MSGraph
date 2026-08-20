#' Einzelne SharePoint-Datei ueber ihre List-Item-ID delegiert laden
#'
#' Pendant zu get_sharepoint_data_delegated() fuer den Fall, dass der Account
#' nur Rechte auf der DATEI hat (Item-Freigabe), nicht auf dem Ordner: Das
#' Item wird direkt ueber die SharePoint-List-ID (Spalte "ID" in der
#' Bibliotheksansicht) adressiert statt ueber den Ordnerpfad - die
#' Berechtigungspruefung passiert dann am Item selbst.
#'
#' ACHTUNG: Der Aufrufer ist damit auf genau dieses Item festgenagelt. Die
#' Datei muss im SharePoint immer UEBERSCHRIEBEN werden (neue Version
#' desselben Items) - wird sie durch eine neue Datei ersetzt, liest der Job
#' kommentarlos den alten Stand weiter.
#'
#' @param list_item_id ID aus der SharePoint-Spalte "ID" (Integer oder String).
#' @param file_type Dateityp (xlsx, csv, RDS), geht an read_most_recent_data.
#' @param auth Liste aus authentication_process()$msgraph_sharepoint.
#' @param tmp_folder Lokaler Temp-Ordner (wird bei Bedarf angelegt).
#' @param sheet Sheet-Name oder -Nummer fuer xlsx.
#' @param list_name Anzeigename der Dokumentbibliothek (Default "Dokumente").
#' @param expected_name_starts_with Optionaler Namens-Guard: stoppt, wenn der
#'   Dateiname des Items nicht mit diesem Praefix beginnt. Schuetzt davor,
#'   dass eine falsche/ersetzte Datei kommentarlos eingelesen wird.
#' @return Eingelesener Dateiinhalt (wie get_sharepoint_data_delegated).
#' @export
#' @importFrom Billomatics read_most_recent_data
get_sharepoint_file_by_listid_delegated <- function(list_item_id, file_type,
                                                    auth, tmp_folder, sheet = 1,
                                                    list_name = "Dokumente",
                                                    expected_name_starts_with = NULL) {
  # ---- start ---- #
  site <- msgraph_delegated_get(msgraph_site_lookup_url(auth$site_url), auth)

  ## Bibliothek per Anzeigename finden (Filterung in R statt OData wegen
  ## Sonderzeichen/Encoding im $filter)
  lists <- msgraph_delegated_get(
    paste0("https://graph.microsoft.com/v1.0/sites/", site$id, "/lists"), auth)
  matching <- Filter(function(l) identical(l$displayName, list_name), lists$value)
  if (length(matching) == 0) {
    stop("Dokumentbibliothek '", list_name, "' nicht gefunden auf Site ",
         site$webUrl, call. = FALSE)
  }

  ## List-Item -> driveItem (404 hier = Item existiert nicht ODER Account
  ## hat keine Rechte auf der Datei)
  item <- msgraph_delegated_get(
    paste0("https://graph.microsoft.com/v1.0/sites/", site$id,
           "/lists/", matching[[1]]$id, "/items/", list_item_id, "/driveItem"),
    auth)

  if (!is.null(expected_name_starts_with) &&
      !startsWith(item$name, expected_name_starts_with)) {
    stop("List-Item ", list_item_id, " heisst '", item$name,
         "', erwartet wurde Praefix '", expected_name_starts_with,
         "' - falsche ID oder Datei wurde ersetzt.", call. = FALSE)
  }

  if (!dir.exists(tmp_folder)) {
    dir.create(tmp_folder, recursive = TRUE)
  }
  ## eigener Unterordner, damit parallele Aufrufe sich nicht in die Quere kommen
  tmp_tmp_folder <- paste0(tmp_folder, "tmp", as.integer(runif(1, 1, 10000)))
  dir.create(tmp_tmp_folder)

  token <- msgraph_delegated_token(auth)
  response <- httr::GET(
    paste0("https://graph.microsoft.com/v1.0/drives/",
           item$parentReference$driveId, "/items/", item$id, "/content"),
    httr::add_headers(authorization = paste("Bearer", token)))
  if (response$status_code != 200) {
    stop("Download fehlgeschlagen (HTTP ", response$status_code, "): ",
         item$name, call. = FALSE)
  }
  temp_file_path <- file.path(tmp_tmp_folder,
                              paste0(sub("\\..*", "", item$name), ".", file_type))
  writeBin(httr::content(response, as = "raw"), temp_file_path)

  file <- Billomatics::read_most_recent_data(tmp_tmp_folder, filetype = file_type,
                                             sheet = sheet)
  unlink(tmp_tmp_folder, recursive = TRUE)
  file
}
