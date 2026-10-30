#!/usr/bin/env python3
"""Check the CDS Mapper JSON export in a built site against its schemas and the report's own counts."""

import argparse
import json
from pathlib import Path

TYPES = {
    "object": dict,
    "array": list,
    "string": str,
    "integer": int,
    "number": (int, float),
    "boolean": bool,
    "null": type(None),
}


class Validator:
    """The subset of JSON Schema the export's schemas use: type, enum, required, properties,
    additionalProperties false, items, anyOf and $ref. Standard library only, so the Pages
    workflow needs no extra packages."""

    def __init__(self, schema_directory: Path):
        self.schemas = {path.name: json.loads(path.read_text(encoding="utf-8")) for path in schema_directory.glob("*.json")}

    def resolve(self, reference: str, document: str) -> tuple:
        name, _, pointer = reference.partition("#")
        name = name or document
        node = self.schemas[name]
        for part in filter(None, pointer.split("/")):
            node = node[part]
        return node, name

    def errors(self, value, schema: dict, document: str, path: str = "$"):
        if "$ref" in schema:
            target, document = self.resolve(schema["$ref"], document)
            yield from self.errors(value, target, document, path)
            return
        if "anyOf" in schema:
            if all(any(True for _ in self.errors(value, option, document, path)) for option in schema["anyOf"]):
                yield f"{path}: matches none of the allowed shapes"
            return
        if "enum" in schema and value not in schema["enum"]:
            yield f"{path}: {value!r} is not one of {schema['enum']}"
        expected = schema.get("type")
        # bool is a subclass of int in Python, so it never counts as an integer or number here.
        if expected and (not isinstance(value, TYPES[expected]) or (expected in ("integer", "number") and isinstance(value, bool))):
            yield f"{path}: expected {expected}, found {type(value).__name__}"
            return
        if isinstance(value, dict):
            for key in schema.get("required", []):
                if key not in value:
                    yield f"{path}: missing {key}"
            properties = schema.get("properties", {})
            for key, item in value.items():
                if key in properties:
                    yield from self.errors(item, properties[key], document, f"{path}.{key}")
                elif schema.get("additionalProperties") is False:
                    yield f"{path}: unexpected {key}"
        if isinstance(value, list) and "items" in schema:
            for position, item in enumerate(value):
                yield from self.errors(item, schema["items"], document, f"{path}[{position}]")


def check(site: Path) -> None:
    exported = site / "cds-mapper" / "json"
    validator = Validator(exported / "schema")
    problems = []

    index = json.loads((exported / "index.json").read_text(encoding="utf-8"))
    problems += [f"index.json {error}" for error in validator.errors(index, validator.schemas["index.schema.json"], "index.schema.json")]
    names = [row["name"] for row in index["tables"]]
    if len(names) != index["stats"]["tables"] or len(set(names)) != len(names):
        problems.append(f"index.json lists {len(names)} tables; stats.tables says {index['stats']['tables']}")

    files = sorted((exported / "tables").glob("*.json"))
    if len(files) != len(names):
        problems.append(f"{len(files)} table files for {len(names)} indexed tables")
    for path in files:
        record = json.loads(path.read_text(encoding="utf-8"))
        problems += [f"{path.name} {error}" for error in validator.errors(record, validator.schemas["table.schema.json"], "table.schema.json")]
        if path.stem.replace("~", "/") != record.get("name"):
            problems.append(f"{path.name} does not round-trip to its table name {record.get('name')!r}")
        fields = [field["name"] for field in record.get("fields", [])]
        if sorted(record.get("mappedFields", []) + record.get("unmappedFields", [])) != sorted(fields):
            problems.append(f"{path.name} mappedFields and unmappedFields do not partition its fields")
        if record.get("meta") != index["meta"]:
            problems.append(f"{path.name} carries a different snapshot stamp from index.json")

    if problems:
        raise SystemExit("\n".join(problems[:50] + [f"{len(problems)} problem(s) found"]))
    print(f"Checked index.json and {len(files)} table files against the schemas")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--site", type=Path, default=Path("_site"))
    check(parser.parse_args().site)
