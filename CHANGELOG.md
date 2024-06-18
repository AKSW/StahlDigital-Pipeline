# Change Log

All notable changes to this project should be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## 0.4.0
- changed: updated to xlsx2owl v.2.3.0 to add more functions and metadata, requires more metadata columns in spreadsheet
- changed: switched descriptions from rdfs:comment to dcterms:descriptions
- changed: updated references on 4 renamed test sheets: `HG-Zugversuch`, `Nakajimaversuch`, `Scherzugversuch`, `Kerbzugversuch`
- changed: added test sheet: `Probentyp`
- changed: removed references on 4 old test sheets
- changed: updated DSMS upload to use DSMS-SDK
- fixed IRI for unit linked properties by creating them with SPARQL post processing
- added publish retry and versioning branch support (new parameter 'publishRepositoryBranchVersioning', leave empty for default branch)
- added filter on cited descriptions via sparql delete statement
- added spreadsheet source information for test and simulation spreadsheet entries, only present in index-full.ttl in artifacts and dsms
- added sparql filter process
- cleanup

## 0.3.6
- added more tags for simulation and test concepts

## 0.3.5
- added description source tags for simulation and test concepts

## 0.3.4
- updated test sheet list (added 'Prüfmaschinen', 'Stahlsorten' and 'Zugversuch')

## 0.3.3
- updated to xlsx2owl v2.1.1 (ommits prefixed IDs)
- updated test sheet list (added BulgeTest; removed Scherzugversuch GF2 PP, Kerbzugversuch GF2 PP, Zugversuch Instron GF2 PP)

## 0.3.2
- fixed mock spreadsheet urls
- added test sheet names (Nakajimaversuch, Virtuelles Labor, Component Crash test, Norm DIN EN ISO 12004-2)
- added: output of rdf result stats(count of triples, classes and properties)
- added nextflow.log to gitlab CI artifacts

## 0.3.2
- fixed mock spreadsheet urls
- added test sheet names (Nakajimaversuch, Virtuelles Labor, Component Crash test, Norm DIN EN ISO 12004-2)
- added: output of rdf result stats(count of triples, classes and properties)
- added nextflow.log to gitlab CI artifacts

## 0.3.1
- added test and simulation input sheet names
- added: output of result triple count

## 0.3.0
- added properties derived from test concepts
- fixed rapper script for spaces in file names
- updated: xlsx2owl version 2.0 and pin image version

## 0.2.0
- fixed: pipeline does not complete on dsms error. Warns on DSMS errors now, but does not fail 
- added: this changelog
- added: a Readme.md replacing the defaultgitlab template
- added: processing of sheet Scherzugversuch GF2
- added: sorted-nt-files
- added: publish to github only on change
- added: simulation mapping


## 0.1.0
- fixed: curl fails on dsms server errors now
- updated: updated dsms url to keep pipeline working
- updated: updated file url to keep pipeline working
