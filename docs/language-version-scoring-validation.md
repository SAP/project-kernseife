# Language-version scoring validation (#91)

Confirmed target: S/4HANA 2025 on-premise/private cloud. With no scored API findings, language version 5 (ABAP Cloud) must appear as Level A with score 0, and version 2 (key user) and standard-language X as Level B with score 0. All three cases were confirmed by the maintainer.

The ABAP proposal drives `ZKNSF_I_DEV_OBJECTS_SCORE` from language findings with a left join to `ZKNSF_I_SCORING`. Null aggregates default to score 0 and an API level of A; only language version 5 retains actual Level A. Scored API findings retain their sum and worst level, with the existing A-to-B adjustment for non-Cloud language versions. CAP's CSV and connector imports remove the special case that previously allowed key-user objects to retain actual Level A. Potential-level conversion rules are unchanged.

## ABAP activation and data-preview checks

1. Activate the changed DDLS `ZKNSF_I_DEV_OBJECTS_SCORE` and record any activation error. SAP-generated metadata can be refreshed by activation; no ABAP compiler/runtime was available during preparation.
2. Choose one run containing a language-version 5 object and one containing a version 2 object, each with no scored API findings. In `ZKNSF_I_ATC_FINDINGS`, confirm the language finding exists and record displayId, objectType, objectName, devClass and messageId. In `ZKNSF_I_SCORING`, confirm there are zero corresponding scored rows for that run/type/name.
3. Preview `ZKNSF_I_DEV_OBJECTS_SCORE`, filtered to those same keys. Verify that each object is present with a non-null score/level and the expected result below.
4. Check objects with scored API findings to ensure their sums and worst levels remain correct. Compare against the underlying rows in `ZKNSF_I_SCORING`.

| Language finding | Scored API findings | Expected result |
| --- | --- | --- |
| 5 | None | A, score 0 |
| 2 | None | B, score 0 |
| X | None | B, score 0 |
| 5 | Worst API level A | A, sum of the underlying scores |
| 2 | Worst API level A | B, sum of the underlying scores |
| 5 or 2 | Worst API level B/C/D | That worst level, sum of the underlying scores |
| X | Existing scored rows | Existing A-to-B adjustment and sum/worst-level behavior |

If a run/object has multiple conflicting language findings, capture their complete keys instead of selecting one arbitrarily; that is the separate identity/language investigation in #100. This change does not alter that identity rule or the existing scoring join keys.

## CAP validation

Two automated integration tests deploy the real CDS schema into SQLite and import language-only objects through the actual CSV and connector import functions. Both verify 5 → A/0, 2 → B/0, and the existing CAP rule X → B/0, without creating any scored findings. The CSV fixture omits optional runId.

In the test BTP landscape, import the corresponding system/CSV after activating the ABAP proposal. Compare object languageVersion_code, level and score in DevelopmentObjects with the expected results above. Existing CAP rows retain their stored classification until reimported; this proposal does not bulk-reclassify historical data.

## Result to send back

```text
Commit / PR activated:
S/4 release and activation result:
Run/object alias and complete language-finding keys:
Language version:
Underlying scored row count, scores and levels:
ABAP scoring-view row count, score and level:
CSV or connector import result:
CAP object language version, score and level:
Duplicate/conflicting language findings, if any:
```
