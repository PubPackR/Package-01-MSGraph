#' Diese Funktion kopiert einen Ordner vom Sharepoint in einen Ordner (hier vom Server)
#'
#' @param folder_item_id Die Item_Id des zu kopierenden Ordners
#' @param server_path Der lokale Pfad an den der Ordner kopiert werden soll
#' @param token Der Zugriffstoken für MS_Graph
#'
#' @return Diese Funktion returnt nichts
#' @export
#'
#' @examples
#' @importFrom httr GET
#' @importFrom httr add_headers
#' @importFrom httr content
copy_folder_from_sharepoint_to_server <- function(folder_item_id, server_path, token){
  studyflix_cloud_id <- "438c7fc9-e4c7-4cdd-a486-61319b1dea2b"


  #1.ordner namen ziehen
  url <- paste0("https://graph.microsoft.com/v1.0/groups/{", studyflix_cloud_id, "}/drive/items/", folder_item_id)
  header <- c("authorization" = paste("Bearer",token))
  folder_content <- content(GET(url, add_headers(header)))

  folder_name <- folder_content[["name"]]
  pfad_zum_neuen_ordner <- paste0(server_path, folder_name, "/")
  #ordner erstellen
  dir.create(pfad_zum_neuen_ordner)
  print(pfad_zum_neuen_ordner)

  #2.dateien des ordners abfragen
  url <- paste0("https://graph.microsoft.com/v1.0/groups/{", studyflix_cloud_id, "}/drive/items/", folder_item_id, "/children")
  header <- c("authorization" = paste("Bearer",token))
  folder_children <- content(GET(url, add_headers(header)))

  if(length(folder_children[["value"]])>0){
    print("ordner nicht leer")
    for(i in 1:length(folder_children[["value"]])){
      #abfrage an children files stellen
      children_id <- folder_children[["value"]][[i]][["id"]]
      url_children <- paste0("https://graph.microsoft.com/v1.0/groups/{", studyflix_cloud_id, "}/drive/items/", children_id)
      header <- c("authorization" = paste("Bearer",token))
      children_info <- content(GET(url_children, add_headers(header)))

      #testen ob children selbst auch wieder ordner ist
      if(is.null(children_info[["file"]])){
        print(paste("datei", i, "ist ein ordner"))
        #dann ist children wieder ein ordner und wir rufen erneut gleiche funktion auf
        copy_folder_from_sharepoint_to_server(children_id, pfad_zum_neuen_ordner, token)
      }else{
        print(paste("datei", i, "ist kein ordner"))
        url_children_content <- paste0("https://graph.microsoft.com/v1.0/groups/{", studyflix_cloud_id, "}/drive/items/", children_id, "/content")
        header <- c("authorization" = paste("Bearer",token))
        children_content <- content(GET(url_children_content, add_headers(header)), as = "raw")

        #erstellen der datei im server unter gleichem namen
        pfad_zur_datei <- paste0(pfad_zum_neuen_ordner, children_info[["name"]])

        writeBin(children_content, pfad_zur_datei)
      }


    }
  }else{
    print("der ordner ist leer")
  }

}
