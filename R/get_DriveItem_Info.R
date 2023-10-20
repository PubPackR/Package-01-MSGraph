#funktion für das MSGraph package, welche über einen absoluten pfad die item_id ausgibt
#bei dem absoluten pfad ZUERST \ in / ändern!!!

#' Diese Funktion gibt für eine Datei im Sharepoint Informationen aus
#'
#' @param absolute_path Pfad beginnen mit /General/...
#' @param token Zugriffstoken für MS_Graph
#' @param info Die Info. Zum Beispiel "name", "webUrl", "parentReference", "folder" ... als default "id"
#'
#' @return Gibt die gewählte Info zurück
#' @export
#'
#' @examples
#' @importFrom utils URLencode
#' @importFrom httr GET
#' @importFrom httr add_headers
#' @importFrom httr content
get_DriveItem_Info <- function(absolute_path, token, info = "id"){
  studyflix_cloud_id <- "438c7fc9-e4c7-4cdd-a486-61319b1dea2b"
  #WICHTIG alle \ müssen VOR eingabe in die Funktion geändert werden zu /

  #den pfad formatieren
  clean_path <- URLencode(absolute_path)

  #Request schicken für Id
  url <- paste0("https://graph.microsoft.com/v1.0/groups/{", studyflix_cloud_id, "}/drive/root:", clean_path)
  header <- c("authorization" = paste("Bearer",token), "content-type" = "Application/Json")
  response <- GET(url, add_headers(header))

  if(response[["status_code"]]==200){
    print("Driveitem gefunden")
    return(content(response)[[info]])
  }else{
    print("Driveitem nicht gefunden")
  }


}

