"""Splits a content JSON file into its data and its words (one-time move, 2026-11-02; kept for new
files written the old way): every string with Hangul (and every object with a Hangul key, whole)
goes to the words file under content/locale/ko/ in the same shape, the rest stays. `about` notes stay
with the data. Locale.overlay (scripts/core/locale.gd) puts them back together.

  cd apps/lab3d && python3 tools/split_text.py content/experiments/spring.json [...]

Only files under content/ (not content/locale) are split.
"""
import json
import os
import re
import sys

HANGUL = re.compile("[\uac00-\ud7a3]")
MISSING = object()
KEEP = ("about",)


def has_hangul(value):
    return isinstance(value, str) and HANGUL.search(value) is not None


def split(value, key=""):
    """(data, words) of `value`; MISSING where a side has nothing."""
    if key in KEEP or key.endswith("_about"):
        return value, MISSING
    if isinstance(value, dict):
        if any(HANGUL.search(k) for k in value):
            return MISSING, value
        data, words = {}, {}
        for k, v in value.items():
            d, w = split(v, k)
            if d is not MISSING:
                data[k] = d
            if w is not MISSING:
                words[k] = w
        return (data if data or not words else MISSING), (words if words else MISSING)
    if isinstance(value, list):
        if value and all(isinstance(x, str) for x in value):
            return (MISSING, value) if any(has_hangul(x) for x in value) else (value, MISSING)
        parts = [split(x) for x in value]
        if not any(w is not MISSING for _, w in parts):
            return value, MISSING
        if all(d is MISSING for d, _ in parts):
            return MISSING, value
        if any(isinstance(x, (str, int, float, bool)) or x is None for x in value):
            raise ValueError("a list mixes words and other values: %r" % value[:3])
        data = [{} if d is MISSING else d for d, _ in parts]
        words = [{} if w is MISSING else w for _, w in parts]
        return data, words
    if has_hangul(value):
        return MISSING, value
    return value, MISSING


def overlay(data, words):
    if words is MISSING or words is None:
        return data
    if data is MISSING or data is None:
        return words
    if isinstance(data, dict) and isinstance(words, dict):
        out = dict(data)
        for k, v in words.items():
            out[k] = overlay(data.get(k, MISSING), v)
        return out
    if isinstance(data, list) and isinstance(words, list):
        n = max(len(data), len(words))
        return [overlay(data[i] if i < len(data) else MISSING, words[i] if i < len(words) else MISSING) for i in range(n)]
    return words


def dump(value, indent=0, width=110):
    """JSON like the hand-written files: short objects and lists of plain values on one line."""
    flat = json.dumps(value, ensure_ascii=False, separators=(", ", ": "))
    if isinstance(value, dict) and flat != "{}":
        flat = "{ " + flat[1:-1] + " }"
    plain = isinstance(value, (dict, list)) and all(not isinstance(v, (dict, list)) for v in (value.values() if isinstance(value, dict) else value))
    if not isinstance(value, (dict, list)) or (plain and indent * 2 + len(flat) <= width and not (isinstance(value, list) and any(isinstance(v, str) and len(v) > 30 for v in value))):
        return flat
    pad = "  " * (indent + 1)
    if isinstance(value, dict):
        items = ["%s%s: %s" % (pad, json.dumps(k, ensure_ascii=False), dump(v, indent + 1, width)) for k, v in value.items()]
        return "{\n" + ",\n".join(items) + "\n" + "  " * indent + "}"
    items = [pad + dump(v, indent + 1, width) for v in value]
    return "[\n" + ",\n".join(items) + "\n" + "  " * indent + "]"


def main(paths):
    content = os.path.realpath("content")
    for path in paths:
        real = os.path.realpath(path)
        if not real.startswith(content + os.sep) or real.startswith(os.path.join(content, "locale") + os.sep):
            raise SystemExit("%s: not a content file (run from apps/lab3d)" % path)
        with open(path, encoding="utf-8") as handle:
            source = json.load(handle)
        data, words = split(source)
        rel = os.path.relpath(real, content)
        out = os.path.join("content", "locale", "ko", rel)
        if words is MISSING:
            raise SystemExit("%s: no words to move (already split?)" % path)
        if os.path.exists(out):
            raise SystemExit("%s: %s exists (add the new words there by hand)" % (path, out))
        if overlay(data, words) != source:
            raise SystemExit("%s: the parts do not add up to the file" % path)
        os.makedirs(os.path.dirname(out), exist_ok=True)
        with open(path, "w", encoding="utf-8") as handle:
            handle.write(dump(data) + "\n")
        with open(out, "w", encoding="utf-8") as handle:
            handle.write(dump(words) + "\n")
        print("%s -> %s" % (path, out))


if __name__ == "__main__":
    main(sys.argv[1:])
