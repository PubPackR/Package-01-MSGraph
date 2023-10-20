#' Diese Funktion kopiert einen Ordner (hier von Flowforce) und erstellt ihn in einem Sharepoint-Ordner
#'
#' @param server_path Der lokale Pfad zum Ordner
#' @param folder_item_id Die Item_Id des Ordners in den der Ordner kopiert werden soll
#' @param token Der Zugriffstoken für MS_Graph
#'
#' @return Diese Funktion returnt nichts
#' @export
#'
#' @examples
#' @importFrom httr POST
#' @importFrom httr add_headers
#' @importFrom httr content
#' @importFrom httr PUT
copy_folder_from_server_to_sharepoint <- function(server_path, folder_item_id, token){
  studyflix_cloud_id <- "438c7fc9-e4c7-4cdd-a486-61319b1dea2b"

  #1. Ordner Namen ziehen
  folder_name <- unlist(strsplit(server_path, "/"))[length(strsplit(server_path, "/")[[1]])]
  print(folder_name)

  #2. Neuen Ordner in Sharepoint erstellen
  url <- paste0("https://graph.microsoft.com/v1.0/groups/{", studyflix_cloud_id, "}/drive/items/", folder_item_id, "/children")
  header <- c("authorization" = paste("Bearer",token), "content-type" = "Application/Json")
  body <- paste0('{
  "name": "', folder_name,
  '","folder": { },
  "@microsoft.graph.conflictBehavior": "rename"
  }')

  new_folder_item_id <- content(POST(url, add_headers(header), body = body))[["id"]]
  print(new_folder_item_id)

  #3. Dateien des Ordners abfragen
  all_files <- list.files(server_path, full.names = TRUE)

  if(length(all_files)>0){
    print("Ordner nicht leer")
    for(i in 1:length(all_files)){
      #info über datei holen
      if(file.info(all_files[i])[["isdir"]]){
        print(paste("datei", i, "ist ein ordner"))
        #neuen pfad zu unterordner erstellen
        new_folder_name <- unlist(strsplit(all_files[i], "/"))[length(strsplit(all_files[i], "/")[[1]])]
        new_server_path <- paste0(server_path, new_folder_name, "/")
        copy_folder_from_server_to_sharepoint(server_path = new_server_path, folder_item_id = new_folder_item_id, token)
      }else{
        print(paste("datei", i, "ist kein ordner"))
        file_content <- readBin(all_files[i], what = "raw", n = file.size(all_files[i]))
        #binärdaten uploaden
        url <- paste0("https://graph.microsoft.com/v1.0/groups/{", studyflix_cloud_id, "}/drive/items/", new_folder_item_id, ":/", gsub(".*//", "", all_files[i]), ":/content")
        header <- c("authorization" = paste("Bearer",token), "content-type" = "octet/stream")
        response <- PUT(url, add_headers(header), body = file_content)
      }
    }
  }else{
    print("dieser ordner ist leer")
  }

}
