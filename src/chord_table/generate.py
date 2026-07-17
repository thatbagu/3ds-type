#!/usr/bin/env python3
"""Generate chord_table.h and ChordTable.kt from chord_entries.json.

Usage: generate.py [output_dir]
  output_dir: directory to write output files (defaults to script directory)
"""
import json
import os
import sys

script_dir = os.path.dirname(os.path.abspath(__file__))
out_dir = sys.argv[1] if len(sys.argv) > 1 else script_dir

with open(os.path.join(script_dir, "chord_entries.json")) as f:
    entries = json.load(f)

size = len(entries)

# Generate chord_table.h
header_lines = [
    "#pragma once",
    "#include <cstdint>",
    "#include <cstddef>",
    "struct ChordEntry { uint8_t ascii; uint16_t bitmask; };",
    "static const ChordEntry CHORD_TABLE[] = {",
]
table_entries = []
for e in entries:
    table_entries.append(f"    {{{e['char']}, {e['bitmask']}}}")
header_lines.append(",\n".join(table_entries))
header_lines.append("};")
header_lines.append(f"static const size_t CHORD_TABLE_SIZE = {size};")

with open(os.path.join(out_dir, "chord_table.h"), "w") as f:
    f.write("\n".join(header_lines) + "\n")

# Generate ChordTable.kt
kt_lines = [
    "object ChordTable {",
    "    val asciiToBitmask: Map<Int, Int> = mapOf(",
]
kt_entries = []
for e in entries:
    kt_entries.append(f"        {e['char']} to {e['bitmask']}")
kt_lines.append(",\n".join(kt_entries))
kt_lines.append("    )")
kt_lines.append("    val bitmaskToAscii: Map<Int, Int> = asciiToBitmask.entries.associate { (k, v) -> v to k }")
kt_lines.append("}")

with open(os.path.join(out_dir, "ChordTable.kt"), "w") as f:
    f.write("\n".join(kt_lines) + "\n")

print(f"Generated chord_table.h and ChordTable.kt with {size} entries.")
