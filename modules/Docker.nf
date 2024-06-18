params.with{
    debug = true
}

process dockerLogin{
    debug params.debug
    // beforeScript 'docker login -u "${user}" -p "${password}" "${registry}"'

    input:
        val user
        val password
        val registry
    output:
        env SUCCESS, emit: success, optional: true

    // docker login -u $CI_REGISTRY_USER -p $CI_STAHL_REGISTRY_TOKEN $CI_REGISTRY
    """
    docker login -u "${user}" -p "${password}" "${registry}" && SUCCESS=true
    """

}

process pullImage {
    debug params.debug

    input:
        val image
    output:
        val image

    """
    docker pull "${image}"
    """
}

process buildImage {
    debug params.debug

    input:
        path dockerfile
        val label
        val tag

    output:
        val lavel
        val tag

    // cd $launchDir
    // if [[ "$CI_COMMIT_BRANCH" == "$CI_DEFAULT_BRANCH" ]]; then
    //     tag=""
    //     echo "Running on default branch "$CI_DEFAULT_BRANCH": tag = "latest""
    // else
    //     tag=":$CI_COMMIT_REF_SLUG"
    //     echo "Running on branch "$CI_COMMIT_BRANCH": tag = \$tag"
    // fi
    """
    docker build -t "${label}\${tag}" -f "${dockerfile}"
    """
}

/*
 * TODO: Description
 *
 */

process TODO_testImage {
    input:
        val buildImage
        val tag from tag.ifEmpty('')
    '''
    #!/usr/bin/env bash

    echo ""
    '''
}

/*
 * TODO: Description
 *
 */

process pushImageToRegistry {
    beforeScript "docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY"

    input:
        val testImage
        val tag

    when:
        params.pushImageToRegistry

    """
    #!/usr/bin/env bash

    docker push "$CI_REGISTRY_IMAGE${tag}"
    """
}

/*
 * TODO: Description
 *
 */


process removeImageLocally {
    input:
        val removeChannel
        val tag from tag.ifEmpty('')

    when:
        params.removeImageLocally

    """
    #!/usr/bin/env bash

    docker image remove "$CI_REGISTRY_IMAGE\${tag}"
    """
}

/*
 * TODO: Description
 *
 */

process dockerImage {
    label ''
    tag ''

    input:
        val tag from tag.ifEmpty('')
        val removeImageLocally from params.removeImageLocally.ifempty('')
        val pushImageToRegistry from params.pushImageToRegistry.ifEmpty('')

    output:
        val '' into buildImage
        env tag,  optional: true into tag

    when:
        params.buildDockerfile

    """
    #!/usr/bin/env bash
    cd $launchDir

    if [[ "$CI_COMMIT_BRANCH" == "$CI_DEFAULT_BRANCH" ]]; then
        tag=""
        echo "Running on default branch "$CI_DEFAULT_BRANCH": tag = "latest""
    else
        tag=":$CI_COMMIT_REF_SLUG"
        echo "Running on branch "$CI_COMMIT_BRANCH": tag = \$tag"
    fi

    docker build --pull -t "$CI_REGISTRY_IMAGE\${tag}" .

    if [[ $pushImageToRegistry ]]; then
        docker push "$CI_REGISTRY_IMAGE${tag}"
    fi

    if [[ $removeImageLocally ]]; then
        docker image remove "$CI_REGISTRY_IMAGE\${tag}"
    fi

    cd -
    """
}