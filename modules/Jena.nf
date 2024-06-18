params.debug = false

process mergeTtlFiles {
    debug params.debug
    container 'stain/jena:4.0.0'
    stageInMode 'copy'
    errorStrategy 'ignore'

    input: 
        path ttlFiles
    output:
        path 'merged-files.ttl', emit: mergedTtl

    """
    riot --quiet --formatted=Turtle $ttlFiles > "merged-files.ttl"
    """
}