
CI = System.getenv('CI_SERVER') ?: ''
if (!CI) {
    evaluate(new File('secrets'))
}

params.with {
    debug = true
    xlsx2owl_image = 'git.infai.org:4567/materialdigital/stahldigital/xlsx2owl:v2.3.0-2024-04-16'
    xlsx2owl_artifactRepository = 'https://git.infai.org/materialdigital/stahldigital/mock_artifacts.git'
    xlsx2owl_commitUsername = 'Script'
    xlsx2owl_commitToken = ''
    xlsx2owl_commitEmail = ''
    xlsx2owl_commitMessage = 'Mock Commit'
    xlsx2owl_xlsxUrl = ''
    xlsx2owl_xlsxFile = ''
    xlsx = ''
}
// params.xlsxCommitToken = System.getenv('XLSX_MOCK_COMMIT_TOKEN') ?: XLSX_MOCK_COMMIT_TOKEN

include { hasChanged } from './Gitlab'
include { commit } from './Gitlab'
include { dockerLogin } from './Docker'
include { collectOutputChannels } from './Util'

process get {
    container params.xlsx2owl_image
    // beforeScript 'docker login -u $CI_REGISTRY_USER -p $CI_STAHL_REGISTRY_TOKEN $CI_REGISTRY'
    debug params.debug
    input:
        val xlsxUrl
    output:
        path '*.xlsx', emit: xlsx
    script:
    """
    curl --remote-name "${xlsxUrl}"
    """
}

process buildFromUrlWithParams {
    container params.xlsx2owl_image
    // workaround for GItlab CI read Comment inside script
    containerOptions '-u 0'
    debug params.debug
    input:
        val xlsx_url
        file yarrrml
        val xlsxFilename
        val resultPrefix
        

    output:
        path "${resultPrefix}.ttl", emit: ttl
        // path '*.yml.ttl', emit: ymlttl
        path '*.nq', emit: nq
        path '*.xlsx', emit: xlsx

    script:
    """
    # workaround for permission denied touch .command.trace on GITLAB CI
    chown user:user .
    su user << EOF
    bash -x "/home/user/xlsx2owl.sh" --input "$xlsxFilename" --outputPrefix $resultPrefix --yarrrml "$yarrrml" "$xlsx_url"
    EOF
    """
}

process buildFromUrl {
    container params.xlsx2owl_image
    // workaround for GItlab CI read Comment inside script
    containerOptions '-u 0'
    debug params.debug
    input:
        val xlsx_url

    output:
        path '*out.ttl', emit: ttl
        // path '*.yml.ttl', emit: ymlttl
        path '*.nq', emit: nq
        path '*.xlsx', emit: xlsx

    script:
    """
    # workaround for permission denied touch .command.trace on GITLAB CI
    chown user:user .
    su user << EOF
    bash -x "/home/user/xlsx2owl.sh" "$xlsx_url"
    EOF
    """
}

process buildFromFile {
    container params.xlsx2owl_image
    debug params.debug
    input:
        path xlsx, name: "xlsx2owl-tmp.xlsx"

    output:
        path '*out.ttl', emit: ttl
        // path '*.yml.ttl', emit: ymlttl
        path '*.nq', emit: nq
        path xlsx, emit: xlsx

    script:
    """
    bash -x "/home/user/xlsx2owl.sh"
    """
}

def getOnlineOrLocalChannel(xlsx) {
    if (isOnlineSource) {
        return channel.value(xlsx)
    }
    return channel.fromPath(xlsx)
}

def isOnlineSource(xlsx) {
    return xlsx.startsWith('http')
}

workflow build {
    take:
        xlsx
    main:
        if (isOnlineSource) { files = buildFromUrl(xlsx) }
        else { files = buildFromFile(Channel.fromPath(xlsx)) }
    emit:
        ttl = files.ttl
        nq = files.nq
        xlsx = files.xlsx
}

workflow {
    // xlsx = params.xlsx2owl_xlsxUrl ?: Channel.fromPath(params.xlsx2owl_xlsxFile)
    files = build(params.xlsx)
    files.ttl.view { name ->
        // println("${name.endsWith('rdf-out.ttl')} ${name}")
        // assert name.endsWith('rdf-out.ttl')
        assert name.endsWith('rdf-out.ttl')
        }
    files.xlsx.view()
    files.nq.view()
}
