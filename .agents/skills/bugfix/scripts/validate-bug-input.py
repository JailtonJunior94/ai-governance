#!/usr/bin/env python3
import argparse
import json
import sys


REQUIRED_FIELDS = [
    "id",
    "severity",
    "file",
    "line",
    "reproduction",
    "expected",
    "actual",
]
ALLOWED_SEVERITIES = {"critical", "major", "minor"}


def validate_bug(bug, index):
    if not isinstance(bug, dict):
        raise ValueError(f"bug[{index}] deve ser um objeto JSON")

    missing = [field for field in REQUIRED_FIELDS if field not in bug]
    if missing:
        raise ValueError(f"bug[{index}] faltando campos obrigatorios: {', '.join(missing)}")

    severity = bug["severity"]
    if severity not in ALLOWED_SEVERITIES:
        raise ValueError(
            f"bug[{index}].severity invalido: {severity}. Use apenas critical, major ou minor"
        )

    line = bug["line"]
    if not isinstance(line, int) or line <= 0:
        raise ValueError(f"bug[{index}].line deve ser inteiro positivo")

    for field in REQUIRED_FIELDS:
        if field == "line":
            continue
        value = bug[field]
        if not isinstance(value, str) or not value.strip():
            raise ValueError(f"bug[{index}].{field} deve ser string nao vazia")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", required=True, help="caminho para arquivo JSON contendo uma lista de bugs")
    args = parser.parse_args()

    with open(args.input, "r", encoding="utf-8") as handle:
        payload = json.load(handle)

    if not isinstance(payload, list) or not payload:
        raise ValueError("o arquivo deve conter uma lista JSON nao vazia de bugs")

    for index, bug in enumerate(payload):
        validate_bug(bug, index)

    print(f"SUCCESS: {len(payload)} bugs validados no formato canonico.")


if __name__ == "__main__":
    try:
        main()
    except Exception as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        sys.exit(1)
