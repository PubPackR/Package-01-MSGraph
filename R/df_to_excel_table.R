#' Dataframe in Excel-Tabelle
#'
#' Die Funktion schreibt einen Dataframe in ein leeres Excel-Sheet in folgenden Schritten:
#' 1. Eine Tabelle wird erstellt mit den Zeilen und Spalten des Dataframes, beginnend bei A1, und die erste Zeile
#' wird der Header mit den Column names des Dataframes
#'
#' 2. Beim Eintragen der Daten wird jede Zeile der Excel Tabelle einzeln addressiert. Die Daten werden Zeile
#' fuer Zeile eingetragen
#'
#' @param workbook_session_id Die zuvor erstellte Workbooksession_Id
#' @param workbook_id Die Id des Workbooks
#' @param worksheet_id Die Id des Sheets in welches der Dataframe geschrieben wird
#' @param worksheet_name Der Name des Sheets
#' @param token Der Zugriffstoken fuer MS Graph
#' @param dataframe Der Dataframe, welcher in das Excel Sheet geschrieben werden soll
#'
#' @return Returnt nichts
#' @export
#'
#' @examples
#' @importFrom httr content
#' @importFrom httr POST
#' @importFrom httr PATCH
#' @importFrom httr add_headers
df_to_excel_table <- function(workbook_session_id, workbook_id, worksheet_id, worksheet_name, token, dataframe){

  #Wichtige ID
  studyflix_cloud_id <- "438c7fc9-e4c7-4cdd-a486-61319b1dea2b"

  #1. zeilen und spalten des df ermitteln und an excel anpassen
  #rows +1 wegen header zeile
  rows <- toString(dim.data.frame(dataframe)[1]+1)
  columns <- dim.data.frame(dataframe)[2]
  column_excel <- numeric_to_excel_column(columns)

  #2. erstellen der tabelle mit gegebener worksheet_id
  url <- paste0("https://graph.microsoft.com/v1.0/groups/", studyflix_cloud_id, "/drive/items/", workbook_id, "/workbook/tables/add")
  header <- c("authorization" = paste("Bearer", token),
              "workbook-session-id" = workbook_session_id,
              "content-type" = "Application/Json")
  body <- paste0('{
  "name" : "Tabelle1",
  "address" : "', worksheet_name, '!A1:', paste0(column_excel, rows),'",
  "hasHeaders" : true }')
  response <- httr::content(httr::POST(url = url, httr::add_headers(header), body = body))
  table_id <- response[["id"]]

  #3. benennen des headers durch die spaltennamen des dataframes
  for(i in 1:columns){
    url <- paste0("https://graph.microsoft.com/v1.0/groups/", studyflix_cloud_id, "/drive/items/", workbook_id, "/workbook/worksheets/%7B", gsub("\\{|\\}", "", worksheet_id) ,"%7D/tables/%7B", gsub("\\{|\\}", "", table_id),"%7D/columns(%27", i ,"%27)")
    header <- c("authorization" = paste("Bearer", token),
                "workbook-session-id" = workbook_session_id,
                "content-type" = "Application/Json")
    body <- paste0('{ "name" : "', colnames(dataframe)[i], '" }')
    httr::PATCH(url = url, httr::add_headers(header), body = body)
  }

  #4. schreiben der zeilen des dataframes in die tabelle
  #dafür schreiben der zeileninhalte in json format
  #und zeile für zeile einfügen
  for (i in 1:dim.data.frame(dataframe)[1]){
    line <- ""
    for(j in 1:dim.data.frame(dataframe)[2]){
      if(is.na(dataframe[i,j])){
        line <- paste0(line, '"",')
      }else{
        line <- paste0(line, '"', gsub('"', '', dataframe[i,j]), '",')
      }
    }
    line <- substr(line, 1, nchar(line) -1)
    json_form <- paste0('[[', line, ']]')
    #erstellen der zeile
    url <- paste0("https://graph.microsoft.com/v1.0/groups/", studyflix_cloud_id, "/drive/items/", workbook_id, "/workbook/worksheets/%7B", gsub("\\{|\\}", "", worksheet_id) ,"%7D/tables/%7B", gsub("\\{|\\}", "", table_id),"%7D/rows/itemAt(index=", i-1,")")
    header <- c("authorization" = paste("Bearer", token),
                "workbook-session-id" = workbook_session_id,
                "content-type" = "Application/Json")
    body <- paste0('{ "values" : ', json_form, ' }')
    response_test <- httr::content(httr::PATCH(url = url, httr::add_headers(header), body = body))
  }

}
