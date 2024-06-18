#!/usr/bin/env nextflow

// read in secrets from file if not running in CI
CI = System.getenv('CI_SERVER') ?: ''
if (!CI) {
    println('Running locally')
    evaluate(new File('secrets'))
}
if (CI){
    // No git within nextflow container
    def yum_out = 'yum install -y git'.execute().text
}

// load registry credentials and url
params.ciRegistryUser = System.getenv('CI_REGISTRY_USER') ?: 'bot'
params.ciRegistryToken = System.getenv('CI_STAHL_REGISTRY_TOKEN') ?: CI_STAHL_REGISTRY_TOKEN
params.ciRegistry = System.getenv('CI_REGISTRY') ?: 'git.infai.org:4567'
m = params.ciRegistry =~ /(?<domain>(\w+.)+(\w+)):(?<port>\d+)/
m.matches()
params.ciRegistryPort = m.group("port")

// load CI related parameters
params.ciCommitBranch = System.getenv('CI_COMMIT_BRANCH') ?: 'git rev-parse --abbrev-ref HEAD'.execute().text.strip()
params.ciDefaultBranch = System.getenv('CI_DEFAULT_BRANCH') ?: 'dev'
params.ciCommitRefSlug = System.getenv('CI_COMMIT_REF_SLUG') ?: params.ciCommitBranch
params.artifactFolder = System.getenv('ARTIFACT_FOLDER') ?: "$launchDir/Artifacts"

// define container images to use
params.xlsx2owl_image = System.getenv('CI_XLSX2OWL_IMAGE') ?: 'git.infai.org:4567/materialdigital/stahldigital/xlsx2owl:v2-3-0-2024-04-16'
params.ciJodImage = System.getenv('CI_JOD_IMAGE') ?: 'git.infai.org:4567/materialdigital/stahldigital/jod-for-stahl:main'

// define control parameters
params.debug = true
params.publish = false
params.publishDSMS = params.publish // should we publish on DSMS?
params.publishArtifacts = params.publish // should commit to artifacts repo?
params.publishW3id = params.publish // should we commit w3id file structure to repo?
params.publishW3idVersioning = params.publish // should we commit to versioning repo?

// define source urls for spreadsheet input
params.xlsxUrl = System.getenv('INPUT_FILE') ?: 'https://msinfai-my.sharepoint.com/:x:/g/personal/lpmeyer_infai_org/EXIqsVf7v7JOh3ahmZLdXD8B_ZseUD6cFpdw46dzjWwJYA?download=1'
params.xlsxTestsUrl = System.getenv('INPUT_TESTS_FILE') ?: 'https://msinfai-my.sharepoint.com/:x:/g/personal/lpmeyer_infai_org/EVIa_9kDC7JLhexX9pAxKosBWj-x_YrB_O8S5I6vVzNk-g?download=1'
params.xlsxSimulUrl = System.getenv('INPUT_SIMUL_FILE') ?: 'https://msinfai-my.sharepoint.com/:x:/g/personal/lpmeyer_infai_org/EeVTPfnPEPZNopzO50f-bZIBjntccjTItiyc55zEyhOaCw?download=1'

// define repository urls
params.artifactRepository = System.getenv('ARTIFACT_REPOSITORY') ?: 'https://git.infai.org/materialdigital/stahldigital/dev_artifacts.git'
params.publishRepository = System.getenv('PUBLISH_REPOSITORY') ?: 'git@github.com:Kibubu/testOntologyDeploy.git'
params.publishRepositoryVersioning = System.getenv('PUBLISH_REPOSITORY_VERSIONING') ?: 'git@github.com:Kibubu/testOntologyDeploy.git'
params.publishRepositoryBranchVersioning = System.getenv('PUBLISH_REPOSITORY_BRANCH_VERSIONING') ?: ''
params.quitstoreRepository = System.getenv('QUITSTORE_REPOSITOR') ?: 'git@git.infai.org:materialdigital/stahldigital/store.git'

// define git credentials
params.commitUsername = 'Script'
params.commitEmail = ''
params.commitMessage = 'Pipeline'
params.imageRegistry = ''
params.imageRegistryToken = ''

// define DSMS credentials
DSMS_USER = System.getenv('DSMS_USER') ?: DSMS_USER
DSMS_PASSWORD = System.getenv('DSMS_PASSWORD') ?: DSMS_PASSWORD
//params.dsmsUrl = " https://stahldigital.materials-data.space/api/knowledge/update-query?user=$DSMS_USER:$DSMS_PASSWORD"
params.dsmsUrl = "https://stahldigital.materials-data.space"

// define parameters for commits to articats repository
params.xlsx2owl_artifactRepository = params.artifactRepository
params.xlsx2owl_commitUsername = params.commitUsername
params.xlsx2owl_commitEmail = params.commitEmail
params.xlsx2owl_commitMessage = params.commitMessage
params.xlsx2owl_commitToken = System.getenv('ARTIFACT_REPOSITORY_TOKEN') ?: ARTIFACT_REPOSITORY_TOKEN

params.publishKey = System.getenv('PUBLISH_REPOSITORY_KEY') ?: "$projectDir/deploy_key"
params.publishKeyVersioning = System.getenv('PUBLISH_REPOSITORY_VERSIONING_KEY') ?: "$projectDir/deploy_key"
params.known_hosts = System.getenv('KNOWN_HOSTS') ?: "$projectDir/known_hosts"

// params.pushImageToRegistry = false
// params.removeImageLocally = false
// params.processOntology = false

// include modules
include { build as buildVocab; buildFromUrlWithParams as buildTestsVocab; buildFromUrlWithParams as buildSimulVocab } from './modules/Xlsx2owl'
include { collectOutputChannels; renameFile as renameVocab } from './modules/Util'
include { serializeRDFFiles as serialize } from './modules/Serializations.nf'
include { generateSites as jod } from './modules/Jod'
include { updateDataspace as v2d } from './modules/Vocab2DSMS'
include { commit as _commitArtifacts } from './modules/Gitlab'
include { publish as _publishGithub } from './modules/Publish'
include { publishVersioning as _publishGithubVersioning } from './modules/Publish'
include { dockerLogin } from './modules/Docker'
include { mergeTtlFiles as mergeVocab } from './modules/Jena'
include { validateWithShapeFilesWorkflow; shortenValidationResultTxt } from './modules/PySHACL'
include { collectArtifacts; countTriplesInIndexNT; miniRdfStatsInIndexNT } from './modules/Util'
include { applySparqlOnRdf } from './modules/SPARQL'
include { applySparqlOnRdf as applySparqlFilter; applySparqlOnRdf as applySparqlTestsPostProc; applySparqlOnRdf as applySparqlSimulPostProc} from './modules/SPARQL'

// define workflows
workflow publishGithub {
    take:
        files
    main:
        _publishGithub(
            files,
            params.publishRepository,
            params.publishKey,
            params.commitEmail,
            params.commitUsername,
            channel.value(params.known_hosts),
            1)
}

workflow publishGithubVersioning {
    take:
        files
    main:
        _publishGithubVersioning(
            files,
            params.publishRepositoryVersioning,
            params.publishRepositoryBranchVersioning,
            params.publishKeyVersioning,
            params.commitEmail,
            params.commitUsername,
            channel.value(params.known_hosts),
            1)
}

workflow commitArtifacts {
    take:
        files
    main:
        _commitArtifacts(
            files,
            params.xlsx2owl_artifactRepository,
            params.xlsx2owl_commitToken,
            params.xlsx2owl_commitUsername,
            params.xlsx2owl_commitEmail,
            params.xlsx2owl_commitMessage)
    emit:
        files
}

// main workflow
workflow {
    dockerLogin(params.ciRegistryUser, params.ciRegistryToken, params.ciRegistry)
    ifDockerLogin = dockerLogin.out.success.multiMap {
          ifTrue -> 
          xlsx: params.xlsxUrl
          xlsxTests: params.xlsxTestsUrl
          xlsxSimul: params.xlsxSimulUrl
       }

    // ...Extract...
    buildVocab(ifDockerLogin.xlsx) // create ontology
    //we want different file names to avoid duplicate file name conflict later when collection artifacts
    buildTestsVocab(ifDockerLogin.xlsxTests, Channel.fromPath("resources/tests-mapping-yarrrml.yml"), "xlsx2owl-tests-tmp.xlsx", "rdf-tests-out" ) // create tests ontology
    buildSimulVocab(ifDockerLogin.xlsxSimul, Channel.fromPath("resources/simul-mapping-yarrrml.yml"), "xlsx2owl-simul-tmp.xlsx", "rdf-simul-out" ) // create simulation ontology
    applySparqlTestsPostProc(buildTestsVocab.out.ttl, Channel.fromPath( ["resources/mapUnits.sparql", "resources/removeForeignUnitInfos.sparql", "resources/removeShortIds.sparql"]).collect(), "rdf-tests-out.ttl") // post process tests ttl
    applySparqlSimulPostProc(buildSimulVocab.out.ttl, Channel.fromPath( ["resources/mapUnits.sparql", "resources/removeForeignUnitInfos.sparql", "resources/removeShortIds.sparql"]).collect(), "rdf-simul-out.ttl") // post process simul ttl

    // ...Transform...
    mergeVocab(buildVocab.out.ttl.mix( applySparqlTestsPostProc.out, applySparqlSimulPostProc.out ).collect())
    renameVocab(mergeVocab.out.mergedTtl, "index-full.ttl")
    applySparqlOnRdf(mergeVocab.out.mergedTtl, Channel.fromPath( ["resources/removeSpreadsheetSourceProperties.sparql"]).collect(), "index.ttl")
    validateWithShapeFilesWorkflow(
            channel.fromPath("./resources/shacl/*").collect(),
            applySparqlOnRdf.out
    )
    shortenValidationResultTxt(validateWithShapeFilesWorkflow.out.validationResultTxt)
    jod(applySparqlOnRdf.out) // generate HTML and ttl files
    serialize(Channel.empty().mix(jod.out.ttls, applySparqlOnRdf.out).collect())  // serialize xml and nt files from ttl
    countTriplesInIndexNT(serialize.out.serializations_dir)
    countTriplesInIndexNT.out.out.view()
    miniRdfStatsInIndexNT(applySparqlOnRdf.out)

    // Sync channels so only one commit gets created
    w3id_files = Channel.empty().mix(
        serialize.out.serializations_dir,
        shortenValidationResultTxt.out.validationResultLongTxt,
        shortenValidationResultTxt.out.validationResultTxt,
        validateWithShapeFilesWorkflow.out.shaclShapesTtl,
        jod.out.htmls_dir,
        jod.out.ontologyDescriptionHtml).collect()
    artifacts = collectOutputChannels(buildVocab).mix(
                        collectOutputChannels(buildTestsVocab),
                        collectOutputChannels(buildSimulVocab),
                        renameVocab.out,
                        applySparqlOnRdf.out,
                        w3id_files,
                        countTriplesInIndexNT.out.statsTxt,
                        miniRdfStatsInIndexNT.out.statsCsv)
                    .collect()
    collectArtifacts(artifacts)

    // ...Load... 
    if (params.publishDSMS){
        v2d(renameVocab.out, params.dsmsUrl, DSMS_USER, DSMS_PASSWORD) // publish vocab on DSMS
    }

    if (params.publishArtifacts){
        commitArtifacts(artifacts) //commit to artifacts
    }

    if (params.publishW3id){
        publishGithub(w3id_files) //publish w3id
    }

    if (params.publishW3idVersioning){
        publishGithubVersioning(w3id_files) //publish versioning file
    }
}

