#!groovy

String getApplication() { "spring-petclinic-helm" }
String getScmManagerCredentials() { 'scm-user' }
String getConfigRepositoryPRBaseUrl() { env.${config.application.namePrefixForEnvVars}SCM_URL}
String getConfigRepositoryPRPrefixedUrl() { env.${config.application.namePrefixForEnvVars}PREFIXED_SCM_URL}
String getConfigRepositoryPRRepo() { '${config.application.namePrefix}argocd/example-apps' }

<#if config.registry.twoRegistries>
String getDockerRegistryProxyCredentials() { 'registry-proxy-user' }
</#if>

<#noparse>

String getCesBuildLibRepo() { configRepositoryPRPrefixedUrl+"3rd-party-dependencies/ces-build-lib/" }
String getCesBuildLibVersion() { '2.5.0' }
String getGitOpsBuildLibRepo() { configRepositoryPRPrefixedUrl+"3rd-party-dependencies/gitops-build-lib" }
String getGitOpsBuildLibVersion() { '0.8.0'}
String getHelmChartRepository() { configRepositoryPRPrefixedUrl+"3rd-party-dependencies/spring-boot-helm-chart" }
String getHelmChartVersion() { "0.4.0" }
String getMainBranch() { 'main' }

cesBuildLib = library(identifier: "ces-build-lib@${cesBuildLibVersion}",
        retriever: modernSCM([$class: 'GitSCMSource', remote: cesBuildLibRepo, credentialsId: scmManagerCredentials])
).com.cloudogu.ces.cesbuildlib

gitOpsBuildLib = library(identifier: "gitops-build-lib@${gitOpsBuildLibVersion}",
    retriever: modernSCM([$class: 'GitSCMSource', remote: gitOpsBuildLibRepo, credentialsId: scmManagerCredentials])
).com.cloudogu.gitops.gitopsbuildlib

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
                scm                     : [
                        provider     : 'SCMManager',
                        credentialsId: scmManagerCredentials,
                        baseUrl      : configRepositoryPRBaseUrl,
                        repositoryUrl   : configRepositoryPRRepo,
                ],
                cesBuildLibRepo: cesBuildLibRepo,
                cesBuildLibVersion: cesBuildLibVersion,
                cesBuildLibCredentialsId: scmManagerCredentials,
                application: application,
                mainBranch: mainBranch,
                gitopsTool: 'ARGO',
                folderStructureStrategy: 'ENV_PER_APP',
</#noparse>
                k8sVersion : env.${config.application.namePrefixForEnvVars}K8S_VERSION,
                buildImages          : [
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
                ],
                deployments: [
                    sourcePath: 'k8s',
                    destinationRootPath: 'apps',
                    helm : [
                        repoType : 'GIT',
                        credentialsId : scmManagerCredentials,
                        repoUrl  : helmChartRepository,
                        version: helmChartVersion,
                        updateValues  : [[fieldPath: "image.name", newValue: imageName]]
                    ]
                ],
                stages: [
                        staging: [
                                namespace: '${config.application.namePrefix}example-apps-staging',
                                deployDirectly: true ],
                        production: [
                                namespace: '${config.application.namePrefix}example-apps-production',
                                deployDirectly: false ]
                ]
        ]
<#noparse>
        deployViaGitops(gitopsConfig)
    }
}

def cesBuildLib
def gitOpsBuildLib
</#noparse>
