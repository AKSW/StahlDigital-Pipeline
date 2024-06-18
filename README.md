# Ontology-Pipeline

A continuous integration pipeline for ontology development in project [StahlDigital (2021-2024)](https://www.materialdigital.de/project/6). Uses spreadsheets as input, converts and validates the input and publishes the resulting ontology.

Workflow is defined using [Nextflow](https://www.nextflow.io/) (version 22.04.5) and depends on a docker container runtime.

Main Steps executed are
* translating spreadsheets to RDF via [xlsx2owl](https://github.com/AKSW/xlsx2owl) for several spreadsheets and mappings
* transformations using e.g. [RPT](https://github.com/SmartDataAnalytics/RdfProcessingToolkit) and [jena/riot](https://jena.apache.org/documentation/io/)
* validate RDF via shacl rules and [PySHACL](https://github.com/RDFLib/pySHACL)
* generate documentation via JOD and [Jekyll RDF](https://github.com/AKSW/jekyll-rdf)
* upload documentation to DSMS and git repos

Please see [CHANGELOG.md](CHANGELOG.md) for the list of changes.

## Execution:
* add file `secrets` with credentials (e.g. `CI_STAHL_REGISTRY_TOKEN`, `CI_STORE_TOKEN`, `XLSX_MOCK_COMMIT_TOKEN`, `GITLAB_TEST_TOKEN`, `ARTIFACT_REPOSITORY_TOKEN`, `DSMS_USER`, `DSMS_PASSWORD`)
* `$ nextflow run main.nf`
* to override parameter defaults add them to commandline, e.g. to use local spreadsheets: `$ nextflow run main.nf --xlsxUrl="$PWD/xlsx2owl-StahlDigital.xlsx" --xlsxTestsUrl="$PWD/xlsx2owl-StahlDigital-tests.xlsx"`

## Authors
* [Kirill Bulert](bulert@infai.org)
* [Norman Radtke](radtke@infai.org)
* [Lars-Peter Meyer](lpmeyer@infai.org)
