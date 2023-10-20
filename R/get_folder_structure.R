
#' Listet alle Elemente eines Ordners als Dataframe auf
#'
#' @param group_id Die Group / das Team in dem der Ordner liegt
#' @param folder_id Der relevante Ordner
#' @param dataframe Format muss: Name, Pfad, Driveitem_id, Typ, Parent_id
#' @param token Der Zugriffstoken für MS Graph
#'
#' @return Returnt den Dataframe mit den Infos zu allen Elementen
#' @export
#'
#' @examples
get_folder_structure <- function(group_id, folder_id, dataframe, token){

  #variablen setzen
  name <- NA
  pfad <- NA
  driveitem_id <- NA
  typ <- NA
  parent_id <- NA

  #abfrage
  url <- paste0("https://graph.microsoft.com/v1.0/groups/", group_id, "/drive/items/", folder_id)
  header <- c("authorization" = paste("Bearer",token))
  response <- GET(url, add_headers(header))
  content <- content(response)

  #informationen zuordnen
  name <- content[["name"]]
  pfad <- paste0(content[["parentReference"]][["path"]], "/", name)
  driveitem_id <- content[["id"]]
  parent_id <- content[["parentReference"]][["id"]]

  #prüfen ob Ordner oder file
  if(!is.null(content[["folder"]])){
    #dann ordner
    typ <- "Ordner"
  }
  if(!is.null(content[["file"]])){
    #dann datei
    typ <- "Datei"
  }

  #informationen an df anhängen
  neue_zeile <- c(name, pfad, driveitem_id, typ, parent_id)
  dataframe <- rbind(dataframe, neue_zeile)

  #wenn datei ein ordner -> funktion rekursiv aufrufen
  if(typ=="Ordner"){
    #inhalte des ordners auflisten
    url <- paste0("https://graph.microsoft.com/v1.0/groups/", group_id, "/drive/items/", folder_id, "/children")
    header <- c("authorization" = paste("Bearer",token))
    response <- GET(url, add_headers(header))
    folder_content <- content(response)

    #alle elemente durch iterieren, falls ordner nicht leer
    if(length(folder_content[["value"]])>0){
      #ordner nicht leer
      for(i in 1:length(folder_content[["value"]])){
        dataframe <- get_folder_structure(group_id, folder_id = folder_content[["value"]][[i]][["id"]], dataframe, token)
      }
    }
  }
  return(dataframe)
}
