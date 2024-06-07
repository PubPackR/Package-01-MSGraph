#' Funktion für den Zugriff des aktuellsten Files aus einem Ordner im Sharepoint
#'
#' this function needs the folder, filename, filetype and msgraph key to load the most recent data.
#'
#'
#' @param folder_path A character with the path in the sharepoint which contains the file.
#' @param file_name the name of the file that you want to load.A character with the complete name or start of the sharepoint file name
#' @param file_type The type of file to load, is passed to read_most_recent_data.  A character defining the type of the file (xlsx, csv, RDS)
#' @param msgraph_key the decrypted msgraph key passed to the function  keys$msgraph[1]
#'
#' @return The file that was found in the folder when the name was found - message if the file was not found
#' @importFrom httr POST
#' @importFrom httr add_headers
#' @importFrom httr content
#' @importFrom Billomatics read_most_recent_data
#' @export
get_sharepoint_data <- function(folder_path, file_name, file_type, msgraph_key,tmp_folder) {
  ## authorize ms graph in sharepoint

  tenant_id <- "f34ad13c-3f44-4e15-b70c-cadfbdb6bfb8"
  client_id <- "128a9a89-1fed-4cc6-86f5-4e4b1267108e"
  studyflix_cloud_id <- "438c7fc9-e4c7-4cdd-a486-61319b1dea2b"

  ms_token <- MSGraph::authorize_graph(tenant_id, client_id, client_secret = msgraph_key)

  ## create the tmp_folder
  if(!dir.exists(tmp_folder)) {
    dir.create(tmp_folder,recursive = TRUE)
  }

  ## to take care of the tmp folder being accessible by the user we create it within a given tmp folder
  tmp_tmp_folder <- paste0(tmp_folder,"tmp",as.integer(runif(1,1,10000)))
  dir.create(tmp_tmp_folder)


  # get the folder
  folder_item_id <- MSGraph::get_DriveItem_Info(folder_path, ms_token)
  url <- paste0("https://graph.microsoft.com/v1.0/groups/{", studyflix_cloud_id, "}/drive/items/", folder_item_id, "/children")
  header <- c(authorization = paste("Bearer", ms_token))
  folder_content <- content(httr::GET(url, httr::add_headers(header)))

  if (length(folder_content[["value"]]) > 0) {
    for (i in 1:length(folder_content[["value"]])) {
      file_id <- folder_content[["value"]][[i]][["id"]]
      url_file <- paste0("https://graph.microsoft.com/v1.0/groups/{", studyflix_cloud_id, "}/drive/items/", file_id)
      file_info <- content(httr::GET(url_file, httr::add_headers(header)))

      url_file_content <- paste0("https://graph.microsoft.com/v1.0/groups/{", studyflix_cloud_id, "}/drive/items/", file_id, "/content")
      file_content <- content(httr::GET(url_file_content, httr::add_headers(header)), as = "raw")

      # Create temporary file
      temp_file_path <- tempfile(pattern = sub("\\..*", "_", tmpdir = tmp_tmp_folder,file_info[["name"]]), fileext = paste0(".", file_type))
      writeBin(file_content, temp_file_path)

      # Set last modified date of temporary file to the same date as the sharepoint file
      Sys.setFileTime(temp_file_path, file_info[["fileSystemInfo"]][["lastModifiedDateTime"]])

    }
  } else {
    print("Ordner ist leer")
  }

  # Get temporary directory path
  temp_folder_path <- tmp_tmp_folder

  # Read most recent file
  file <- Billomatics::read_most_recent_data(temp_folder_path, filetyp = file_type, name_starts_with = file_name)

  # Delete temporary directory
  unlink(tmp_tmp_folder, recursive = TRUE)

  return(file)

}
