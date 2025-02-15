#' Upload Files to SharePoint
#'
#' This function uploads files from a specified local folder to a SharePoint directory
#' The function does not retain the folder structure
#' If a file already exists in the target directory, it will be overwritten
#'
#' @param tenant_id Character. Microsoft Graph API tenant ID
#' @param client_id Character. Microsoft Graph API client ID
#' @param studyflix_cloud_id Character. Microsoft Graph API cloud ID
#' @param key_msgraph Character. Microsoft Graph API client secret
#' @param path_on_sharepoint Character. SharePoint target path
#' @param path_to_folder Character. Local path containing files/folder
#' @param cleanup Logical. Delete local files and subfolders after successful upload
#'
#' @return NULL
#' @export
#' @importFrom httr PUT
#' @importFrom httr add_headers
#' @importFrom httr status_code
copy_folder_from_server_to_sharepoint <- function(tenant_id, client_id, studyflix_cloud_id, key_msgraph, path_on_sharepoint, path_to_folder, cleanup = FALSE) {
  ## ----- Auth -----
  ms_token <- MSGraph::authorize_graph(client_id = client_id, tenant_id = tenant_id, client_secret = key_msgraph)
  folder_id <- MSGraph::get_DriveItem_Info(path_on_sharepoint, token = ms_token)

  ## ----- Upload Files to Sharepoint -----
  all_files <- list.files(path_to_folder, full.names = TRUE, recursive = TRUE)
  print(paste("Uploading", length(all_files), "files to Sharepoint..."))

  for (file in all_files) {
    filename <- basename(file)
    file_content <- readBin(file, what = "raw", n=file.size(file))

    url <- paste0("https://graph.microsoft.com/v1.0/groups/{", studyflix_cloud_id, "}/drive/items/", folder_id, ":/", filename, ":/content")
    header <- c("authorization" = paste("Bearer",ms_token), "content-type" = "octet/stream")
    response <- httr::PUT(url, httr::add_headers(header), body = file_content)

    # Error handling
    if (!(httr::status_code(response) %in% c(200, 201))) {
      error_message <- paste("File transfer failed. Status code:", httr::status_code(response))
      stop(error_message)
    }
  }
  print("Files uploaded successfully")

  ## ----- CleanUp -----
  if (cleanup) {
    # Remove all the files from the folder after uploading
    unlink(path_to_folder, recursive = TRUE, force = TRUE)
    dir.create(path_to_folder)
    print("Folder cleaned successfully")
  }
}
