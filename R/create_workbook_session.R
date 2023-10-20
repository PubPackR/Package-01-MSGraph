#' Erstellt eine workbook session
#'
#' Diese Funktion erstellt zu einem gegebenem Excel file eine Session. Die Session_id muss bei allen Vorkehrungen
#' mit dem Excel File im header angegeben werden
#'
#' @param workbook_id Die Id der Excel file
#' @param token Der Zugriffstoken fuer MS Graph
#'
#' @return Gibt eine Session_id aus, welche bei Anpassungen im Workbook im Header angegeben werden muss
#' @export
#'
#' @examples
#' @importFrom httr content
#' @importFrom httr POST
#' @importFrom httr add_headers
create_workbook_session_id <- function(workbook_id, token){
  studyflix_cloud_id <- "438c7fc9-e4c7-4cdd-a486-61319b1dea2b"
  url <- paste0("https://graph.microsoft.com/v1.0/groups/",
                studyflix_cloud_id,
                "/drive/items/",
                workbook_id,
                "/workbook/createSession")
  header <- c("authorization" = paste("Bearer",token), "content-type" = "Application/Json")
  body <- '{ "persistChanges": true }'
  response <- httr::content(httr::POST(url = url, httr::add_headers(header), body = body))
  session_id <- response[["id"]]
  return(session_id)
}
