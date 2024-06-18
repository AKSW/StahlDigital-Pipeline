# Ontology-Pipeline

A continuous integration pipeline for ontology development in project StahlDigital. Uses spreadsheets as input, converts and validates the input and publishes the resulting ontology.

Workflow is defined using [Nextflow](https://www.nextflow.io/) and depends on a docker container runtime.

Main Steps executed are
* translating spreadsheets to RDF via [xlsx2owl](https://github.com/AKSW/xlsx2owl) for several spreadsheets and mappings
* validate RDF via shacl rules and [PySHACL](https://github.com/RDFLib/pySHACL)
* generate documentation via JOD and [Jekyll RDF](https://github.com/AKSW/jekyll-rdf)
* upload documentation to DSMS and git repos

Please see [CHANGELOG.md](CHANGELOG.md) for the list of changes.

## Execution:
* `$ nextflow run main.nf`
* to override parameter defaults add them to commandline, e.g. to use local spreadsheets: `$ nextflow run main.nf --xlsxUrl="$PWD/xlsx2owl-StahlDigital.xlsx" --xlsxTestsUrl="$PWD/xlsx2owl-StahlDigital-tests.xlsx"`

## Authors
* [Kirill Bulert](bulert@infai.org)
* [Norman Radtke](radtke@infai.org)
* [Lars-Peter Meyer](lpmeyer@infai.org)
