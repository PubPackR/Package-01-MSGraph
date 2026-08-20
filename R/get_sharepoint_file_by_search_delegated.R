#' Einzelne SharePoint-Datei per Namenssuche delegiert laden
#'
#' Dritte Zugriffsvariante neben get_sharepoint_data_delegated() (Ordnerpfad,
#' braucht Ordner-Rechte) und get_sharepoint_file_by_listid_delegated()
#' (feste List-ID): findet die Datei ueber die Graph-Suche, die auch mit
#' reinen Datei-Rechten (Item-Freigabe) alle sichtbaren Treffer liefert.
#' Damit muss keine ID im Code hinterlegt werden - die Freigabe der Datei
#' fuer den delegierten Account genuegt.
#'
#' Schutz gegen stille Fehlgriffe: Es wird auf exakten Namens-Praefix und
#' optional auf einen Pfad-Bestandteil der webUrl gefiltert; bei 0 oder
#' mehr als 1 Treffer stoppt die Funktion hart (Mehrdeutigkeit z.B. durch
#' Migrations-/Restore-Kopien). Zu beachten: Die SharePoint-Suche ist
#' eventual consistent - eine geloescht und neu angelegte Datei taucht erst
#' verzoegert auf (Ueberschreiben derselben Datei ist unkritisch). Bei
#' Umbenennung der Datei bricht diese Variante; die List-ID-Variante nicht.
#'
#' @param file_name_starts_with Exakter Namens-Praefix der gesuchten Datei
#'   (dient zugleich als Suchbegriff).
#' @param file_type Dateityp (xlsx, csv, RDS), geht an read_most_recent_data.
#' @param auth Liste aus authentication_process()$msgraph_sharepoint.
#' @param tmp_folder Lokaler Temp-Ordner (wird bei Bedarf angelegt).
#' @param sheet Sheet-Name oder -Nummer fuer xlsx.
#' @param path_must_contain Optionaler Pfad-Bestandteil (z.B.
#'   "01 Leadmanagement"), der in der (dekodierten) webUrl des Treffers
#'   vorkommen muss - schuetzt vor namensgleichen Kopien in anderen Ordnern.
#' @return Eingelesener Dateiinhalt (wie get_sharepoint_data_delegated).
#' @export
#' @importFrom Billomatics read_most_recent_data
get_sharepoint_file_by_search_delegated <- function(file_name_starts_with, file_type,
                                                    auth, tmp_folder, sheet = 1,
                                                    path_must_contain = NULL) {
  # ---- start ---- #
  drive_id <- msgraph_delegated_drive_id(auth)

  ## Suche (matcht Name UND Inhalt - deshalb unten der strikte Namens-Filter);
  ## einfache Anfuehrungszeichen OData-konform doppeln, dann URL-encoden
  term <- utils::URLencode(gsub("'", "''", file_name_starts_with), reserved = TRUE)
  page <- msgraph_delegated_get(
    paste0("https://graph.microsoft.com/v1.0/drives/", drive_id,
           "/root/search(q='", term, "')"), auth)
  hits <- page[["value"]]
  while (!is.null(page[["@odata.nextLink"]])) {
    page <- msgraph_delegated_get(page[["@odata.nextLink"]], auth)
    hits <- c(hits, page[["value"]])
  }

  matches <- Filter(function(h) {
    is_file <- !is.null(h[["file"]])
    name_ok <- startsWith(h[["name"]], file_name_starts_with)
    path_ok <- is.null(path_must_contain) ||
      (!is.null(h[["webUrl"]]) &&
         grepl(path_must_contain, utils::URLdecode(h[["webUrl"]]), fixed = TRUE))
    is_file && name_ok && path_ok
  }, hits)

  if (length(matches) == 0) {
    stop("Keine Datei mit Praefix '", file_name_starts_with, "'",
         if (!is.null(path_must_contain)) paste0(" unter '", path_must_contain, "'"),
         " gefunden - Datei-Freigabe fuer den Account fehlt, Name/Pfad falsch ",
         "oder Such-Index noch nicht aktuell.", call. = FALSE)
  }
  if (length(matches) > 1) {
    stop("Mehrdeutig: ", length(matches), " Dateien mit Praefix '",
         file_name_starts_with, "' gefunden:\n",
         paste(vapply(matches, function(h) utils::URLdecode(h[["webUrl"]]),
                      character(1)), collapse = "\n"),
         "\nMit path_must_contain eindeutig machen.", call. = FALSE)
  }
  item <- matches[[1]]
  item_drive_id <- if (!is.null(item$parentReference$driveId)) {
    item$parentReference$driveId
  } else {
    drive_id
  }

  if (!dir.exists(tmp_folder)) {
    dir.create(tmp_folder, recursive = TRUE)
  }
  ## eigener Unterordner, damit parallele Aufrufe sich nicht in die Quere kommen
  tmp_tmp_folder <- paste0(tmp_folder, "tmp", as.integer(runif(1, 1, 10000)))
  dir.create(tmp_tmp_folder)

  token <- msgraph_delegated_token(auth)
  response <- httr::GET(
    paste0("https://graph.microsoft.com/v1.0/drives/", item_drive_id,
           "/items/", item$id, "/content"),
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
