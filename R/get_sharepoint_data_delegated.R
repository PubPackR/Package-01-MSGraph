#' Aktuellstes File aus einem SharePoint-Ordner delegiert laden
#'
#' Delegiertes Pendant zu get_sharepoint_data(): identisches Verhalten und
#' identische Rueckgabe, nur die Authentifizierung laeuft ueber den
#' Billomatics-Service msgraph_sharepoint (Refresh-Token-Rotation) statt
#' app-only mit hardcodetem Tenant.
#'
#' @param folder_path Ordner-Pfad im Drive, beginnend mit /General/...
#' @param file_name Kompletter Name oder Namensanfang der gesuchten Datei.
#' @param file_type Dateityp (xlsx, csv, RDS), geht an read_most_recent_data.
#' @param auth Liste aus authentication_process()$msgraph_sharepoint.
#' @param tmp_folder Lokaler Temp-Ordner (wird bei Bedarf angelegt).
#' @param sheet Sheet-Nummer fuer xlsx.
#' @return Das gefundene File - Message, wenn nichts gefunden wurde.
#' @export
#' @importFrom Billomatics read_most_recent_data
get_sharepoint_data_delegated <- function(folder_path, file_name, file_type,
                                          auth, tmp_folder, sheet = 1) {
  # ---- start ---- #
  if (!dir.exists(tmp_folder)) {
    dir.create(tmp_folder, recursive = TRUE)
  }
  ## eigener Unterordner, damit parallele Aufrufe sich nicht in die Quere kommen
  tmp_tmp_folder <- paste0(tmp_folder, "tmp", as.integer(runif(1, 1, 10000)))
  dir.create(tmp_tmp_folder)

  download_sharepoint_folder_delegated(folder_path, auth,
                                       dest_dir = tmp_tmp_folder,
                                       file_type = file_type)

  file <- Billomatics::read_most_recent_data(tmp_tmp_folder, filetyp = file_type,
                                             name_starts_with = file_name,
                                             sheet = sheet)
  unlink(tmp_tmp_folder, recursive = TRUE)
  file
}
