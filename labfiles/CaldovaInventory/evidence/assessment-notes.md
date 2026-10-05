# Caldova workload assessment notes

## Baseline facts

| Area | Verified observation | Evidence file |
| --- | --- | --- |
| Application purpose | _Record the application purpose._ | _Record the file._ |
| API surface | _Record the routes._ | _Record the file._ |
| Framework | _Record the target framework._ | _Record the file._ |
| Database configuration | _Record where configuration is defined._ | _Record the file._ |
| Database access | _Record how reads and writes occur._ | _Record the file._ |
| Deployment | _Record the local deployment assumptions._ | _Record the file._ |

## Prioritized modernization findings

| Rank | Category | Finding and evidence | Risk | Effort | Customer value | Next action |
| ---: | --- | --- | --- | --- | --- | --- |
| 1 | _Category_ | _Finding and cited evidence._ | _Risk_ | _Size_ | _Value_ | _Action_ |
| 2 | _Category_ | _Finding and cited evidence._ | _Risk_ | _Size_ | _Value_ | _Action_ |
| 3 | _Category_ | _Finding and cited evidence._ | _Risk_ | _Size_ | _Value_ | _Action_ |

## Bounded change evidence

| Check | Result | Evidence |
| --- | --- | --- |
| Credential removed from C# source | _Pass or fail_ | _Describe the reviewed diff._ |
| Updated application builds | _Pass or fail_ | _Record the build result._ |
| Copilot CLI review matches acceptance criteria | _Pass or fail_ | _Record the review result and any difference from the IDE review._ |
| Copilot CLI build succeeds | _Pass or fail_ | _Record the reported error and warning counts._ |
| Health endpoint responds | _Pass or fail_ | _Record the response._ |
| Inventory read succeeds | _Pass or fail_ | _Record returned rows._ |
| Inventory write succeeds | _Pass or fail_ | _Record the created item._ |

## Azure migration evidence

| Check | Result | Evidence |
| --- | --- | --- |
| Local table migrated to Azure SQL Database | _Pass or fail_ | _Record the server, database, export and import results, and reconciled row count._ |
| Container image built | _Pass or fail_ | _Record the registry, image tag, and ACR build result._ |
| Container app deployed | _Pass or fail_ | _Record the app, environment, revision, and public URL._ |
| Connection string uses a secret reference | _Pass or fail_ | _Record the configuration without recording the secret value._ |
| Cloud health endpoint responds | _Pass or fail_ | _Record the public response._ |
| Cloud inventory read succeeds | _Pass or fail_ | _Record the initial row count._ |
| Cloud inventory write succeeds | _Pass or fail_ | _Record the created item and final row count._ |
| Deployment issues | _None or describe_ | _Record symptoms, logs, and resolution._ |

## Assumptions and discovery questions

- _Record facts that require customer validation, such as availability targets, database size, SQL Server features, downtime tolerance, private networking, identity, scaling, and recovery requirements._
