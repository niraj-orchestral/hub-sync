# Pack report 2026-11-26

StackStorm-Exchange → orchestral-hub

| | |
|---|---|
| Packs on the hub | 174: 173 OK, 1 WARN, 0 FAIL |
| Up to date with upstream | 174 |
| Open PRs on the hub | 0 (0 failing) |
| Open PRs upstream | 74 (74 new since last report, 0 recreated on the hub) |

## Packs that need attention

| Pack | Check | Version | Upstream | Issues |
|---|---|---|---|---|
| robotpack | WARN | 0.0.2 | up to date | no python_versions (warn) |

## Open PRs on orchestral-hub

None.

## New upstream PRs since the last report

| PR | Author | Updated | On hub | Title |
|---|---|---|---|---|
| [stackstorm-ansible#11](https://github.com/StackStorm-Exchange/stackstorm-ansible/pull/11) | `cognifloyd` | 2022-05-11 | no | Add json parameter to get JSON output from ansible.command* |
| [stackstorm-ansible#14](https://github.com/StackStorm-Exchange/stackstorm-ansible/pull/14) | `cognifloyd` | 2022-05-11 | no | Add extra_vars parsing directives due to Jinja |
| [stackstorm-ansible#52](https://github.com/StackStorm-Exchange/stackstorm-ansible/pull/52) | `jodygilbert` | 2024-09-07 | no | Support ansible collections and fix vault commands |
| [stackstorm-aws#38](https://github.com/StackStorm-Exchange/stackstorm-aws/pull/38) | `AndyMoore` | 2022-06-10 | no | addition of role and region flags |
| [stackstorm-aws#91](https://github.com/StackStorm-Exchange/stackstorm-aws/pull/91) | `grepory` | 2025-02-07 | no | Add SQSServiceSensor for non-polling SQS sensor |
| [stackstorm-aws#102](https://github.com/StackStorm-Exchange/stackstorm-aws/pull/102) | `cholletk` | 2022-05-11 | no | Fix issue with multiaccount (TypeError: client() got an unexpected ke… |
| [stackstorm-aws#109](https://github.com/StackStorm-Exchange/stackstorm-aws/pull/109) | `drksnw` | 2022-06-07 | no | Modified action.py in order to have filters in a more conveinent way |
| [stackstorm-aws#113](https://github.com/StackStorm-Exchange/stackstorm-aws/pull/113) | `kylestewart` | 2022-05-11 | no | Fix for SQS Sensor when configured credentials are 'None' |
| [stackstorm-aws_boto3#21](https://github.com/StackStorm-Exchange/stackstorm-aws_boto3/pull/21) | `DuaneB-TD` | 2022-05-11 | no | Add support for session token to assume_role action |
| [stackstorm-aws_s3#1](https://github.com/StackStorm-Exchange/stackstorm-aws_s3/pull/1) | `AndyMoore` | 2022-05-11 | no | testing CI |
| [stackstorm-azure#17](https://github.com/StackStorm-Exchange/stackstorm-azure/pull/17) | `cognifloyd` | 2022-05-11 | no | Drop azure bundles |
| [stackstorm-azure#19](https://github.com/StackStorm-Exchange/stackstorm-azure/pull/19) | `philipphomberger` | 2023-11-03 | no | Update Dependencys \| Close Sync SEC Findings |
| [stackstorm-backups#18](https://github.com/StackStorm-Exchange/stackstorm-backups/pull/18) | `nmaludy` | 2022-05-12 | no | Remove Postgres backups |
| [stackstorm-bitbucket#18](https://github.com/StackStorm-Exchange/stackstorm-bitbucket/pull/18) | `blag` | 2022-05-12 | no | Add action to open a PR |
| [stackstorm-bolt#12](https://github.com/StackStorm-Exchange/stackstorm-bolt/pull/12) | `bishopbm1` | 2022-05-20 | no | Byte String Fixes |
| [stackstorm-cisco_aci#18](https://github.com/StackStorm-Exchange/stackstorm-cisco_aci/pull/18) | `ankita-orchestral` | 2022-05-11 | no | Fixed pack installation issue |
| [stackstorm-csv#9](https://github.com/StackStorm-Exchange/stackstorm-csv/pull/9) | `Kami` | 2022-05-12 | no | [DONT MERGE] Test new Circle CI config with Python 3 tasks |
| [stackstorm-elasticsearch#19](https://github.com/StackStorm-Exchange/stackstorm-elasticsearch/pull/19) | `AbhyudayaSharma` | 2022-05-11 | no | Add support for Elasticsearch 7.x |
| [stackstorm-email#30](https://github.com/StackStorm-Exchange/stackstorm-email/pull/30) | `farhan27` | 2022-05-11 | no | add content id for attachments |
| [stackstorm-email#37](https://github.com/StackStorm-Exchange/stackstorm-email/pull/37) | `anirudhbagri` | 2022-05-11 | no | Update polling interval for email sensor |
| [stackstorm-email#46](https://github.com/StackStorm-Exchange/stackstorm-email/pull/46) | `minsis` | 2023-09-07 | no | Remove account requirements |
| [stackstorm-foreman#13](https://github.com/StackStorm-Exchange/stackstorm-foreman/pull/13) | `cyberkov` | 2022-05-16 | no | Regenerate API definitions for Foreman 1.24.3 |
| [stackstorm-foreman#14](https://github.com/StackStorm-Exchange/stackstorm-foreman/pull/14) | `cyberkov` | 2022-05-16 | no | Fix write command for python3 |
| [stackstorm-freeipa#7](https://github.com/StackStorm-Exchange/stackstorm-freeipa/pull/7) | `jschoewe` | 2023-06-09 | no | update/fix-scripts-to-work-with-st2-35 |
| [stackstorm-github#47](https://github.com/StackStorm-Exchange/stackstorm-github/pull/47) | `MarlonHeiber` | 2022-11-11 | no | V2.2.0 |
| [stackstorm-github#52](https://github.com/StackStorm-Exchange/stackstorm-github/pull/52) | `alexatx15` | 2023-02-13 | no | Using v2.2.0 (as per PR) , and adding GitHub security actions |
| [stackstorm-github#53](https://github.com/StackStorm-Exchange/stackstorm-github/pull/53) | `dependabot[bot]` | 2023-05-22 | no | Bump requests from 2.23.0 to 2.31.0 |
| [stackstorm-gitlab#12](https://github.com/StackStorm-Exchange/stackstorm-gitlab/pull/12) | `ManonDe18` | 2024-01-26 | no | Action epic.create using python gitlab library |
| [stackstorm-gitlab#13](https://github.com/StackStorm-Exchange/stackstorm-gitlab/pull/13) | `ManonDe18` | 2026-06-05 | no | Add action to create an issue |
| [stackstorm-gitlab#14](https://github.com/StackStorm-Exchange/stackstorm-gitlab/pull/14) | `bishopbm1` | 2025-10-29 | no | feature/gitlab-issues |
| [stackstorm-git#16](https://github.com/StackStorm-Exchange/stackstorm-git/pull/16) | `dependabot[bot]` | 2024-01-10 | no | Bump gitpython from 3.1.40 to 3.1.41 |
| [stackstorm-jira#19](https://github.com/StackStorm-Exchange/stackstorm-jira/pull/19) | `pdenning` | 2026-11-18 | no | Multi profiles |
| [stackstorm-jira#39](https://github.com/StackStorm-Exchange/stackstorm-jira/pull/39) | `viveksyngh` | 2026-08-05 | no | Add client cert support and new action |
| [stackstorm-jira#92](https://github.com/StackStorm-Exchange/stackstorm-jira/pull/92) | `dependabot[bot]` | 2026-03-14 | no | Bump pyjwt from 2.4.0 to 2.12.0 |
| [stackstorm-jira#93](https://github.com/StackStorm-Exchange/stackstorm-jira/pull/93) | `kszarek` | 2026-08-11 | no | Expose issue type and status category metadata |
| [stackstorm-jira#94](https://github.com/StackStorm-Exchange/stackstorm-jira/pull/94) | `kszarek` | 2026-08-21 | no | Pin CI to the stable StackStorm release |
| [stackstorm-kafka#22](https://github.com/StackStorm-Exchange/stackstorm-kafka/pull/22) | `dependabot[bot]` | 2026-09-01 | no | Bump kafka-python from 2.0.2 to 2.3.2 |
| [stackstorm-manageiq#13](https://github.com/StackStorm-Exchange/stackstorm-manageiq/pull/13) | `dependabot[bot]` | 2022-12-08 | no | Bump certifi from 2020.6.20 to 2022.12.7 |
| [stackstorm-msexchange#16](https://github.com/StackStorm-Exchange/stackstorm-msexchange/pull/16) | `tonybaloney` | 2023-08-08 | no | Update pack exchangelib and create some tests. |
| [stackstorm-nagios#8](https://github.com/StackStorm-Exchange/stackstorm-nagios/pull/8) | `KOezcanAtWork` | 2023-06-15 | no | Patch 1 |
| [stackstorm-napalm_logs#5](https://github.com/StackStorm-Exchange/stackstorm-napalm_logs/pull/5) | `blag` | 2022-05-12 | no | Require python 2 and 3 to deploy |
| [stackstorm-netbox#41](https://github.com/StackStorm-Exchange/stackstorm-netbox/pull/41) | `lucasfontini` | 2023-10-05 | no | Update patch.ipam.ip_addresses.yaml |
| [stackstorm-netbox#57](https://github.com/StackStorm-Exchange/stackstorm-netbox/pull/57) | `johanek` | 2026-03-04 | no | Fix GET detail route when id is array (single vs multi-id) |
| [stackstorm-networking_utils#8](https://github.com/StackStorm-Exchange/stackstorm-networking_utils/pull/8) | `lakshmi-kannan` | 2023-02-14 | no | WIP: Add a tcpdump pcap write action |
| [stackstorm-openstack#41](https://github.com/StackStorm-Exchange/stackstorm-openstack/pull/41) | `gwaewion` | 2025-03-31 | no | server.reboot's 'hard' and 'soft' parameters were redefined as booleans |
| [stackstorm-openstack#42](https://github.com/StackStorm-Exchange/stackstorm-openstack/pull/42) | `gwaewion` | 2025-03-31 | no | port.set doesn't work without munch |
| [stackstorm-opsgenie#17](https://github.com/StackStorm-Exchange/stackstorm-opsgenie/pull/17) | `cognifloyd` | 2022-05-11 | no | Reformat API list for Github |
| [stackstorm-orion#24](https://github.com/StackStorm-Exchange/stackstorm-orion/pull/24) | `jschoewe` | 2023-06-09 | no | feature/sensor-to-check-if-api-is-down |
| [stackstorm-orion#27](https://github.com/StackStorm-Exchange/stackstorm-orion/pull/27) | `jamesdreid` | 2024-01-25 | no | Enhanced SNMPv3 Add Node and Added custom poller action |
| [stackstorm-phantomjs#7](https://github.com/StackStorm-Exchange/stackstorm-phantomjs/pull/7) | `jschoewe` | 2025-02-19 | no | hotfix/fix-ci-errors |
| [stackstorm-qualys#6](https://github.com/StackStorm-Exchange/stackstorm-qualys/pull/6) | `jschoewe` | 2025-02-21 | no | hotfix/fix-ci-errors |
| [stackstorm-rabbitmq#22](https://github.com/StackStorm-Exchange/stackstorm-rabbitmq/pull/22) | `ip-sf` | 2023-02-08 | no | feat: contribution of new py-amqp/asyncio based sensor, bump to v1.2.0 |
| [stackstorm-rabbitmq#24](https://github.com/StackStorm-Exchange/stackstorm-rabbitmq/pull/24) | `0xliam` | 2024-01-24 | no | add virtual host connection params into RabbitMQQueueSensor |
| [stackstorm-servicenow#16](https://github.com/StackStorm-Exchange/stackstorm-servicenow/pull/16) | `TimothyDJones` | 2022-10-19 | no | ServiceNow Pack Update |
| [stackstorm-slack#72](https://github.com/StackStorm-Exchange/stackstorm-slack/pull/72) | `amanda11` | 2022-05-12 | no | [WIP] Update lxml and slackclient to versions that supports python 3.8 |
| [stackstorm-slack#81](https://github.com/StackStorm-Exchange/stackstorm-slack/pull/81) | `bertyah` | 2023-04-19 | no | update users_filter_by to use pagination |
| [stackstorm-slack#86](https://github.com/StackStorm-Exchange/stackstorm-slack/pull/86) | `dependabot[bot]` | 2026-04-21 | no | Bump lxml from 4.6.5 to 6.1.0 |
| [stackstorm-sql#30](https://github.com/StackStorm-Exchange/stackstorm-sql/pull/30) | `ankitaOrch` | 2024-01-08 | no | Modification in the descriptions and actions along with tests. |
| [stackstorm-st2#24](https://github.com/StackStorm-Exchange/stackstorm-st2/pull/24) | `cognifloyd` | 2022-05-11 | no | Feature: Add KV "entry" actions |
| [stackstorm-telegram#10](https://github.com/StackStorm-Exchange/stackstorm-telegram/pull/10) | `sakharovmaksim` | 2022-05-11 | no | feat: add support for html parse mode |
| [stackstorm-telegram#11](https://github.com/StackStorm-Exchange/stackstorm-telegram/pull/11) | `dependabot[bot]` | 2021-06-01 | no | Bump urllib3 from 1.24.2 to 1.26.5 |
| [stackstorm-telegram#13](https://github.com/StackStorm-Exchange/stackstorm-telegram/pull/13) | `dependabot[bot]` | 2022-12-07 | no | Bump certifi from 2017.1.23 to 2022.12.7 |
| [stackstorm-terraform#46](https://github.com/StackStorm-Exchange/stackstorm-terraform/pull/46) | `apielasa` | 2023-04-03 | no | Added env_variable_dict parameter |
| [stackstorm-tesla#6](https://github.com/StackStorm-Exchange/stackstorm-tesla/pull/6) | `jschoewe` | 2025-02-21 | no | hotfix/fix-ci-errors |
| [stackstorm-trello#11](https://github.com/StackStorm-Exchange/stackstorm-trello/pull/11) | `martezr` | 2022-05-11 | no | Add additional actions |
| [stackstorm-vadc#11](https://github.com/StackStorm-Exchange/stackstorm-vadc/pull/11) | `jschoewe` | 2025-02-21 | no | hotfix/fix-ci-errors |
| [stackstorm-vault#28](https://github.com/StackStorm-Exchange/stackstorm-vault/pull/28) | `JD-ISWT` | 2026-05-19 | no | Support of wrap/unwrap actions |
| [stackstorm-vault#29](https://github.com/StackStorm-Exchange/stackstorm-vault/pull/29) | `nzlosh` | 2026-09-28 | no | Debug ci |
| [stackstorm-vra7#7](https://github.com/StackStorm-Exchange/stackstorm-vra7/pull/7) | `blag` | 2022-05-12 | no | Block deployment until both Python 2 and 3 tests pass |
| [stackstorm-vsphere#37](https://github.com/StackStorm-Exchange/stackstorm-vsphere/pull/37) | `jeking3` | 2022-05-11 | no | get_properties: a property collector action |
| [stackstorm-zabbix#60](https://github.com/StackStorm-Exchange/stackstorm-zabbix/pull/60) | `masa-orca` | 2024-01-25 | no | Add webhook mediatype for Zabbix 6.0 or higher |
| [stackstorm-zabbix#61](https://github.com/StackStorm-Exchange/stackstorm-zabbix/pull/61) | `cayohollanda` | 2024-04-01 | no | Added the name of the MediaType and removed deprecated fields |
| [stackstorm-zabbix#64](https://github.com/StackStorm-Exchange/stackstorm-zabbix/pull/64) | `namachieli` | 2026-10-09 | no | v0.2.1 - Fix missing basic connection params for SSL Verify, timeout, etc |
| [stackstorm-zendesk#6](https://github.com/StackStorm-Exchange/stackstorm-zendesk/pull/6) | `alexatx15` | 2023-02-09 | no | Making alterations to create_ticket to allow for tags and specific ti… |

All 74 open upstream PRs are listed in `reports/upstream_prs.tsv`.
To bring one over, run the **Recreate upstream PR** workflow with the repo name and PR number.
