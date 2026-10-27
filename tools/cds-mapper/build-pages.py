#!/usr/bin/env python3
"""Prepare the existing CDS Mapper report for static GitHub Pages hosting."""

import argparse
import shutil
from pathlib import Path
from zipfile import ZipFile


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

    (output / "index.html").write_text(
        '<!doctype html><html lang="en"><meta charset="utf-8">'
        '<meta http-equiv="refresh" content="0; url=cds-mapper/">'
        '<title>Project Kernseife — CDS Mapper</title>'
        '<a href="cds-mapper/">Open the CDS Mapper full-scan report</a></html>\n',
        encoding="utf-8",
    )
    print(f"Prepared CDS Mapper report with 256 data shards in {report}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=Path("_site"))
    build(parser.parse_args().output)
