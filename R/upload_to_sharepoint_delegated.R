#' Dateien delegiert in einen SharePoint-Ordner hochladen
#'
#' Delegiertes Pendant zum Upload-Teil von move_tmpJP5export_to_sharepoint()
#' (base-18): laedt jede Datei per PUT in den Zielordner. Wirft beim ersten
#' fehlgeschlagenen Upload (FlowForce soll den Lauf flaggen).
#'
#' @param local_files Character-Vektor lokaler Dateipfade.
#' @param sharepoint_folder Ziel-Ordner im Drive, beginnend mit /General/...
#' @param auth Liste aus authentication_process()$msgraph_sharepoint.
#' @return invisible(TRUE)
#' @export
upload_to_sharepoint_delegated <- function(local_files, sharepoint_folder, auth) {
  # ---- start ---- #
  drive_id <- msgraph_delegated_drive_id(auth)
  folder_id <- get_DriveItem_Info_delegated(sharepoint_folder, auth)
  token <- msgraph_delegated_token(auth)

  for (file in local_files) {
    filename <- basename(file)
    file_content <- readBin(file, what = "raw", n = file.size(file))
    response <- httr::PUT(
      paste0("https://graph.microsoft.com/v1.0/drives/", drive_id,
             "/items/", folder_id, ":/", utils::URLencode(filename), ":/content"),
      httr::add_headers(authorization = paste("Bearer", token),
                        "content-type" = "application/octet-stream"),
      body = file_content)
    if (!(response$status_code %in% c(200, 201))) {
      stop("Upload fehlgeschlagen (HTTP ", response$status_code, "): ",
           filename, call. = FALSE)
    }
  }
  message(length(local_files), " Datei(en) nach ", sharepoint_folder, " hochgeladen")
  invisible(TRUE)
}
