#!/usr/bin/env python3
"""Generate an AI-first `llms.txt` for a pico-* package from its public API.

Reads `src/<pkg>/__init__.py` (the public contract: `__all__` + `from .mod
import ...` re-exports) via AST — no import, so the venv/auto-discovery traps
never fire. For each exported symbol it pulls the signature + first docstring
line from the defining module, and lists the docs/ tree for navigation.

Usage:  python gen-llms-txt.py /path/to/pico-foo [--write]
        (--write saves <repo>/llms.txt; otherwise prints to stdout)

ponytail: handles the fleet's one pattern (`from .mod import X` in __init__).
A star-import or dynamic __all__ would need extending — none exist in the fleet.
"""
import ast
import sys
from pathlib import Path


def _summary(repo: Path) -> str:
    mk = repo / "mkdocs.yml"
    if mk.exists():
        for line in mk.read_text().splitlines():
            if line.startswith("site_description:"):
                return line.split(":", 1)[1].strip().strip("'\"")
    return ""


def _sig(node: ast.AST) -> str:
    if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef)):
        return f"{node.name}({ast.unparse(node.args)})"
    if isinstance(node, ast.ClassDef):
        bases = ", ".join(ast.unparse(b) for b in node.bases)
        return f"class {node.name}" + (f"({bases})" if bases else "")
    return getattr(node, "name", "?")


def _doc1(node: ast.AST) -> str:
    doc = ast.get_docstring(node) if isinstance(
        node, (ast.FunctionDef, ast.AsyncFunctionDef, ast.ClassDef)) else None
    return doc.strip().splitlines()[0] if doc else ""


def collect(pkg_dir: Path):
    init = ast.parse((pkg_dir / "__init__.py").read_text())
    all_names, origin = [], {}
    for n in ast.walk(init):
        if isinstance(n, ast.ImportFrom) and n.module and n.level == 1:
            for a in n.names:
                origin[a.asname or a.name] = (n.module, a.name)
        if isinstance(n, ast.Assign):
            for t in n.targets:
                if isinstance(t, ast.Name) and t.id == "__all__" and isinstance(n.value, (ast.List, ast.Tuple)):
                    all_names = [e.value for e in n.value.elts if isinstance(e, ast.Constant)]
    # No __all__ declared: the public surface is what __init__ re-exports.
    if not all_names:
        all_names = [k for k in origin if not k.startswith("_")]
    # per-module (defs, local re-export map), parsed lazily
    cache: dict[str, tuple] = {}

    def parse(mod: str):
        if mod not in cache:
            f = pkg_dir / f"{mod}.py"
            d, imp = {}, {}
            if f.exists():
                for node in ast.parse(f.read_text()).body:
                    if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef, ast.ClassDef)):
                        d[node.name] = node
                    elif isinstance(node, ast.ImportFrom) and node.module and node.level == 1:
                        for a in node.names:
                            imp[a.asname or a.name] = (node.module, a.name)
            cache[mod] = (d, imp)
        return cache[mod]

    def resolve(mod: str, name: str, depth: int = 0):
        # follow `from .other import name` facades until a def/class is found
        if not mod or depth > 6:
            return None
        d, imp = parse(mod)
        if name in d:
            return d[name]
        if name in imp:
            nmod, nname = imp[name]
            return resolve(nmod, nname, depth + 1)
        return None

    out = []
    for name in all_names:
        if name.isupper():  # module-level constants (LOGGER_NAME, PICO_*): infra, not codegen API
            continue
        mod, orig = origin.get(name, (None, name))
        node = resolve(mod, orig)
        out.append((name, _sig(node) if node else name, _doc1(node) if node else ""))
    return out


def usage(repo: Path) -> str:
    """First ```python fenced block from the README — the canonical snippet."""
    rd = repo / "README.md"
    if not rd.exists():
        return ""
    lines, block, grab = rd.read_text().splitlines(), [], False
    for ln in lines:
        if grab:
            if ln.strip().startswith("```"):
                break
            block.append(ln)
        elif ln.strip() in ("```python", "```py"):
            grab = True
    return "\n".join(block).strip()


def docs_sections(repo: Path):
    """Group docs/: one line per top-level subdir (with page count), plus
    any top-level pages by name. Beats listing every ADR."""
    d = repo / "docs"
    if not d.is_dir():
        return []
    rows = []
    for child in sorted(d.iterdir()):
        if child.is_dir():
            n = sum(1 for _ in child.rglob("*.md"))
            if n:
                rows.append(f"docs/{child.name}/ ({n} pages)")
        elif child.suffix == ".md" and child.name not in ("README.md", "index.md"):
            rows.append(f"docs/{child.name}")
    return rows


def find_pkg(repo: Path):
    """The importable package dir. Prefer the one matching the repo name
    (pico-data-redis -> pico_data_redis, not a sibling like pico_redis)."""
    want = repo.name.replace("-", "_")
    for base in (repo / "src", repo):
        cand = base / want
        if (cand / "__init__.py").exists():
            return cand
    for base in (repo / "src", repo):
        if base.is_dir():
            hit = next((p for p in base.glob("pico_*") if (p / "__init__.py").exists()), None)
            if hit:
                return hit
    return None


def render(repo: Path):
    """Returns the llms.txt text, or None if the repo has no public API surface."""
    name = repo.name
    pkg = find_pkg(repo)
    api = collect(pkg) if pkg else []
    if not api:  # not a library (app/meta/BOM) — nothing an LLM writes code against
        return None
    L = [f"# {name}", ""]
    s = _summary(repo)
    if s:
        L += [f"> {s}", ""]
    L += [f"Install: `pip install {name}`. Import surface: `from {pkg.name} import ...`.", ""]
    snippet = usage(repo)
    if snippet:
        L += ["## Usage", "", "```python", snippet, "```", ""]
    L += ["## Public API", ""]
    for nm, sig, doc in api:
        L.append(f"- `{sig}`" + (f" — {doc}" if doc else ""))
    sections = docs_sections(repo)
    if sections:
        L += ["", "## Docs", ""]
        for rel in sections:
            L.append(f"- {rel}")
    return "\n".join(L) + "\n"


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    write = "--write" in sys.argv
    repo = Path(args[0]).resolve()
    txt = render(repo)
    if txt is None:
        print(f"skip {repo.name}: no public API (not a library)")
        return
    if write:
        (repo / "llms.txt").write_text(txt)
        print(f"wrote {repo / 'llms.txt'} ({len(txt.splitlines())} lines, {txt.count('- `')} symbols)")
    else:
        print(txt)


if __name__ == "__main__":
    main()
