% Generated by roxygen2 (4.1.1): do not edit by hand
% Please edit documentation in R/SystemMetadata.R
\docType{methods}
\name{serializeSystemMetadata}
\alias{serializeSystemMetadata}
\alias{serializeSystemMetadata,SystemMetadata-method}
\title{Serialize a SystemMetadata object to an XML representation}
\usage{
serializeSystemMetadata(sysmeta, ...)

\S4method{serializeSystemMetadata}{SystemMetadata}(sysmeta, version = "v1",
  ...)
}
\arguments{
\item{sysmeta}{The SystemMetadata instance to be serialized}

\item{...}{(Not currently used)}

\item{version}{A character string representing the DataONE API version that this system will be used with (eg. "v1", "v2").}
}
\value{
the character string representing a SystemMetadata object
}
\description{
Serialize a SystemMetadata object to an XML representation
}
\section{Methods (by class)}{
\itemize{
\item \code{SystemMetadata}: 
}}
\seealso{
\code{\link[=SystemMetadata-class]{SystemMetadata}}{ class description.}
}

