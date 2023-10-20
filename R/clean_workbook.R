#' Erstellt ein neues Sheet in einem Excel file
#'
#' Diese Funktion legt in einem bestehendem Excel file ein neues Sheet an und entfernt alle anderen
#'
#' @param workbook_id Die Id der Excel file
#' @param workbook_session_id Die Id um Anpassungen in einem Workbook vorzunehmen
#' @param new_worksheet_name Der Name des neuen Sheets
#' @param token Der Zugriffstoken fuer MS Graph
#'
#' @return Die Funktion gibt die Worksheet_id des neu angelegten Sheets aus
#' @export
#'
#' @examples
#' @importFrom httr content
#' @importFrom httr GET
#' @importFrom httr POST
#' @importFrom httr DELETE
#' @importFrom httr PATCH
#' @importFrom httr add_headers
#'
clean_workbook <- function(workbook_id, workbook_session_id, new_worksheet_name, token){
  studyflix_cloud_id <- "438c7fc9-e4c7-4cdd-a486-61319b1dea2b"
  url <- paste0("https://graph.microsoft.com/v1.0/groups/",
                studyflix_cloud_id,
                "/drive/items/",
                workbook_id,
                "/workbook/worksheets")
  header <- c("authorization" = paste("Bearer", token),
              "workbook-session-id" = workbook_session_id,
              "content-type" = "Application/Json")
  response <- httr::content(httr::GET(url = url, httr::add_headers(header)))

  #create vector with worksheet ids
  worksheet_ids <- c()
  for(i in 1:length(response[["value"]])){
    worksheet_ids <- c(worksheet_ids, response[["value"]][[i]][["id"]])
  }

  #create new worksheet and get the id
  body <- paste0('{ "name": "Temp_sheet" }')
  response <- httr::content(httr::POST(url = url, httr::add_headers(header), body = body))
  new_worksheet_id <- response[["id"]]

  #delete all other worksheets
  for(id in worksheet_ids){
    worksheet_id <- gsub("\\{|\\}", "", id)
    url <- paste0("https://graph.microsoft.com/v1.0/groups/",
                  studyflix_cloud_id,
                  "/drive/items/",
                  workbook_id,
                  "/workbook/worksheets('%7B",
                  worksheet_id,
                  "%7D')")
    response <- httr::content(httr::DELETE(url = url, httr::add_headers(header)))
    if(class(response)!="raw"){
      warning(paste("Could not delete worksheet", id))
    }
  }
  #rename the new worksheet into the given name
  url <- paste0("https://graph.microsoft.com/v1.0/groups/",
                studyflix_cloud_id,
                "/drive/items/",
                workbook_id,
                "/workbook/worksheets('%7B",
                gsub("\\{|\\}", "", new_worksheet_id),
                "%7D')")
  header <- c("authorization" = paste("Bearer", token),
              "workbook-session-id" = workbook_session_id,
              "content-type" = "Application/Json")
  body <- paste0('{ "name": "', new_worksheet_name, '" }')
  httr::PATCH(url = url, httr::add_headers(header), body = body)
  return(new_worksheet_id)
}
