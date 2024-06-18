
CI = System.getenv('CI_SERVER') ?: ''
if (!CI) {
    evaluate(new File('secrets'))
}

params.with{
    debug = true
    container = "bitnami/git"
    // Not possible here
    // token = System.getenv('GITLAB_TEST_TOKEN') ?: GITLAB_TEST_TOKEN
    repository = 'https://git.infai.org/nextflow/testgitlabcommit.git'
    commitUsername = "Script"
    commitEmail = ""
}

// params.token = System.getenv('GITLAB_TEST_TOKEN') ?: GITLAB_TEST_TOKEN

process hasChanged{
    debug params.debug
    container params.container
    stageInMode "copy"

    input:
        path files
        val repository
        val token
    output:
        env CHANGED, emit: changed optional true
        // path files, emit: files
    
    // # git config --global credential.helper '!f() { echo "username=TOKEN"; echo "password=${token}"; }; f'
    """
    TASK_DIR=\$(pwd)
    git config --global credential.helper '!f() { echo "username=TOKEN"; echo "password=${token}"; }; f'
    git clone --depth 1 "${repository}" repository

    cd repository
    for f in ${files}; do
        cp ../\${f} .
    done
    # Check for changes
    if [ -n "\$(git status -s)" ]; then
        CHANGED="true"
    fi
    cd \$TASK_DIR
    """
}

// TODO
// process diff{
//     debug params.debug
//     container params.container
//     stageInMode "copy"

//     input:
//         val repository
//         val token
//         path files
//         val commitUsername
//         val commitEmail
//         val commitMessage
//     output:
//         env CHANGED, emit: changed optional true
//         // path files, emit: files
    
//     // # git config --global credential.helper '!f() { echo "username=TOKEN"; echo "password=${token}"; }; f'
//     """
//     TASK_DIR=\$(pwd)
//     git config --global credential.helper '!f() { echo "username=TOKEN"; echo "password=${token}"; }; f'
//     git clone --depth 1 "${repository}" repository
//     CHANGED="false"

//     cd repository
//     for f in ${files}; do
//         cp ../\${f} .
//     done
//     # Check for changes
//     if [ -n "\$(git status -s)" ]; then
//         CHANGED="true"
//     fi
//     cd \$TASK_DIR
//     """
// }

process commit{
    debug params.debug
    container params.container
    stageInMode "copy"

    input:
        path files
        val repository
        val token
        val commitUsername
        val commitEmail
        val commitMessage
    output:
        env CHANGED, emit: changed, optional: true

    
    // # git config --global credential.helper '!f() { echo "username=TOKEN"; echo "password=${token}"; }; f'
    """
    TASK_DIR=\$(pwd)
    git config --global credential.helper '!f() { echo "username=TOKEN"; echo "password=${token}"; }; f'
    git clone --depth 1 "${repository}" repository

    cd repository || exit
    mkdir -p artifacts || exit

    for f in ${files}; do
        cp -r ../\${f} artifacts/
    done

    # Check for changes
    if [ -n "\$(git status -s)" ]; then
        CHANGED="true"

        rm -rf artifacts
        mkdir -p artifacts || exit

        for f in ${files}; do
            cp -r ../\${f} artifacts/
        done

        git config --local user.email "${commitEmail}"
        git config --local user.name "${commitUsername}"
        for f in ${files}; do
            git add -A artifacts/\${f}
        done
        # git add ${files}
        git commit -m "Update ${files}"
        git push
    fi
    cd \$TASK_DIR
    """
}

process generateTestFiles{
    debug params.debug
    container params.container
    output:
        path '*.txt', emit: files
    """
    for i in \$(seq 1 2); do
        base64 /dev/urandom |tr 0-9 ' ' | tr '[:punct:]' '\n' | head -c 1024 > f\${i}.txt
    done
    """
}

workflow{
    generateTestFiles().files.view()
    commit(params.repository, params.token, generateTestFiles.out.files, params.commitUsername, params.commitEmail, "").changed.view()
    // diff(params.repository, params.token, generateTestFiles.out.files, params.commitUsername, params.commitEmail, "").changed.view()
}

process pushToQuitstoreRepository {
    container 'ubuntu:22.04'
    //beforeScript "apt update && apt install -y git raptor2-utils"
    // echo true
    input:
        path ttl
    val repo from params.storeRepository
    env QUITSTORE_TOKEN
    env QUITSTORE_USER
    val userEmail from params.userEmail
    val userName from params.userName

    """
    apt update
    apt install -y git raptor2-utils
    git config --global credential.helper '!f() { echo "username=${QUITSTORE_USER}"; echo "password=${QUITSTORE_TOKEN}"; }; f'
    git clone "https://git.infai.org/materialdigital/stahldigital/store.git"

    cd store
    # rapper -i turtle -o ntriples $ttl | LC_ALL=C sort -u > SteelProcessOntology.nt
    rapper -i turtle -o ntriples ../$ttl | LC_ALL=C sort -u > SteelProcessOntology.nt && git add SteelProcessOntology.nt

    if [ -n "\$(git status -s)" ]; then
        git config --global user.email "$userEmail"
        git config --global user.name "$userName"
        git commit -m "Pushing latest changes"
        git push
    fi
    """
}

process gitlabLogin{
    """
    """
}