# Cargo Tracker Open Liberty on AKS Deployment Run

## Run identity

- Date: 2026-09-29
- Repository: `azure-javaee/cargotracker-liberty-aks`
- Branch: `edburns/dd-3016202-cargotracker-devoxx-be-2026`
- Prompt-recorded starting commit: `e9cea44`
- Actual starting commit: `5e7e1e5dc17a29ae8529256d24f5e71ae46f3ad3`
- Difference from the prompt-recorded commit: only the campaign prompt itself was updated.
- Azure tenant: `72f988bf-86f1-41af-91ab-2d7cd011db47`
- Azure subscription: `Open Standard Enterprise Java Testing with TTL = 7 Days`
- Azure subscription ID: `05887623-95c5-4e50-a71c-6e1c738794e2`
- Azure user: `edburns@microsoft.com`
- Initial attempted region/environment: `eastus` / `eb-ct-olaks-20260929`
- Successful region/environment: `westus2` / `eb-ct-olaks-w2-20260929`

No credentials, connection strings, database passwords, kubeconfig content, or generated secret values are recorded in this report.

## Baseline

| Component | Observed version/status | Requirement/result |
| --- | --- | --- |
| JDK | Microsoft OpenJDK 17.0.18 | Meets JDK 17 requirement |
| Maven | 3.8.7 | Below the required 3.9.8 minimum; a repository-local current Maven 3 installation is used below |
| Azure CLI | 2.90.0 | Meets the 2.61.0 minimum |
| Azure Developer CLI | 1.34.2 | Authenticated through the existing Azure CLI session |
| Bicep | 0.47.16 | Installed through `az bicep install` |
| Docker | Windows Docker CLI shim present, but Docker Desktop WSL integration unavailable | Local container build is unavailable; Azure Container Registry remote build is used |
| Helm | Not initially installed | A repository-local Helm 3 installation is used below |
| kubectl | Not initially installed for Linux | A repository-local Linux kubectl installation is used below |
| Git | 2.43.0 | Available |

The active subscription is enabled and the required Azure resource providers
for AKS, ACR, networking, PostgreSQL, Log Analytics, and Azure Monitor are
registered. The first `eastus` deployment was not viable: the TTL subscription
offered only confidential-compute AKS VM SKUs whose relevant quota was zero,
and PostgreSQL Flexible Server returned no supported versions in that region.
Those failed resources were deleted with `azd down --purge --force
--no-prompt`. `westus2` was then selected and provisioned successfully.

## Investigation findings

- The automated path was internally inconsistent: `infra/main.bicep`, the environment-variable template, the README, and the GitHub workflow referenced different `WASdev/azure.liberty.aks` commits.
- `azure.yaml` used remote chart version `1.0.8` even though the repository contains the chart and deployment templates that must evolve with the application.
- Azure OpenAI was documented as optional but was provisioned unconditionally. The chart also always created an OpenAI secret and required its keys in the pod specification.
- The application itself already has a deterministic non-AI fallback in `GraphTraversalService`, but `ShortestPathAiImpl` initialized its model statically whenever CDI instantiated the bean.
- The AKS packaging profile pinned Open Liberty `23.0.0.9`, Application Insights Java agent `3.4.11`, and an unversioned Open Liberty image tag.
- The predeploy hook required Docker Desktop, enabled ACR admin credentials, and performed password-based Docker login even though `az acr build` is sufficient.
- `infra/main.parameters.json` supplied a nonexistent `principalId` parameter.
- The Bicep outputs and hooks disagreed on namespace naming (`AZURE_AKS_NAMESPACE` versus `NAMESPACE`) and Azure OpenAI deployment naming.
- Generated database and Application Insights secret manifests are ignored only indirectly as WAR/build output; `custom-values.yaml` is explicitly ignored.
- The legacy GitHub workflow uses retired Ubuntu 20.04 runners, old actions, `set-output`, a misspelled `ture` condition, an invalid `export ******` line, and an outdated Azure CLI pin. It is not the restored primary path.
- The root Payara `Dockerfile` and `cargo-tracker.yml` are unrelated deployment surfaces and are not used.

## Commands and evidence

### Local validation

- A repository-local Maven 3.9.16 installation was used with Microsoft OpenJDK
  17.0.18.
- The Java source, unit tests, WAR, Open Liberty server package, and AKS Docker
  context build successfully.
- Open Liberty starts under Arquillian after removing the deployment-only
  Application Insights agent from local `jvm.options`.
- `helm lint` and `helm template` succeed against the local chart.
- `az bicep build --file infra/main.bicep` succeeds. The generated upstream
  Liberty-on-AKS module emits linter warnings but no compilation errors.
- Four legacy Arquillian integration-test errors remain. They are limited to
  missing routing CSV resources in the ShrinkWrap test archive and EclipseLink
  implementation classes needed by client-side serialized assertions. Open
  Liberty starts and deploys the test application successfully before those
  assertions fail.

### Provisioning and deployment

- `azd provision --no-prompt` completed in `westus2`.
- The WSL instance restarted after the Azure subscription deployment had
  completed. Re-running `azd provision --no-prompt` was idempotent and
  completed the local output and post-provision steps.
- `azd deploy demo --no-prompt` was validated after explicitly removing
  `CARGO_TRACKER_IMAGE` from the azd environment, proving that the first-run
  path works from the predeploy hook.
- The predeploy hook runs `mvn clean package -PopenLibertyOnAks`, creates a
  unique commit-and-timestamp image tag, and submits a Linux AMD64 build to ACR
  with `az acr build`.
- `azure.yaml` uses `docker.imagePassthrough`, so azd applies the local Helm
  chart without requiring Docker or rebuilding the image through azd.
- The final successful ACR build was run `cc9`.
- The final successful deployment log is
  `20260929-2210-azd-final-deploy-logs.txt` (ignored by Git).
- The postdeploy hook waits for the Open Liberty Operator to reconcile the
  exact image, waits for the generated Deployment rollout, and waits for the
  public Application Gateway URL to return HTTP 200.

## Azure resource inventory

Resource group: `rg-eb-ct-olaks-w2-20260929-44exlg`

| Resource | Name / status |
| --- | --- |
| AKS | `cluster2396a7`, Kubernetes 1.35.7, Running |
| AKS node pool | `Standard_D2s_v5`, autoscaling 1-3, two nodes at verification |
| Node OS | Ubuntu 24.04, image `AKSUbuntu-2404gen2containerd-202609.15.0` |
| ACR | `acr2396a7` |
| Open Liberty Operator | 1.6.2, image digest `sha256:35bc43e7b4705ef15f4614f81b8ebe94fad6f43e5576d9114412e253cb9b4c3d` |
| Helm release | `demo`, namespace `default`, local chart revision 3 |
| Application Gateway | `appgw2396a7` |
| Public IP / DNS | `gwip2396a7` / `olgw2396a7.westus2.cloudapp.azure.com` |
| PostgreSQL Flexible Server | `liberty-server-44exlg`, PostgreSQL 16, `Standard_B1ms`, Ready |
| Database | `liberty-db-44exlg` |
| Log Analytics | `log-44exlgyj5u75u`, Succeeded, 30-day retention |
| Application Insights | `appi-44exlgyj5u75u` |
| Key Vault | `keyvault2396a7` |

Final application image:

- Image:
  `acr2396a7.azurecr.io/cargo-tracker:3.2-SNAPSHOT-5e7e1e5dc17a-20260929215148`
- Digest:
  `sha256:81bb388341272a987a64846a2ebaaf5bc781c4043226d4f7ee528cda9910e254`
- Base image:
  `icr.io/appcafe/open-liberty:26.0.0.9-full-java17-openj9-ubi-minimal`
- Base digest:
  `sha256:7776cc3a9fa15cacbf961947def8929bc4b524e42b2dc40fb9eca2072714093c`
- OCI revision:
  `5e7e1e5dc17a29ae8529256d24f5e71ae46f3ad3`

## Functional verification

Verification was performed on 2026-09-29 between 21:42 and 21:56 UTC.

| Check | Evidence |
| --- | --- |
| Operator reconciliation | `OpenLibertyApplication/cargo-tracker-cluster` reports `Reconciled=True`, `ResourcesReady=True`, and `Ready=True` |
| Pods | Two replicas Ready, zero restarts, on separate AKS nodes |
| Running image | Both pods use digest `sha256:81bb388341272a987a64846a2ebaaf5bc781c4043226d4f7ee528cda9910e254` |
| Public root | HTTP 200 from `http://olgw2396a7.westus2.cloudapp.azure.com/cargo-tracker/` |
| Administration | HTTP 200 from `/cargo-tracker/admin/dashboard.xhtml`, title `Cargo Dashboard` |
| Tracking | JSF tracking request for `ABC123` reports `Onboard voyage 0200T` |
| AI-disabled routing | `/rest/graph-traversal/shortest-path?origin=CNHKG&destination=SESTO&deadline=20261030` returns HTTP 200 and a non-empty JSON route list without Azure OpenAI |
| Valid handling report | JSON `LOAD` report for `ABC123`, `USNYC`, voyage `0200T` returned HTTP 204 |
| Invalid handling report | Deliberately malformed report returned HTTP 400 with field-level validation messages and `Validation-Exception: true` |
| Asynchronous handling | Liberty logs record receipt, `Cargo was handled ABC123`, and `Registered handling event` |
| PostgreSQL persistence | `handlingevent` row 48 contains the new `LOAD` event; the tracking UI continues to show `Loaded onto voyage 0200T in New York` after pod replacement |
| Application Insights | Request telemetry includes successful root/JSF requests, the HTTP 200 shortest-path call, the HTTP 204 valid handling call, and the expected HTTP 400 invalid call |
| Application traces | Application Insights recorded 309 informational and 9 warning traces during the verification window |
| Container Insights | `ContainerLogV2` contains hundreds of records from both Cargo Tracker pods, including records through the handling-report verification time |

Application Insights Java agent 3.7.10 reports successful startup in both
containers. Open Liberty reports the JMS server and `cargo-tracker` application
started successfully.

## Future `e7b651f` Java EE 7 / `javax.*` integration delta

The lineage commit is
`Azure-Samples/cargotracker-azure@e7b651fb3ed8bc17c338face1c7ff960618fcd95`
(2020-09-27). It is not an object in this repository. Its application contains
107 Java source files, produces `cargo-tracker.war`, compiles at Java source and
target level 7, and depends on `javax:javaee-api:7.0`.

- **Maven profile and WAR handoff:** build the lineage application as a
  separate input and copy its final `cargo-tracker.war` into the existing
  Open Liberty image context. Do not overlay its old Payara/Cargo deployment
  profile onto this repository. A dedicated Maven property/profile should make
  the external WAR path explicit while retaining this repository's Liberty,
  JDBC driver, agent, image, Helm, and azd packaging.
- **Java level:** keep the runtime on JDK 17. The old POM's source/target 1.7
  settings and old plugins need validation or updating so the WAR can be built
  reproducibly with the selected JDK 17 toolchain.
- **Platform namespace:** the lineage source and descriptors use `javax.*`,
  Java EE 7 XML namespaces, Servlet 3.1, JSF 2.2, CDI 1.2, JPA 2.1, JAX-RS
  2.0, JMS 2.0, EJB 3.2, and Batch 1.0. They cannot run under the current
  Jakarta EE 10 feature set because that set exposes `jakarta.*` APIs.
- **Liberty features:** create a separate Java EE 7 `server.xml` using
  `javaee-7.0` or the equivalent explicit Java EE 7 features, plus the current
  JDBC/shared-library and context-root configuration. Open Liberty's current
  Java EE 7 feature supports Java 17, so the deployment does not require a
  Java runtime downgrade. Do not mix incompatible Java EE 7 and Jakarta EE 10
  feature generations in one server.
- **Database and persistence:** replace the lineage WAR's embedded Derby
  datasource with the existing JTA datasource
  `java:app/jdbc/CargoTrackerDatabase` backed by PostgreSQL JDBC 42.7.13.
  Preserve the JNDI name expected by `persistence.xml`. Validate EclipseLink
  JPA 2.1 mappings and schema generation against PostgreSQL 16 before reusing
  any existing schema; use an isolated database/schema for the first swap.
- **JMS and batch:** retain Liberty's in-process messaging server and define
  the five `java:app/jms/*` destinations expected by the Java EE 7 `web.xml`.
  Enable Batch 1.0 and verify the event-file job repository tables and
  PostgreSQL prepared transactions.
- **JSF and web configuration:** retain context root `/cargo-tracker`, but use
  the lineage `javax.faces.*` settings, JSF 2.2 behavior, and its older
  PrimeFaces assets. Do not copy the current Jakarta Faces 4 descriptor into
  the lineage WAR.
- **REST routing:** preserve the
  `java:app/configuration/GraphTraversalUrl` environment entry. Decide whether
  the lineage WAR consumes the current pathfinder service as a separate
  endpoint or packages it; keep the externally tested shortest-path URL stable
  if possible.
- **Container image:** reuse the current Java 17/OpenJ9 UBI Minimal base,
  PostgreSQL driver, Application Insights agent, OCI revision label, ACR build,
  and unique image tagging. Swap only the WAR and the Java EE 7 Liberty
  configuration.
- **Acceptance tests that remain valid:** pod readiness and zero restarts,
  `/cargo-tracker/`, Administration, `ABC123`, shortest-path response, valid
  and invalid handling reports, PostgreSQL persistence, Application Insights,
  and `ContainerLogV2`.
- **Infrastructure reusable unchanged:** AKS, ACR, Application Gateway,
  ingress, Open Liberty Operator, PostgreSQL Flexible Server, Log Analytics,
  Application Insights, Key Vault, Helm release mechanics, and azd
  provisioning can all be reused. The application image/configuration is the
  integration boundary.

## Reproduction

From a fresh shell:

```bash
export JAVA_HOME=/path/to/jdk-17
export PATH="${JAVA_HOME}/bin:${PATH}"

az login
azd config set auth.useAzCliAuth true
azd auth status --no-prompt

azd env new <unique-environment-name> \
  --location westus2 \
  --subscription <subscription-id> \
  --no-prompt

azd env set DB_ADMIN_PASSWORD \
  "$(openssl rand -base64 36 | tr -d '/+=' | cut -c1-32)"
azd env set LIBERTY_AKS_REPO_REF \
  1bfcc50b1bfdb4165d4ce5a5deb62b5b5346a3cc

azd provision --no-prompt
azd deploy demo --no-prompt

export CARGO_TRACKER_URL="$(azd env get-value CARGO_TRACKER_URL)"
curl --fail --show-error --location "${CARGO_TRACKER_URL}"
curl --fail --show-error \
  -H "Accept: application/json" \
  "${CARGO_TRACKER_URL}rest/graph-traversal/shortest-path?origin=CNHKG&destination=SESTO&deadline=20261030"
```

Docker is not required. The predeploy hook builds in ACR. The postdeploy hook
does not complete until the exact image is reconciled, the generated
Deployment is rolled out, and the public URL returns HTTP 200.

## Changed files

- `.gitignore`: excludes repository-local tools and root command logs.
- `.scripts/setup-env-variables-template.sh`: pins the current Liberty-on-AKS
  source revision.
- `README.md`: documents the repaired azd path and current prerequisites.
- `azure.yaml`: uses the local chart, explicit AKS resource identity, and image
  passthrough.
- `azd-hooks/preprovision.sh`: reproducibly builds the pinned upstream Bicep
  module.
- `azd-hooks/postprovision.sh`: configures kube credentials, monitoring, and
  PostgreSQL prepared transactions.
- `azd-hooks/predeploy.sh`: builds the Liberty package, uses ACR remote build,
  creates unique image tags and secret Helm values, and records the image.
- `azd-hooks/postdeploy.sh`: performs bounded operator, rollout, ingress, and
  HTTP readiness waits.
- `infra/main.bicep`, `infra/main.parameters.json`: reconcile the current
  module contract, supported AKS/PostgreSQL choices, optional AI behavior, and
  required outputs.
- `charts/cargotracker-liberty-aks/*`: make OpenAI optional, inject the
  Application Insights agent only in AKS, use consistent namespaces, and
  deploy two replicas.
- `pom.xml`: pins Open Liberty 26.0.0.9, Application Insights 3.7.10, and
  PostgreSQL JDBC 42.7.13.
- `src/main/java/org/eclipse/pathfinder/api/GraphTraversalService.java`,
  `ShortestPathAiImpl.java`: make Azure OpenAI lazy and optional with the
  deterministic fallback.
- `src/main/liberty/config/*`, `src/main/liberty/docker/*`,
  `src/main/liberty/aks/openlibertyapplication.yaml`: use the immutable Open
  Liberty image, preserve local startup, add the test library, and carry the
  deployment-only agent configuration.
- `src/test/java/org/eclipse/cargotracker/application/BookingServiceTest.java`,
  `src/test/resources/arquillian.xml`, `test-liberty-web.xml`,
  `test-beans.xml`: restore the Open Liberty Arquillian test setup.
- This deployment report records the durable evidence and future lineage
  integration boundary.

## Cleanup

The successful deployment is intentionally retained for human inspection.

```bash
azd down \
  --environment eb-ct-olaks-w2-20260929 \
  --purge \
  --force \
  --no-prompt
```

Do not run that command until the retained environment has been inspected.

## Residual risks

- Four legacy Arquillian client-side test errors remain as described under
  local validation. They do not affect the deployed application.
- The legacy GitHub Actions workflow remains stale and is not the supported
  path restored by this work.
- The generated upstream Bicep module has linter warnings involving
  nondeterministic names, nullable modules, and reference syntax.
- The upstream solution enables the ACR admin account. The deployment path
  does not consume admin credentials, but disabling it was outside this
  focused restoration.
- Application Gateway currently exposes HTTP. Production TLS, a custom domain,
  WAF policy tuning, private networking, and workload identity hardening were
  not part of this spike.
- The Open Liberty Operator reports a warning because managed TLS is enabled
  while the service port is 9080; reconciliation and readiness still succeed.
- Each deployment creates a unique ACR image tag. Old spike tags should be
  pruned when the retained environment is no longer needed.
- The ACR build context is about 175 MiB because it contains the packaged
  Liberty server. This is functional but could be optimized separately.
- Azure OpenAI is disabled and was not provisioned or tested. The deterministic
  shortest-path behavior is the verified default.
- The retained Azure resources continue to incur cost until cleanup.
