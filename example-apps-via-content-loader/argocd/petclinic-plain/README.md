# Petclinic plain pipelines

Build and deployment run independently:

* `Jenkinsfile` checks out the application, builds and tests it, and builds and pushes the Docker image as before. It does not trigger deployment.
* `Jenkinsfile.deploy` takes a `DOCKER_IMAGE` string parameter, checks out the Kubernetes resources and application sources from this repository, and calls `deployViaGitops`. It renders and validates manifests and updates the `argocd/example-apps` GitOps repository. Argo CD applies the changes. Staging is updated directly; production uses a pull request as before.

The ContentLoader renders the source templates `Jenkinsfile.ftl` and `Jenkinsfile.deploy.ftl` into these script paths in the generated `argocd/petclinic-plain` repository.

## Configure the deploy job

The GOP configuration's `createJenkinsJob: true` creates the existing build job. Adding a second Jenkinsfile does not automatically create another job. In Jenkins, create an additional **Pipeline** job, for example `petclinic-plain-deploy`, with:

* **Definition:** Pipeline script from SCM
* **SCM:** Git
* **Repository URL:** the same generated SCM-Manager `argocd/petclinic-plain` repository used by the build job (including the configured name prefix)
* **Credentials:** `scm-user`
* **Branch Specifier:** `*/main`
* **Script Path:** `Jenkinsfile.deploy`
* **This project is parameterized:** string parameter `DOCKER_IMAGE`, with an empty default

Configure the parameter when creating the job so that **Build with Parameters** is available on the first run. The pipeline also declares it itself; a run without an image fails before checkout or deployment. Keep SCM polling and automatic build triggers disabled for this job. Use the same Jenkins environment and agent setup as the build job, including the GOP environment variables, Docker access and registry credentials.

## Deploy an image

After a successful image push, copy the full image reference from the build's Docker stage output. Start the deploy job using **Build with Parameters**, for example with `DOCKER_IMAGE=registry.example.org/spring-petclinic-plain:202609101200-abc1234-main`. An image reference pinned by digest is also supported.

The deploy job does not rebuild the image. It updates the image of the `spring-petclinic-plain` container in `deployment.yaml` for both environments using the deployment configuration checked out from `main`. The `messages` ConfigMap is still generated from `src/main/resources/messages/messages.properties` in that checkout. It can also deploy a previously published image independently of a new application build.
