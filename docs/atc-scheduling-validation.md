# ATC scheduling validation for #101 and #104

Target: S/4HANA 2025 on-premise/private cloud. Apply PR #121 to the `ZKNSF_RUN_ATC` function module in function group `ZKNSF_FG_BTP_WRAPPER`, and PR #115 to the `RUNATC` implementation of behavior pool `ZKNSF_CL_BP_PROJECTS`. Activate both changes and check for activation errors before runtime testing. The PRs change reporting; they do not change BOPF activation, transaction/save behavior or ATC configuration.

## Main tests

Use a test system and the existing Kernseife project. Record the system alias, timestamp/timezone, installed Kernseife commit, and the project state before each call. In the Settings application, select the intended system and use **Trigger ATC Run** once per test.

| Test | What to do | Expected result |
| --- | --- | --- |
| Existing disabled action (#104) | Reproduce the current failure without changing its project/configuration. | `E_ERROR = ABAP_TRUE`. `E_MESSAGE` includes available BOPF messages, such as `/BOBF/FRW_COMMON` 094. If BOPF returns failed keys without message text, the fallback is `ATC scheduling action failed`. The caller reports `Failed: ...` with error severity; the UI must not display scheduling success. Verify that no new run was scheduled. |
| Successful scheduling (#101) | In a project/system where scheduling is enabled, trigger a run and inspect its actual ATC monitoring state. | No failed keys and no BOPF error messages. `E_ERROR` is initial. The caller reports `Success: Started ATC Run` with success severity. Independently confirm a new run was scheduled/started. A success notification alone does not establish that ATC has completed successfully. |
| Error cleared on the next call | After a failed call, make a call in a valid scheduling state through the same frontend session. If no valid state is available, report this test as unavailable. | The successful call does not retain the previous error/text. Its scheduled run can be verified independently. |

If the action is disabled in every available project, the disabled-action test can still validate #121. Mark the success tests as unavailable; do not change configuration merely to produce a passing result.

## What to capture at the ABAP boundary

Set external breakpoints for the backend execution user in `ZKNSF_RUN_ATC`, immediately after `service_manager->do_action` and before the function returns. The behavior calls the function asynchronously with `STARTING NEW TASK ... DESTINATION 'NONE'`, so a breakpoint confined to the original dialog session may not stop in the task. Use your system's supported asynchronous-RFC debugging setup. If debugging is unavailable, provide the returned error text and service/log evidence instead.

Capture:

- Whether `project_id` was found. Identify the project with a consistent alias if its identifier is sensitive.
- `lines( failed_keys )` and whether the requested project key is in that list.
- Whether `messages` is bound, whether it contains errors (`messages->check( )`), and `has_errors`.
- Every BOPF message's class/ID, number, severity, full text and substitutions where visible. Capture all messages, including warnings preceding an error. On the error path, `message_table` is populated by `messages->get`.
- Final `E_ERROR` and `E_MESSAGE`. If the exception branch is reached, capture the exception class and text.

In `ZKNSF_CL_BP_PROJECTS`, also verify that `RUN_ATC_FINISH` receives those values and that `RUNATC` selects the matching failure/success branch. For the combined PRs, success uses `severity-success` and failure uses `severity-error`.

## What to capture at the service/UI boundary

The current connector reads the project from:

```text
GET /sap/opu/odata4/sap/zknsf_btp_connector/srvd/sap/zknsf_btp_connector/0001/ZKNSF_I_PROJECTS
```

It schedules ATC through:

```text
POST /sap/opu/odata4/sap/zknsf_btp_connector/srvd/sap/zknsf_btp_connector/0001/ZKNSF_I_PROJECTS/com.sap.gateway.srvd.zknsf_btp_connector.v0001.RunATC
```

Use the normal UI flow; direct calls are optional if you already have approved service tooling. Record before/after project fields: `status`, `statusDescription`, `runId`, `runSeries`, `runState`, `runStateText`, `startedOn`, `total`, `failed` and `processed`, as returned by the service. `ZKNSF_I_PROJECTS` selects CHECKV projects with check variant `ZKNSF_SCORING`; record whether that variant exists and is the one used by the project.

Capture the RunATC response status, response body and `sap-messages` header where available. An ABAP action can return an HTTP success status with an error message in this header: assess message severity as well as HTTP status. CAP currently converts numeric severity 4 into a rejected request and severity 2 into a success notification. In a frontend `$batch` response, record the inner action's status/message, not just the outer batch status.

Provide the displayed UI message and relevant server log excerpt, with timestamp/correlation ID if available. Omit Authorization headers, cookies, passwords and tokens.

## Additional cases, if available in the test landscape

| Case | Expected result |
| --- | --- |
| No matching Kernseife project | `E_ERROR = ABAP_TRUE`, `E_MESSAGE = Failed: No Project Exists`. Use an existing empty test setup; do not delete a project for this test. |
| Failed keys with no message container/text | Error flag and fallback scheduling-failure text. |
| Error message without failed keys | Error flag and BOPF text. |
| Warning-only messages with successful scheduling | No false failure; verify that a run was actually scheduled. |
| Unexpected exception | Error flag and actual exception text. |

These cases are additional coverage, not a request to force a dump or corrupt project state. If exercising them requires fault injection, agree that separately in the test system.

## Minimum result to send back

```text
Kernseife commits / PRs activated:
ABAP activation errors, if any:
System release and installed ATC-related SAP Note versions (including 3565942 if applicable):
Project alias, check variant, before/after status:
Test performed: disabled action / success / success after failure
Timestamp + timezone:
Failed-key count:
BOPF messages (class, number, severity, text):
E_ERROR / E_MESSAGE:
Service status + sap-messages (sanitized):
UI message:
New ATC run actually scheduled? Evidence:
```

Passing the disabled-action reporting test resolves the misleading success response, but not the reason BOPF disables RUN_ATC or marks the project corrupt. The captured project state, messages and ATC configuration are the next evidence needed for that investigation.
