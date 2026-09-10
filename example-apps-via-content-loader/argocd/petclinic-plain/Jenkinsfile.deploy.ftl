#!groovy

String getApplication() { 'spring-petclinic-plain' }
String getConfigRepositoryPRRepo() { '${config.application.namePrefix}argocd/example-apps' }
String getScmManagerCredentials() { 'scm-user' }
String getConfigRepositoryPRBaseUrl() { env.${config.application.namePrefixForEnvVars}SCM_URL}
String getConfigRepositoryPRPrefixedUrl() { env.${config.application.namePrefixForEnvVars}PREFIXED_SCM_URL}

<#if config.registry.twoRegistries>
String getDockerRegistryProxyCredentials() { 'registry-proxy-user' }
</#if>

<#noparse>

String getCesBuildLibRepo() { configRepositoryPRPrefixedUrl+"3rd-party-dependencies/ces-build-lib/" }
String getGitOpsBuildLibRepo() { configRepositoryPRPrefixedUrl+"3rd-party-dependencies/gitops-build-lib" }

String getCesBuildLibVersion() { '2.5.0' }
String getGitOpsBuildLibVersion() { '0.8.0'}

loadLibraries()

properties([
        disableConcurrentBuilds(),
        parameters([
                string(name: 'DOCKER_IMAGE', defaultValue: '',
                        description: 'Full Docker image reference including tag or digest to deploy.',
                        trim: true)
        ])
])

node {
    String imageName = params.DOCKER_IMAGE?.trim()
    stage('Validate parameters') {
        if (!imageName) {
            error('DOCKER_IMAGE is required. Start this job with a full Docker image reference including tag or digest.')
        }
    }

    stage('Checkout') {
        checkout scm
    }

    stage('Deploy') {
        def gitopsConfig = [
                scm: [
                        provider     : 'SCMManager',
                        credentialsId: scmManagerCredentials,
                        baseUrl      : configRepositoryPRBaseUrl,
                        repositoryUrl   : configRepositoryPRRepo,
                ],
                application: application,
                gitopsTool: 'ARGO',
                folderStructureStrategy: 'ENV_PER_APP',
</#noparse>
                k8sVersion : env.${config.application.namePrefixForEnvVars}K8S_VERSION,
                deployments: [
                        sourcePath: 'k8s',
                        destinationRootPath: 'apps',
                        plain: [
                                updateImages: [
                                        [ filename: 'deployment.yaml',
                                          containerName: application,
                                          imageName: imageName ]
                                ]
                        ]
                ],
                fileConfigmaps: [
                        // Showcase for gitops-build-lib: Convert file into a config map
                        [
                                name : 'messages',
                                sourceFilePath : '../src/main/resources/messages/messages.properties',
                                stage: ['staging', 'production']
                        ]
                ],
                stages: [
                        staging: [
                                namespace: '${config.application.namePrefix}example-apps-staging',
                                deployDirectly: true ],
                        production: [
                                namespace: '${config.application.namePrefix}example-apps-production',
                                deployDirectly: false ],
                ]
        ]
<#noparse>
        gitopsConfig += createSpecificGitOpsConfig()

        deployViaGitops(gitopsConfig)
    }
}

/** Initializations might not be needed in a real-world setup, but are necessary to work in an air-gapped env, for example */
Map createSpecificGitOpsConfig() {
    [
        // In the GitOps playground, we're loading the build libs from our local SCM so it also works in an offline context
        // As the gitops-build-lib also uses the ces-build-lib we need to pass those parameters on.
        // If you can access the internet, you can rely on the defaults, which load the lib from GitHub.
        cesBuildLibRepo: cesBuildLibRepo,
        cesBuildLibVersion: cesBuildLibVersion,
        cesBuildLibCredentialsId: scmManagerCredentials,


        // The GitOps playground provides parameters for overwriting the build images used by gitops-build-lib, so
        // it also works in an offline context.
        // Those parameters overwrite the following parameters.
        // If you can access the internet, you can rely on the defaults, which load the images from public registries.
        buildImages          : [
</#noparse>
<#if config.registry.twoRegistries>
            helm:       [
                     image: '${config.content.variables.images.helm}',
                     credentialsId: dockerRegistryProxyCredentials
            ],
            kubectl:    [
                    image: '${config.content.variables.images.kubectl}',
                    credentialsId: dockerRegistryProxyCredentials
            ],
            kubeval:    [
                    image: '${config.content.variables.images.kubeval}',
                    credentialsId: dockerRegistryProxyCredentials
            ],
            helmKubeval: [
                    image: '${config.content.variables.images.helmKubeval}',
                    credentialsId: dockerRegistryProxyCredentials
            ],
            yamllint:   [
                    image: '${config.content.variables.images.yamllint}',
                    credentialsId: dockerRegistryProxyCredentials
            ]
<#else>
            helm: '${config.content.variables.images.helm}',
            kubectl: '${config.content.variables.images.kubectl}',
            kubeval: '${config.content.variables.images.kubeval}',
            helmKubeval: '${config.content.variables.images.helmKubeval}',
            yamllint: '${config.content.variables.images.yamllint}'
</#if>
<#noparse>
        ]
    ]
}

def loadLibraries() {
    // In the GitOps playground, we're loading the build libs from our local SCM so it also works in an offline context
    // If you can access the internet, you could also load the libraries directly from github like so
    // @Library(["github.com/cloudogu/ces-build-lib@${cesBuildLibVersion}", "github.com/cloudogu/gitops-build-lib@${gitOpsBuildLibRepo}"]) _
    //import com.cloudogu.ces.cesbuildlib.*
    //import com.cloudogu.ces.gitopsbuildlib.*

    cesBuildLib = library(identifier: "ces-build-lib@${cesBuildLibVersion}",
            retriever: modernSCM([$class: 'GitSCMSource', remote: cesBuildLibRepo, credentialsId: scmManagerCredentials])
    ).com.cloudogu.ces.cesbuildlib

    library(identifier: "gitops-build-lib@${gitOpsBuildLibVersion}",
            retriever: modernSCM([$class: 'GitSCMSource', remote: gitOpsBuildLibRepo, credentialsId: scmManagerCredentials])
    ).com.cloudogu.gitops.gitopsbuildlib
}

def cesBuildLib
def gitOpsBuildLib
</#noparse>
