#!/usr/bin/env python3
"""Prepare the existing CDS Mapper report for static GitHub Pages hosting."""

import argparse
import json
import re
import shutil
from pathlib import Path
from zipfile import ZipFile

INDEX_BLOCK = re.compile(r'<script id="data" type="application/json">(.*?)</script>', re.S)
RUN_LINE = re.compile(r'<div class="run">Data compiled: (.*?)<br>Source: (.*?)</div>')
DETAIL_PREFIX = "window.__CDSM_DETAIL__("
DETAIL_SUFFIX = ");"
# Report UI state, not data: the search string, the lazy-load flag and the shard number.
UI_ONLY_FIELDS = ("search", "loaded", "shard")
DISCLAIMER = (
    "An accelerator, not an SAP decision. A candidate is structural evidence only; validate scope, "
    "semantics, authorizations, transactional behavior and performance before using it."
)


LLMS_TXT = """# SAP Table to CDS Mapper

> For DB tables in {source}, the CDS views that expose their fields, traced field by field,
> with C1-release and official-successor evidence. Data compiled {compiled}; the analysis run finished on {run_date}.
> {disclaimer}

The data is plain JSON. Names are uppercase and lookups are case-sensitive. In a file name,
every "/" of an SAP namespace becomes "~": table /1BS/TEST_TABLE is tables/~1BS~TEST_TABLE.json.

## Data

- [Table index]({base}json/index.json): the {table_count} DB tables found in the lineage of the analyzed CDS views, each with its coverage and successor flags, plus run statistics
- Table detail: `{base}json/tables/<TABLE>.json`, for example [DFKKOP]({base}json/tables/DFKKOP.json). Holds the table's `fields`, `mappedFields`, `unmappedFields` and ranked `candidates`, each with its field-to-element `mappings`
- [Table record schema]({base}json/schema/table.schema.json) and [index schema]({base}json/schema/index.schema.json)

## Reading a table record

- The same names mean different things at two levels. On the table, `c1` is a count of C1-released candidates and `mappings` is a count; on a candidate, `c1` is a boolean and `mappings` is the list of field-to-element mappings
- On a candidate, `c1` true means the view is C1-released and listed in the SAP Cloudification Repository baseline. `other_c1` true means the analyzed system reports a C1 release that the baseline does not list, so validate its intended use. To find baseline-released views, filter on `c1`, not on `category`
- `category` is one of OFFICIAL_SUCCESSOR, C1_HIGH_COVERAGE, C1_PARTIAL_COVERAGE or UNRELEASED_CANDIDATE. The two C1_ categories also include `other_c1` views, where `c1` is false
- `state` is the release state: RELEASED, DEPRECATED, NOT_TO_BE_RELEASED, NOT_TO_BE_RELEASED_STABLE, or empty when none is recorded. Skip DEPRECATED candidates for new code
- On a candidate, `official` true means the repository metadata names it as the table's successor. An official successor is usually, but not always, C1-released: check `c1` and `state`
- On the table, `official` is true when a candidate is official. `has_official_successor` is true when the repository names a successor at all; in some tables (CDHDR and CDPOS among them) it is true while no candidate is official, so the successor's name is not in this data
- Candidates are listed official first, then `c1`, then by coverage, highest first. `other_c1` is not a ranking tier
- `mappings[].contract` is the release contract reported for that element (C0, C1, C2, or empty); see SAP's documentation on release contracts for what each means
- `unmappedFields` lists the table fields that no candidate maps directly
- Absence is not evidence. A table missing from the index, or a missing candidate, does not show that no successor exists: the run reports {run[failed]} failed analyses out of {run[total]}
- Run timestamps (`meta.run.created`, `meta.run.finished`) use SAP's YYYYMMDDhhmmss.sss format

## Optional

- [Interactive report]({report_link})
- [Source repository](https://github.com/SAP/project-kernseife), licensed {license}
"""


def file_name(name: str) -> str:
    """Map an SAP object name to a URL-safe file name: /1BS/TABLE becomes ~1BS~TABLE.json."""
    return f"{name.replace('/', '~')}.json"


def write_json(path: Path, value: object) -> None:
    # Sorted keys and no whitespace keep the output byte-stable, so snapshots can be diffed.
    path.write_text(
        json.dumps(value, ensure_ascii=False, sort_keys=True, separators=(",", ":")),
        encoding="utf-8",
    )


def export_json(source: ZipFile, report_name: str, data_directory: str, report: Path) -> int:
    """Write the report data as plain JSON: an index plus one file per DB table."""
    html = source.read(report_name).decode("utf-8")
    index_match, run_match = INDEX_BLOCK.search(html), RUN_LINE.search(html)
    if not index_match or not run_match:
        raise ValueError("Report HTML must carry its table index and its source release")
    index = json.loads(index_match.group(1))
    meta = {
        "source": run_match.group(2),
        "compiled": run_match.group(1),
        "run": index["run"],
        "license": "Apache-2.0",
        "disclaimer": DISCLAIMER,
    }
    rows = {row["name"]: {k: v for k, v in row.items() if k not in UI_ONLY_FIELDS} for row in index["tables"]}

    exported = report / "json"
    (exported / "tables").mkdir(parents=True)
    shutil.copytree(Path(__file__).with_name("schema"), exported / "schema")
    write_json(exported / "index.json", {"meta": meta, "stats": index["stats"], "tables": list(rows.values())})

    written = set()
    for shard in range(256):
        text = source.read(f"{data_directory}/{shard:02x}.js").decode("utf-8").strip()
        if not (text.startswith(DETAIL_PREFIX) and text.endswith(DETAIL_SUFFIX)):
            raise ValueError(f"Data shard {shard:02x} does not use the expected detail wrapper")
        details = json.loads(text[len(DETAIL_PREFIX):-len(DETAIL_SUFFIX)])
        for name, detail in details.items():
            if name not in rows:
                raise ValueError(f"Data shard {shard:02x} holds {name}, which the table index does not list")
            record = {**rows[name], **{k: v for k, v in detail.items() if k not in UI_ONLY_FIELDS}}
            mapped = set(record["mappedFields"])
            record["unmappedFields"] = [f["name"] for f in record["fields"] if f["name"] not in mapped]
            record["meta"] = meta
            write_json(exported / "tables" / file_name(name), record)
            written.add(name)

    if written != set(rows):
        raise ValueError("Every DB table in the index must have exactly one detail record")
    finished = meta["run"]["finished"]
    facts = {**meta, "table_count": len(rows), "run_date": f"{finished[:4]}-{finished[4:6]}-{finished[6:8]}"}
    # The same guide at the site root and beside the report, with links relative to each.
    (report.parent / "llms.txt").write_text(LLMS_TXT.format(base="cds-mapper/", report_link="cds-mapper/", **facts), encoding="utf-8")
    (report / "llms.txt").write_text(LLMS_TXT.format(base="", report_link="./", **facts), encoding="utf-8")
    return len(written)


def build(output: Path) -> None:
    archive = Path(__file__).with_name("table-cds-mapper-analysis.zip")
    report_name = "table-to-cds-mapper.html"
    data_directory = "table-to-cds-mapper-data"
    expected = {report_name} | {
        f"{data_directory}/{shard:02x}.js" for shard in range(256)
    }

    with ZipFile(archive) as source:
        names = source.namelist()
        if len(names) != len(expected) or set(names) != expected:
            raise ValueError("Report archive must contain its HTML and all 256 data shards")
        output.mkdir(parents=True, exist_ok=False)
        report = output / "cds-mapper"
        report.mkdir()
        for name in names:
            destination = report / ("index.html" if name == report_name else name)
            destination.parent.mkdir(parents=True, exist_ok=True)
            with source.open(name) as original, destination.open("wb") as published:
                shutil.copyfileobj(original, published)
        table_count = export_json(source, report_name, data_directory, report)

    (output / "index.html").write_text(
        '<!doctype html><html lang="en"><meta charset="utf-8">'
        '<meta http-equiv="refresh" content="0; url=cds-mapper/">'
        '<title>Project Kernseife — CDS Mapper</title>'
        '<a href="cds-mapper/">Open the CDS Mapper full-scan report</a></html>\n',
        encoding="utf-8",
    )
    print(f"Prepared CDS Mapper report with 256 data shards and {table_count} JSON table files in {report}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=Path("_site"))
    build(parser.parse_args().output)
