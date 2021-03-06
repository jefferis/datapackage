#
#   This work was created by participants in the DataONE project, and is
#   jointly copyrighted by participating institutions in DataONE. For
#   more information on DataONE, see our web site at http://dataone.org.
#
#     Copyright 2011-2015
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#

#' A class representing a data package, which can contain data objects
#' @description The DataPackage class provides methods for added and extracting
#' data objects from a datapackage. The contents of a package
#' can be determined and the package can be prepared for transport before being
#' uploaded to a data repository or archived.
#' @include dmsg.R
#' @include DataObject.R
#' @include SystemMetadata.R
#' @import hash
#' @rdname DataPackage-class
#' @aliases DataPackage-class
#' @slot relations A hash containing provenance relationships of package objects
#' @slot objects A hash containing identifiers for data object in the DataPackage
#' @slot sysmeta A SystemMetadata class instance describing the package
#' @section Methods:
#' \itemize{
#'  \item{\code{\link[=initialize-DataPackage]{initialize}}}{: Initialize a DataPackage object}
#'  \item{\code{\link{getData}}}{: Get the data content of a specified data object}
#'  \item{\code{\link{getSize}}}{: Get the Count of Objects in the Package}
#'  \item{\code{\link{getIdentifiers}}}{: Get the Identifiers of Package Members}
#'  \item{\code{\link{addData}}}{: Add a DataObject to the DataPackage}
#'  \item{\code{\link{insertRelationship}}}{: Record relationships of objects in a DataPackage}
#'  \item{\code{\link{recordDerivation}}}{: Record derivation relationships between objects in a DataPackage}
#'  \item{\code{\link{getRelationships}}}{: Retrieve relationships of package objects}
#'  \item{\code{\link{containsId}}}{: Returns true if the specified object is a member of the package}
#'  \item{\code{\link{removeMember}}}{: Remove the Specified Member from the Package}
#'  \item{\code{\link{getMember}}}{: Return the Package Member by Identifier}
#'  \item{\code{\link{serializePackage}}}{: Create an OAI-ORE resource map from the package}
#'  \item{\code{\link{serializeToBagit}}}{: Serialize A DataPackage into a Bagit Archive File}
#' }
#' @seealso \code{\link{datapackage}}{ package description.}
#' @export
setClass("DataPackage", slots = c(
    relations               = "hash",
    objects                 = "hash",          # key=identifier, value=DataObject
    sysmeta                 = "SystemMetadata" # system metadata about the package
    )
)

###########################
## DataPackage constructors
###########################

#' Create a DataPackage object
#' @rdname initialize-DataPackage
#' @description The DataPackage() method is a shortcut to creating a DataPackage object, as this method does
#' not allow specifying any options that the \code{\link[=initialize-DataPackage]{initialize}} method allows (using new("DataPackage"")
#' @param ... (Not yet used)
#' @export
setGeneric("DataPackage", function(...) { standardGeneric("DataPackage")} )

#' @rdname initialize-DataPackage
#' @aliases initialize-DataPackage
#' @import hash
#' @param .Object The object being initialized
#' @param packageId The package id to assign to the package
#' @examples
#' # Create a DataPackage with undefined package id (to be set manually later)
#' pkg <- new("DataPackage")
#' # Alternatively, manually assign the package id when the DataPackage object is created
#' pkg <- new("DataPackage", "urn:uuid:4f953288-f593-49a1-adc2-5881f815e946")
#' @seealso \code{\link[=DataPackage-class]{DataPackage}}{ class description.}
setMethod("initialize", "DataPackage", function(.Object, packageId) {
    dmsg("DataPackage-class.R initialize")

    .Object@sysmeta <- new("SystemMetadata")
    if (!missing("packageId")) {
        ## set the packageId and instantiate a new SystemMetadata
        .Object@sysmeta@identifier <- packageId
    }
    .Object@relations = hash()
    .Object@objects = hash()
   return(.Object)
})

#' @describeIn getData
#' @export
setMethod("getData", signature("DataPackage", "character"), function(x, id) {
    databytes <- as.raw(NULL)
    if (containsId(x, id)) {
        do <- x@objects[[id]]
        databytes <- getData(do)
        return(databytes)
    } else {
        return(NULL)
    }
})

#' Get the Count of Objects in the Package
#' @param x A DataPackage instance
#' @param ... (not yet used)
#' @return The number of object in the Package
#' @seealso \code{\link[=DataPackage-class]{DataPackage}}{ class description.}
#' @export
setGeneric("getSize", function(x, ...) { standardGeneric("getSize")} )

#' @describeIn getSize
#' @examples
#' dp <- new("DataPackage")
#' data <- charToRaw("1,2,3\n4,5,6")
#' do <- new("DataObject", dataobj=data, format="text/csv", user="jsmith")
#' addData(dp, do)
#' getSize(dp)
#' @export
setMethod("getSize", "DataPackage", function(x) {
  return(length(x@objects))
})

#setMethod("length", "DataPackage", function(x) {
#    return(length(x@objects))
#})

#' Get the Identifiers of Package Members
#' @description The identifiers of the objects in the package are retrieved and returned as a list.
#' @param x A DataPackage instance
#' @param ... (not yet used)
#' @return A list of identifiers
#' @seealso \code{\link[=DataPackage-class]{DataPackage}}{ class description.}
#' @export
setGeneric("getIdentifiers", function(x, ...) { standardGeneric("getIdentifiers")} )

#' @describeIn getIdentifiers
#' @examples
#' dp <- new("DataPackage")
#' data <- charToRaw("1,2,3\n4,5,6")
#' do <- new("DataObject", dataobj=data, format="text/csv", user="jsmith")
#' addData(dp, do)
#' getIdentifiers(dp)
#' @export
setMethod("getIdentifiers", "DataPackage", function(x) {
    return(keys(x@objects))
})

#' Add a DataObject to the DataPackage
#' @description The DataObject is added to the DataPackage, making it available for
#' retrieval and eventual upload using the method \code{\link[dataone]{uploadDataPackage}}.
#' @param x A DataPackage instance
#' @param do A DataObject instance
#' @param ... (Additional parameters)
#' @seealso \code{\link[=DataPackage-class]{DataPackage}}{ class description.}
#' @export
setGeneric("addData", function(x, do, ...) { 
    standardGeneric("addData")
})

#' @describeIn addData
#' @description The DataObject \code{do} is added to the data package \code{x}.
#' @details If the optional \code{mo} parameter is specified, then it is assumed that this DataObject is a metadata
#' object that describes the science object that is being added. The \code{addData} function will add a relationship
#' to the resource map that indicates that the metadata object describes the science object, using CiTO, the Citation Typing Ontology
#' \code{documents} and \code{isDocumentedBy} relationship.
#' @param mo A DataObject (containing metadata describing \code{"do"} ) to associate with the science object.
#' @examples
#' dpkg <- new("DataPackage")
#' data <- charToRaw("1,2,3\n4,5,6")
#' metadata <- charToRaw("This is the good data\n")
#' md <- new("DataObject", id="md1", dataobj=data, format="text/csv", user="smith", 
#'   mnNodeId="urn:node:KNB")
#' do <- new("DataObject", id="id1", dataobj=data, format="text/csv", user="smith", 
#'   mnNodeId="urn:node:KNB")
#' # Associate the metadata object with the science object. The 'mo' object will be added 
#' # to the package  automatically, since it hasn't been added yet.
#' addData(dpkg, do, md)
#' @export
setMethod("addData", signature("DataPackage", "DataObject"), function(x, do, mo=as.character(NA)) {
  x@objects[[do@sysmeta@identifier]] <- do
  # If a metadata object identifier is specified on the command line, then add the relationship to this package
  # that associates this science object with the metadata object.
  if (!missing(mo)) {
    # CHeck that the metadata object has already been added to the DataPackage. If it has not
    # been added, then add it now.
    if (!containsId(x, getIdentifier(mo))) {
      moId <- addData(x, mo)
    }
    # Now add the CITO "documents" and "isDocumentedBy" relationships
    insertRelationship(x, getIdentifier(mo), getIdentifier(do))
  }
})

#' Record relationships of objects in a DataPackage
#' @description Record a relationship of the form "subject -> predicate -> object", as defined by the Resource Description Framework (RDF), i.e.
#' an RDF triple. 
#' @details For use with DataONE, a best practice is to specifiy the subject and predicate as DataONE persistent identifiers 
#' (https://mule1.dataone.org/ArchitectureDocs-current/design/PIDs.html). If the objects are not known to DataONE, then local identifiers can be
#' used, and these local identifiers may be promoted to DataONE PIDs when the package is uploaded to a DataONE member node.
#' The predicate is typically an RDF property (as a IRI) from a schema supported by DataONE, i.e. "http://www.w3.org/ns/prov#wasGeneratedBy"
#' If multiple values are specified for argument objectIDS, a relationship is created for each value in the list "objectIDs". IF a value
#' is not specified for subjectType or objectType, then NA is assigned. Note that if these relationships are fetched via the getRelationships()
#' function, and passed to the createFromTriples() function to initialize a ResourceMap object, the underlying redland package will assign
#' appropriate values for subjects and objects.
#' @param x A DataPackage object
#' @param subjectID The identifier of the subject of the relationship
#' @param objectIDs A list of identifiers of the object of the relationships (a relationship is recorded for each objectID)
#' @param predicate The IRI of the predicate of the relationship
#' @param ... (Additional parameters)
#' @seealso \code{\link[=DataPackage-class]{DataPackage}}{ class description.}
#' @export
setGeneric("insertRelationship", function(x, subjectID, objectIDs, predicate, ...) {
  standardGeneric("insertRelationship")
})

#' @describeIn insertRelationship
#' @export
setMethod("insertRelationship",  signature("DataPackage", "character", "character", "missing"), function(x, subjectID, objectIDs) {
  
  insertRelationship(x, subjectID, objectIDs, "http://purl.org/spar/cito/documents")
  
  for (obj in objectIDs) {
    insertRelationship(x, obj, subjectID, "http://purl.org/spar/cito/isDocumentedBy")
  }
})

#' @describeIn insertRelationship
#' @param subjectType the type to assign the subject, values can be 'uri', 'blank'
#' @param objectTypes the types to assign the objects (cal be single value or list), each value can be 'uri', 'blank', or 'literal'
#' @param dataTypeURIs An RDF data type that specifies the type of the object
#' @examples
#' \dontrun{
#' dp <- new("DataPackage")
#' # Create a relationship
#' insertRelationship(dp, "/Users/smith/scripts/genFields.R",
#'     "http://www.w3.org/ns/prov#used",
#'     "https://knb.ecoinformatics.org/knb/d1/mn/v1/object/doi:1234/_030MXTI009R00_20030812.40.1")
#' # Create a relationshp with the subject as a blank node with an automatically assigned blank node id
#' insertRelationship(dp, subjectID=NULL, objectIDs="thing6", predicate="http://www.myns.org/wasThing")
#' # Create a relationshp with the subject as a blank node with a user assigned blank node id
#' insertRelationship(dp, subjectID="_:BL1234", objectIDs="thing7", 
#'     predicate="http://www.myns.org/hadThing")
#' # Create multiple relationships with the same subject, predicate, but different objects
#' insertRelationship(dp, subjectID="_:bl2", objectIDs=c("thing4", "thing5"), 
#'     predicate="http://www.myns.org/hadThing")
#' # Create multiple relationships with subject and object types specified
#' insertRelationship(dp, subjectID="orcid.org/0000-0002-2192-403X", 
#'     objectIDs="http://www.example.com/home", predicate="http://www.example.com/hadHome",
#'                    subjectType="uri", objectType="literal")                
#' }
setMethod("insertRelationship", signature("DataPackage", "character", "character", "character"),
          function(x, subjectID, objectIDs, predicate, 
                   subjectType=as.character(NA), objectTypes=as.character(NA), dataTypeURIs=as.character(NA)) {
  
  # Append new relationships to previously stored ones.
  if (has.key("relations", x@relations)) {
    relations <- x@relations[["relations"]]
  } else {
    relations <- data.frame()
  }
  
  # If the subjectID or objectIDs were not specified or NULL then the user is requesting that these be "anonymous"
  # blank nodes, i.e. a blank node identifier is automatically assigned. Assign a uuid now vs having redland
  # RDF package assign a node, so that we don't have to remember that this node is special.
  if (is.na(subjectID)) {
    subjectID <- sprintf("_:%s", UUIDgenerate())
    subjectType <- "blank"
  }
  
  if (all(is.na(objectIDs))) {
    objectIDs <- sprintf("_:%s", UUIDgenerate())
    objectTypes <- "blank"
  }
  
  # Add all triples to the data frame. If the length of objectTypes or dataTypeURIs is less
  # that the length of objectIDs, then values will be set to NA
  i <- 0
  for (obj in objectIDs) {
    i <- i + 1
    # Check that the subjectType is a valid type for an RDF subject
    if (!is.element(subjectType[i], c("uri", "blank", as.character(NA)))) {
      stop(sprintf("Invalid subject type: %s\n", subjectType[i]))
    }
    # Check that the objectType is a valid type for an RDF object
    if(!is.element(objectTypes[i], c("uri", "literal", "blank", as.character(NA)))) {
      stop(sprintf("Invalid objct type: %s\n", objectTypes[i]))
    }
    newRels <- data.frame(subject=subjectID, predicate=predicate, object=obj, 
                        subjectType=subjectType, objectType=objectTypes[i], 
                        dataTypeURI=dataTypeURIs[i], row.names = NULL, stringsAsFactors = FALSE)
    
    # Has a relation been added previously?
    if (nrow(relations) == 0) {
      relations <- newRels
    } else {
      relations <- rbind(relations, newRels)
    }
  }
  
  # Use a slot that is a hash, so that we can update the datapackage without having to 
  # return the datapackage object to the caller (since S4 methods don't pass args by reference)
  x@relations[["relations"]] <- relations
})

#' Record derivation relationships between objects in a DataPackage
#' @description Record a derivation relationship that expresses that a target object has been derived from a source object.
#' For use with DataONE, a best practice is to specifiy the subject and predicate as DataONE persistent identifiers 
#' (https://mule1.dataone.org/ArchitectureDocs-current/design/PIDs.html). If the objects are not known to DataONE, then local identifiers can be
#' used, and these local identifiers may be promoted to DataONE PIDs when the package is uploaded to a DataONE member node.
#' @details A derived relationship is created for each value in the list "objectIDs".  For each derivedId, one statement will be
#' added expressing that it was derived from the sourceId.  The predicate is will be an RDF property (as a IRI) from the W3C PROV
#' specification, namely, "http://www.w3.org/ns/prov#wasDerivedFrom"
#' @param x a DataPackage object
#' @param ... Additional parameters
#' @examples
#' \dontrun{
#' dp <- new("DataPackage")
#' recordDerivation(dp, "https://cn.dataone.org/cn/v1/object/doi:1234/_030MXTI009R00_20030812.40.1",
#'                      "https://cn.dataone.org/cn/v1/object/doi:1234/_030MXTI009R00_20030812.45.1")
#' }
#' @seealso \code{\link[=DataPackage-class]{DataPackage}}{ class description.}
#' @export
setGeneric("recordDerivation", function(x, ...) {
    standardGeneric("recordDerivation")
})

#' @describeIn recordDerivation
#' @param sourceID the identifier of the source object in the relationship
#' @param derivedIDs an identifier or list of identifiers of objects that were derived from the source 
setMethod("recordDerivation",  signature("DataPackage"), function(x, sourceID, derivedIDs, ...) {
    for (obj in derivedIDs) {
        insertRelationship(x, subjectID=obj, objectIDs=sourceID, predicate="http://www.w3.org/ns/prov#wasDerivedFrom")
    }
})

#' Retrieve relationships of package objects
#' @description Relationships of objects in a package are defined using the \code{'insertRelationship'} call and retrieved
#' using \code{getRetaionships}. These relationships are returned in a data frame with \code{'subject'}, \code{'predicate'}, \code{'objects'}
#' as the columns, ordered by "subject"
#' @param x A DataPackage object
#' @param ... (Not yet used)
#' @seealso \code{\link[=DataPackage-class]{DataPackage}}{ class description.}
#' @export
setGeneric("getRelationships", function(x, ...) {
  standardGeneric("getRelationships")
})

#' @describeIn getRelationships
#' @examples
#' dp <- new("DataPackage")
#' insertRelationship(dp, "/Users/smith/scripts/genFields.R",
#'     "http://www.w3.org/ns/prov#used",
#'     "https://knb.ecoinformatics.org/knb/d1/mn/v1/object/doi:1234/_030MXTI009R00_20030812.40.1")
#' rels <- getRelationships(dp)
#' @export
setMethod("getRelationships", signature("DataPackage"), function(x, ...) {
  
  # Get the relationships stored by insertRelationship
  relationships <- x@relations[["relations"]]
  
  # Reorder output data frame by "subject" column
  relationships <- relationships[order(relationships$subject, relationships$predicate, relationships$object),]
  invisible(relationships)
})

#' Returns true if the specified object is a member of the package
#' @param x A DataPackage object
#' @param identifier The DataObject identifier to check for inclusion in the DataPackage
#' @param ... (Not yet used)
#' @seealso \code{\link[=DataPackage-class]{DataPackage}}{ class description.}
#' @export
setGeneric("containsId", function(x, identifier, ...) {
    standardGeneric("containsId")
})

#' @describeIn containsId
#' @return A logical - a value of TRUE indicates that the DataObject is in the DataPackage
#' @examples
#' dp <- new("DataPackage")
#' data <- charToRaw("1,2,3\n4,5,6")
#' id <- "myNewId"
#' do <- new("DataObject", id=id, dataobj=data, format="text/csv", user="jsmith")
#' addData(dp, do)
#' isInPackage <- containsId(dp, identifier="myNewId")
#' @export
setMethod("containsId", signature("DataPackage", "character"), function(x, identifier) {
    obj <- x@objects[[identifier]]
    found <- !is.null(obj)
    return(found)
})

#' Remove the Specified Member from the Package
#' @description Given the identifier of a member of the data package, delete the DataObject
#' representation of the member.
#' @param x a Datapackage object
#' @param identifier an identifier for a DataObject
#' @param ... (Not yet used)
#' @seealso \code{\link[=DataPackage-class]{DataPackage}}{ class description.}
#' @export 
setGeneric("removeMember", function(x, identifier, ...) {
  standardGeneric("removeMember")
})

#' @describeIn removeMember
#' @examples
#' dp <- new("DataPackage")
#' data <- charToRaw("1,2,3\n4,5,6")
#' do <- new("DataObject", id="myNewId", dataobj=data, format="text/csv", user="jsmith")
#' addData(dp, do)
#' removeMember(dp, "myNewId")
#' @export
setMethod("removeMember", signature("DataPackage", "character"), function(x, identifier) {
    if (containsId(x, identifier)) {
        x@objects[[identifier]] <- NULL
    }
})

#' Return the Package Member by Identifier
#' @description Given the identifier of a member of the data package, return the DataObject
#' representation of the member.
#' @param x A DataPackage object
#' @param identifier A DataObject identifier
#' @param ... (Not yet used)
#' @seealso \code{\link[=DataPackage-class]{DataPackage}}{ class description.}
#' @export
setGeneric("getMember", function(x, identifier, ...) {
    standardGeneric("getMember")
})

#' @describeIn getMember
#' @return A DataObject if the member is found, or NULL if not
#' @export
#' @examples
#' dp <- new("DataPackage")
#' data <- charToRaw("1,2,3\n4,5,6")
#' do <- new("DataObject", id="myNewId", dataobj=data, format="text/csv", user="jsmith")
#' addData(dp, do)
#' do2 <- getMember(dp, "myNewId")
setMethod("getMember", signature("DataPackage", "character"), function(x, identifier) {
    if (containsId(x, identifier)) {
        return(x@objects[[identifier]])
    } else {
        return(NULL)
    }
})

#' Create an OAI-ORE resource map from the package
#' @description The Datapackage is serialized as a OAI-ORE resource map to the specified file.
#' @param .Object A DataPackage object
#' @param ... Additional arguments
#' @seealso \code{\link[=DataPackage-class]{DataPackage}}{ class description.}
#' @export
setGeneric("serializePackage", function(.Object, ...) {
  standardGeneric("serializePackage")
})

#' @describeIn serializePackage
#' @details The resource map that is created is serialized by default as RDF/XML. Other serialization formats
#' can be specified using the \code{syntaxName} and \code{mimeType} parameters. Other available formats
#' include: 
#' \tabular{ll}{
#' \strong{syntaxName}\tab \strong{mimeType}\cr
#' json\tab application/json\cr
#' ntriples\tab application/n-triples\cr
#' turtle\tab text/turtle\cr
#' dot\tab text/x-graphviz\cr
#' } 
#' Note that the \code{syntaxName} and \code{mimeType} arguments together specify o serialization format.
#' 
#' Also, for packages that will be uploaded to the DataONE network, "rdfxml" is the only 
#' accepted format.  
#' 
#' The resolveURI string value is prepended to DataPackage member identifiers in the resulting resource map. 
#' If no resolveURI value is specified, then 'https://cn.dataone.org/cn/v1/resolve' is used.
#' @param file The file to which the ResourceMap will be serialized
#' @param id A unique identifier for the serialization. The default value is the id assinged 
#' to the DataPackage when it was created.
#' @param syntaxName The name of the syntax to use for serialization - default is "rdfxml"
#' @param mimeType The mimetype of the serialized output - the default is "application/rdf+xml"
#' @param namespaces A data frame containing one or more namespaces and their associated prefix
#' @param syntaxURI URI of the serialization syntax
#' @param resolveURI A character string containing a URI to prepend to datapackage identifiers
#' @export
#' @examples
#' dp <- new("DataPackage")
#' data <- charToRaw("1,2,3\n4,5,6")
#' do <- new("DataObject", id="do1", dataobj=data, format="text/csv", user="jsmith")
#' addData(dp, do)
#' data2 <- charToRaw("7,8,9\n4,10,11")
#' do2 <- new("DataObject", id="do2", dataobj=data2, format="text/csv", user="jsmith")
#' addData(dp, do2)
#' recordDerivation(dp, "do2", "do2")
#' status <- serializePackage(dp, file="/tmp/resmap.json", syntaxName="json", mimeType="application/json")
#' status <- serializePackage(dp, file="/tmp/resmap.rdf", syntaxName="rdfxml", mimeType="application/rdf+xml")
#' status <- serializePackage(dp, file="/tmp/resmap.ttl", syntaxName="turtle", mimeType="text/turtle")
setMethod("serializePackage", signature("DataPackage"), function(.Object, file, 
                                                                 id = as.character(NA),
                                                                 syntaxName="rdfxml", 
                                                                 mimeType="application/rdf+xml", 
                                                                 namespaces=data.frame(namespace=character(), prefix=character(), stringsAsFactors=FALSE),
                                                                 syntaxURI=as.character(NA), resolveURI=as.character(NA)) {
  # Get the relationships stored in this datapackage.
  relations <- getRelationships(.Object)
  
  # Create a ResourceMap object and serialize it to the specified file  
  #
  # If a serialization id was not specified, then use the id assinged to the DataPackage when it
  # was created. If a DataPackage id was not assigned, then create a unique id.
  if(is.na(id)) {
    if(is.na(.Object@sysmeta@identifier) || is.null(.Object@sysmeta@identifier)) {
      id <- sprintf("urn:uuid:%s", UUIDgenerate())
    } else {
      id <- .Object@sysmeta@identifier
    }
  }
  
  # Create a resource map from previously stored triples, for example, from the relationships in a DataPackage
  resMap <- new("ResourceMap", id)
  resMap <- createFromTriples(resMap, relations=relations, identifiers=getIdentifiers(.Object), resolveURI=resolveURI)  
  status <- serializeRDF(resMap, file, syntaxName, mimeType, namespaces, syntaxURI)
  freeResourceMap(resMap)
  rm(resMap)
})

#' Serialize A DataPackage into a Bagit Archive File
#' @description The Bagit packaging format \url{https://tools.ietf.org/html/draft-kunze-bagit-08}
#' is used to prepare an archive file that contains the contents of a DataPackage.
#' @details A Bagit Archive File is created by copying each member of a DataPackge, and preparing
#' files that describe the files in the archive, including information about the size of the files
#' and a checksum for each file. These metadata files and the data files are then packaged into
#' a single zip file.
#' @param .Object A DataPackage object
#' @param ... Additional arguments
#' @seealso \code{\link[=DataPackage-class]{DataPackage}}{ class description.}
#' @export
setGeneric("serializeToBagit", function(.Object, ...) {
  standardGeneric("serializeToBagit")
})

#' @describeIn serializeToBagit
#' @import uuid
#' @import digest
#' @return A zip file containing a Bagit archive.
#' @examples
#' # Create the first data object
#' dp <- new("DataPackage")
#' data <- charToRaw("1,2,3\n4,5,6")
#' do <- new("DataObject", id="do1", dataobj=data, format="text/csv", user="jsmith")
#' addData(dp, do)
#' # Create a second data object
#' data2 <- charToRaw("7,8,9\n4,10,11")
#' do2 <- new("DataObject", id="do2", dataobj=data2, format="text/csv", user="jsmith")
#' addData(dp, do2)
#' # Create a relationship between the two data objects
#' recordDerivation(dp, "do2", "do2")
#' # Write out the data package to a Bagit file
#' bagitFile <- serializeToBagit(dp)
#' @export
setMethod("serializeToBagit", signature("DataPackage"), function(.Object) {
  pidMap <- as.character()
  manifest <- as.character()
  # Create a temp working area where the Bagit directory structure will be created
  tmpDir <- tempdir()
  bagDir <- sprintf("%s/bag", tmpDir)
  if(dir.exists(bagDir)) {
    unlink(bagDir, recursive=TRUE)
  } 
  dir.create(bagDir)
  payloadDir <- sprintf("%s/data", bagDir)
  if(!dir.exists(payloadDir)) dir.create(payloadDir)
  
  # Get the relationships stored in this datapackage.
  relations <- getRelationships(.Object)
  
  # Create a ResourceMap object and serialize it to the specified file
  resMapId <- sprintf("urn:uuid:%s", UUIDgenerate())
  
  tmpFile <- tempfile()
  resMap <- new("ResourceMap", resMapId)
  resMap <- createFromTriples(resMap, relations=relations, identifiers=getIdentifiers(.Object), resolveURI="")  
  serializeRDF(resMap, tmpFile, syntaxName="rdfxml", mimeType="application/rdf+xml")
  freeResourceMap(resMap)
  rm(resMap)
  
  # Add resource map to the pid map
  relFile <- sprintf("data/%s.rdf", resMapId)
  resMapFilepath <- sprintf("%s/%s", bagDir, relFile)
  file.copy(tmpFile, resMapFilepath)
  pidMap <- c(pidMap, sprintf("%s %s", resMapId, relFile))
  # Add resource map to the manifrest
  resMapMd5 <- digest(resMapFilepath, algo="md5", file=TRUE)
  manifest <- c(manifest, sprintf("%s %s", resMapMd5, relFile)) 
  
  # Create bagit.txt  
  bagit <- sprintf("BagIt-Version: 0.97\nTag-File-Character-Encoding: UTF-8")
  writeLines(bagit, sprintf("%s/bagit.txt", bagDir))
  
   # Populate './data" directory by copying each DataPackage member from a filename
  # if that was specified, or from an in-memober object.
  identifiers <- getIdentifiers(.Object)
  for(idNum in 1:length(identifiers)) {
    dataObj <- getMember(.Object, identifiers[idNum])
    # Was the DataObject created with the 'file' arg, i.e. data not in the DataObject,
    # but at a specified file out on disk?
    if(!is.na(dataObj@filename)) {
      if(file.exists(dataObj@filename)) {
        relFile <- sprintf("data/%s", basename(dataObj@filename))
        file.copy(dataObj@filename, sprintf("%s/%s", bagDir, relFile))
        # Add this data pacakge member to the bagit files
        pidMap <- c(pidMap, sprintf("%s %s", identifiers[idNum], relFile))
        thisMd5 <- digest(sprintf("%s/%s", bagDir, relFile), algo="md5", file=TRUE)
        manifest <- c(manifest, sprintf("%s %s", as.character(thisMd5), relFile))  
      } else {
        stop(sprintf("Error serializing to Bagit format, data object \"%s\", uses file %s but this file doesn't exist", dataObj@filename, identifiers[idNum]))
      }
    } else {
      # Must be an in-memory data object
      tf <- tempfile()
      con <- file(tf, "wb")
      writeBin(getData(dataObj), con)
      close(con)
      relFile <- sprintf("data/%s", getIdentifier(dataObj))
      file.copy(tf, sprintf("%s/%s", bagDir, relFile))
      unlink(tf)
      rm(tf)
      # Add this data pacakge member to the bagit files
      pidMap <- c(pidMap, sprintf("%s %s", identifiers[idNum], relFile))
      thisMd5 <- digest(sprintf("%s/%s", bagDir, relFile), algo="md5", file=TRUE)
      manifest <- c(manifest, sprintf("%s %s", as.character(thisMd5), relFile))
    }
  }
  
  #fInfo <- file.info(sprintf("%s", payloadDir))
  fInfo <- file.info(list.files(payloadDir, full.names=T, recursive=T))
  #fInfo <- file.info(list.files(payloadDir), all.files=TRUE, recursive=TRUE)
  bagBytes <- sum(fInfo[['size']])
  # Convert the value returned from file.info (bytes) into a more 
  # human readable form.
  # Size is displayed in bytes
  if(bagBytes < 1024) {
    bagSize <- bagBytes
    sizeUnits <- "B"
  } else if (bagBytes < 1000000) {
    # Size is displayed in Kilobytes
    bagSize <- bagBytes / 1024.0
    sizeUnits <- "KB"
  } else if (bagBytes < 1000000000) {
    # Size is displayed in megabytes
    bagSize <- bagBytes / 1000000.0
    sizeUnits <- "MB"
  } else {
    # Size is displayed in terabytes
    bagSize <- bagBytes / 1000000000.0 
    sizeUnits <- "GB"
  }
  
  bagInfo <- sprintf("Payload-Oxum: %d.%d\nBagging-Date: %s\nBag-Size: %f %s",
                       bagBytes, length(list.files(payloadDir)),
                       format(Sys.time(), format="%Y-%m-%d"), 
                       bagSize, sizeUnits)
  
  writeLines(bagInfo, sprintf("%s/%s", bagDir, "bag-info.txt"))
  # Create pid-mapping.txt  
  writeLines(pidMap, sprintf("%s/%s", bagDir, "pid-mapping.txt"))
  # Create bag-info.txt
  
  # create manifest-md5.txt
  writeLines(manifest, sprintf("%s/%s", bagDir, "manifest-md5.txt"))
  
  # Create tagmanifest-md5.txt
  tagManifest <- as.character()
  #tagFiles <- c("bag-info.txt", "bagit.txt", "pid-mapping.txt", "tagmanifest-md5.txt")
  tagFiles <- c("bag-info.txt", "bagit.txt", "pid-mapping.txt")
  for (i in 1:length(tagFiles)) {
    thisFile <- tagFiles[i]  
    thisMd5 <- digest(sprintf("%s/%s", bagDir, thisFile), algo="md5", file=TRUE)
    tagManifest <- c(tagManifest, sprintf("%s %s", thisMd5, thisFile))
  }
  
  writeLines(tagManifest, sprintf("%s/%s", bagDir, "tagmanifest-md5.txt"))
  zipFile <- tempfile(fileext=".zip")
  # Now zip up the directory struction 
  setwd(bagDir)
  if(getwd() != bagDir) {
    stop("Unable to set working directory to the Bagit dir: %s", bagDir)
  }
  zip(zipFile, files=list.files(recursive=TRUE), flags="-q")
  # Return the zip filename
  return(zipFile)
})
