% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/create_workbook_session.R
\name{create_workbook_session_id}
\alias{create_workbook_session_id}
\title{Erstellt eine workbook session}
\usage{
create_workbook_session_id(workbook_id, token)
}
\arguments{
\item{workbook_id}{Die Id der Excel file}

\item{token}{Der Zugriffstoken fuer MS Graph}
}
\value{
Gibt eine Session_id aus, welche bei Anpassungen im Workbook im Header angegeben werden muss
}
\description{
Diese Funktion erstellt zu einem gegebenem Excel file eine Session. Die Session_id muss bei allen Vorkehrungen
mit dem Excel File im header angegeben werden
}
