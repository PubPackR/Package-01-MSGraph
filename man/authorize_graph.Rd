% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/authorize_MSGraph.R
\name{authorize_graph}
\alias{authorize_graph}
\title{Funktion für den Zugriff auf MS Graph}
\usage{
authorize_graph(tenant_id, client_id, client_secret)
}
\arguments{
\item{tenant_id}{Die tenant_id}

\item{client_id}{Die client_id}

\item{client_secret}{NICHT in das Skript schreiben!!!}
}
\value{
Gibt einen Zugriffstoken fuer MS Graph aus
}
\description{
Diese Funktion nimmt die tenant_id, client_id und den client_secret und erstell einen Zugriffstoken
für MS Graph
}
