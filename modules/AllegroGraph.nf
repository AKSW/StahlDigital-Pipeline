params.with{
    debug = true
}

process post {
    debug params.debug

    input:
        val user
        val password
        path data

    """
    curl -u ${user}:${password} -X POST -F 'file=@${data}' -H 'Content-Type: application/n-triples' 'http://localhost:10035/repositories/test/statements?continueOnError=true'
    """
}

process put {
    debug params.debug

    input:
        val user
        val password
        path data

    """
    curl -u ${user}:${password} -X PUT -F 'file=@${data}' -H 'Content-Type: application/n-triples' 'http://localhost:10035/repositories/test/statements?continueOnError=true'
    """
}