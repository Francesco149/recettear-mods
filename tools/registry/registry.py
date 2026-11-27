#!/usr/bin/env python3
"""registry.py — write registry.json from mods/*/mod.toml (the launcher's package list).

  tools/registry/registry.py [--base URL] [--out registry.json] [--check]

One version per mod: the one in its mod.toml.  Every file under mods/<id>/ becomes a `download` with its sha256 +
size, served at  <base>/mods/<id>/<path>.  Default base = the GitHub raw URL at the tag `<id>-<version>` (so a
release = tag the commit, push the tag; the hash pins the bytes either way).  `--base http://host:port` = a local
`python3 -m http.server` in this repo (install tests before anything is pushed).  Release notes + dates:
tools/registry/notes.json ({id: {version: {released, notes}}}).  --check: exit 1 if registry.json is stale.
"""
import argparse, hashlib, json, os, sys, tomllib

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
RAW = "https://raw.githubusercontent.com/Francesco149/recettear-mods/{tag}"
SOURCE = {"name": "recettear-mods",
          "description": "Mods for Recettear on the Recettear Mod Loader.",
          "homepage": "https://github.com/Francesco149/recettear-mods", "maintainer": "Francesco149"}


def files(mod_dir):
    for d, dirs, fs in os.walk(mod_dir):
        dirs.sort()
        for f in sorted(fs):
            p = os.path.join(d, f)
            yield os.path.relpath(p, mod_dir).replace(os.sep, "/"), p


def build(base):
    notes = json.load(open(os.path.join(ROOT, "tools", "registry", "notes.json")))
    mods = []
    for mid in sorted(os.listdir(os.path.join(ROOT, "mods"))):
        md = os.path.join(ROOT, "mods", mid)
        toml = os.path.join(md, "mod.toml")
        if not os.path.isfile(toml):
            continue
        t = tomllib.load(open(toml, "rb"))
        m, ver = t["mod"], t["mod"]["version"]
        if m["id"] != mid:
            sys.exit(f"{toml}: id {m['id']!r} != its directory")
        n = notes.get(mid, {}).get(ver) or sys.exit(f"tools/registry/notes.json: no entry for {mid} {ver}")
        b = (base or RAW.format(tag=f"{mid}-{ver}")).rstrip("/")
        fl = []
        for rel, p in files(md):
            data = open(p, "rb").read()
            fl.append({"kind": "download", "dest": f"mods/{mid}/{rel}", "url": f"{b}/mods/{mid}/{rel}",
                       "sha256": hashlib.sha256(data).hexdigest(), "size": len(data)})
        mods.append({"id": mid, "name": m["name"], "description": m.get("description", ""),
                     "keywords": m.get("keywords", []), "target_games": m.get("target_games", []),
                     "versions": [{"version": ver, "released": n["released"], "notes": n["notes"],
                                   "min_loader": n.get("min_loader", "0.1.0"), "requires": n.get("requires", {}),
                                   "files": fl}]})
    return {"registry_version": 1, "source": SOURCE, "mods": mods}


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--base"); ap.add_argument("--out", default=os.path.join(ROOT, "registry.json"))
    ap.add_argument("--check", action="store_true")
    a = ap.parse_args()
    text = json.dumps(build(a.base), indent=2, ensure_ascii=False) + "\n"
    if a.check:
        if open(a.out).read() != text:
            sys.exit(f"{a.out} is stale: run tools/registry/registry.py")
        print("registry.json is current")
        return
    open(a.out, "w").write(text)
    print(f"{a.out}: {len(json.loads(text)['mods'])} mods")


if __name__ == "__main__":
    main()
