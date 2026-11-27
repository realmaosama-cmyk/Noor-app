#!/usr/bin/env python3
"""Attach the NOOR in-app Arabic keyboard to the child-name field."""
from __future__ import annotations
import re
import sys
from pathlib import Path
import os

root = Path(sys.argv[1]).resolve()
widget = root / "lib/core/widgets/noor_arabic_keyboard.dart"
if not widget.is_file():
    raise SystemExit("Arabic keyboard widget was not copied into the Flutter project")


def matching(text: str, start: int, opening: str, closing: str) -> int:
    depth = 0
    quote = None
    triple = False
    escaped = False
    line_comment = False
    block_comment = False
    i = start
    while i < len(text):
        ch = text[i]
        nxt = text[i + 1] if i + 1 < len(text) else ""
        if line_comment:
            if ch == "\n":
                line_comment = False
            i += 1
            continue
        if block_comment:
            if ch == "*" and nxt == "/":
                block_comment = False
                i += 2
            else:
                i += 1
            continue
        if quote:
            if escaped:
                escaped = False
            elif ch == "\\":
                escaped = True
            elif triple and text.startswith(quote * 3, i):
                quote = None
                triple = False
                i += 3
                continue
            elif not triple and ch == quote:
                quote = None
            i += 1
            continue
        if ch == "/" and nxt == "/":
            line_comment = True
            i += 2
            continue
        if ch == "/" and nxt == "*":
            block_comment = True
            i += 2
            continue
        if ch in ("'", '"'):
            if text.startswith(ch * 3, i):
                quote = ch
                triple = True
                i += 3
                continue
            quote = ch
            i += 1
            continue
        if ch == opening:
            depth += 1
        elif ch == closing:
            depth -= 1
            if depth == 0:
                return i
        i += 1
    raise ValueError("Unbalanced Dart source while locating widget")


def add_import(source: str, import_line: str) -> str:
    if import_line in source:
        return source
    library = re.search(r"(?m)^library\s+[^;]+;\s*", source)
    if library:
        at = library.end()
        return source[:at] + import_line + "\n" + source[at:]
    imports = list(re.finditer(r"(?m)^import\s+[^;]+;\s*\n?", source))
    if imports:
        at = imports[-1].end()
        return source[:at] + import_line + "\n" + source[at:]
    return import_line + "\n" + source


def add_autoshow(source: str, controller: str) -> tuple[str, bool]:
    # Locate the State class that owns the name controller.
    state_match = None
    state_open = -1
    state_close = -1
    for match in re.finditer(r"class\s+\w+\s+extends\s+(?:ConsumerState|State)<[^>]+>\s*\{", source):
        opening = source.find("{", match.start())
        closing = matching(source, opening, "{", "}")
        body = source[opening + 1:closing]
        if re.search(r"\b" + re.escape(controller) + r"\b", body):
            state_match, state_open, state_close = match, opening, closing
            break
    if state_match is None:
        return source, False
    state_body = source[state_open + 1:state_close]
    if "_noorNameKeyboardAutoOpened" in state_body:
        return source, True
    callback = (
        "\n  bool _noorNameKeyboardAutoOpened = false;\n"
        "  void _openNoorNameKeyboard() {\n"
        "    if (!mounted || _noorNameKeyboardAutoOpened) return;\n"
        "    _noorNameKeyboardAutoOpened = true;\n"
        "    showModalBottomSheet<void>(\n"
        "      context: context,\n"
        "      isScrollControlled: true,\n"
        "      useSafeArea: true,\n"
        "      backgroundColor: Colors.transparent,\n"
        f"      builder: (_) => NoorArabicKeyboard(controller: {controller}),\n"
        "    );\n"
        "  }\n"
    )
    source = source[:state_close] + callback + source[state_close:]
    # Recompute the State class range after inserting the helper.
    match = re.search(r"class\s+\w+\s+extends\s+(?:ConsumerState|State)<[^>]+>\s*\{", source)
    opening = source.find("{", match.start())
    closing = matching(source, opening, "{", "}")
    body = source[opening + 1:closing]
    init_match = re.search(r"@override\s+void\s+initState\s*\(\s*\)\s*\{", body)
    if init_match:
        init_open = opening + 1 + body.find("{", init_match.start())
        init_close = matching(source, init_open, "{", "}")
        super_call = re.search(r"super\.initState\s*\(\s*\)\s*;", source[init_open:init_close])
        if super_call:
            insert_at = init_open + super_call.end()
            auto = (
                "\n    WidgetsBinding.instance.addPostFrameCallback((_) {\n"
                "      if (!mounted) return;\n"
                "      _openNoorNameKeyboard();\n"
                "    });"
            )
            source = source[:insert_at] + auto + source[insert_at:]
            return source, True
    build_match = re.search(r"@override\s+Widget\s+build\s*\(", body)
    if not build_match:
        return source, False
    insert_at = opening + 1 + build_match.start()
    init = (
        "  @override\n"
        "  void initState() {\n"
        "    super.initState();\n"
        "    WidgetsBinding.instance.addPostFrameCallback((_) {\n"
        "      if (!mounted) return;\n"
        "      _openNoorNameKeyboard();\n"
        "    });\n"
        "  }\n\n"
    )
    source = source[:insert_at] + init + source[insert_at:]
    return source, True


candidates = []
for path in sorted((root / "lib").rglob("*.dart")):
    source = path.read_text(encoding="utf-8")
    for widget_match in re.finditer(r"\b(TextFormField|TextField)\s*\(", source):
        opening = source.find("(", widget_match.start())
        try:
            closing = matching(source, opening, "(", ")")
        except ValueError:
            continue
        block = source[widget_match.start():closing + 1]
        controller_match = re.search(r"\bcontroller\s*:\s*([A-Za-z_$][\w$]*)", block)
        if not controller_match:
            continue
        controller = controller_match.group(1)
        markers = " ".join((controller, block, source[max(0, widget_match.start()-700):widget_match.start()]))
        if not re.search(r"name|child|learner|اسم|المتعلم|الطفل", markers, re.IGNORECASE):
            continue
        candidates.append((path, source, widget_match.start(), closing, opening, controller, block))

if not candidates:
    raise SystemExit("Could not identify the child-name TextField in the extracted source archive")

# Prefer an explicit name controller or an Arabic child-name label.
candidates.sort(key=lambda item: (
    0 if re.search(r"name|child|learner", item[5], re.IGNORECASE) else 1,
    0 if re.search(r"اسم الطفل|اسم المتعلم|اسم", item[6]) else 1,
))
path, source, start, closing, opening, controller, block = candidates[0]
relative_widget = os.path.relpath(widget, path.parent).replace(os.sep, "/")
if not relative_widget.startswith("."):
    relative_widget = "./" + relative_widget
source = add_import(source, f"import '{relative_widget}';")

# Re-find the chosen field after import insertion.
field_match = None
for match in re.finditer(r"\b(TextFormField|TextField)\s*\(", source):
    op = source.find("(", match.start())
    end = matching(source, op, "(", ")")
    field_block = source[match.start():end + 1]
    cm = re.search(r"\bcontroller\s*:\s*" + re.escape(controller) + r"\b", field_block)
    if cm:
        field_match = (match.start(), op, end, field_block)
        break
if field_match is None:
    raise SystemExit("Child-name field changed unexpectedly during keyboard integration")
start, opening, closing, block = field_match
if re.search(r"\bonTap\s*:", block):
    raise SystemExit("Child-name field already has an onTap handler; manual-safe merge required")

# Prevent the Android system keyboard from covering the form; use the in-app keyboard.
insert_at = opening + 1
properties = (
    "\n      readOnly: true,"
    "\n      keyboardType: TextInputType.none,"
    "\n      autofocus: true,"
    "\n      onTap: _openNoorNameKeyboard,"
)
source = source[:insert_at] + properties + source[insert_at:]

# Add an explicit keyboard affordance to the field decoration.
field_start = start
field_end = matching(source, opening, "(", ")")
field_block = source[field_start:field_end + 1]
decoration = re.search(r"\bdecoration\s*:\s*InputDecoration\s*\(", field_block)
if decoration:
    dec_open = field_start + decoration.end() - 1
    dec_close = matching(source, dec_open, "(", ")")
    dec_body = source[dec_open + 1:dec_close]
    if "suffixIcon:" not in dec_body:
        suffix = (
            "\n        suffixIcon: IconButton("
            "\n          tooltip: 'لوحة المفاتيح العربية',"
            "\n          onPressed: _openNoorNameKeyboard,"
            "\n          icon: const Icon(Icons.keyboard_alt_rounded),"
            "\n        ),"
        )
        source = source[:dec_close] + suffix + source[dec_close:]

source, auto = add_autoshow(source, controller)
if not auto:
    raise SystemExit("Name field found, but automatic keyboard opening could not be attached to its State class")
path.write_text(source, encoding="utf-8")
print(f"Integrated Arabic in-app keyboard into {path.relative_to(root)} using {controller}; auto-opens on profile creation.")
