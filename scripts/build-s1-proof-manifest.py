#!/usr/bin/env python3
"""Rebuild data/proofs/s-1/manifest.json with sha256 checksums."""
from __future__ import annotations

import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "data" / "proofs" / "s-1"

LABELS = {
    "anthropic": "Anthropic PBC · confidential draft S-1 · Rule 135",
    "openai": "OpenAI, Inc. · confidential draft S-1 · Rule 135",
    "xai-spacex-consolidated": "xAI · SpaceX consolidated S-1/A public segment",
}


def sha256(path: Path) -> str:
    h = hashlib.sha256()
    h.update(path.read_bytes())
    return h.hexdigest()


def main() -> None:
    proofs = []
    for sub, label in LABELS.items():
        d = OUT / sub
        proof_path = d / "proof.json"
        if not proof_path.is_file():
            raise SystemExit(f"missing proof.json: {proof_path}")
        proof = json.loads(proof_path.read_text())
        files = []
        for p in sorted(d.iterdir()):
            if p.is_file() and p.name != "proof.json":
                data = p.read_bytes()
                files.append(
                    {
                        "name": p.name,
                        "bytes": len(data),
                        "sha256": hashlib.sha256(data).hexdigest(),
                    }
                )
        proofs.append({"id": sub, "label": label, "proof": proof, "files": files})

    manifest = {
        "schema": "brmste-s1-proof-bundle/v1",
        "version": "2026-06-24",
        "operator": "Dr. Shravan Bansal · BRMSTE LTD",
        "company": "BRMSTE LTD · Companies House 15310393",
        "legit": True,
        "doctrine": "Confidential draft S-1s are not on EDGAR until public; proofs are Rule 135 announcements + consolidated public filings where applicable.",
        "download_script": "scripts/download-s1-proofs.sh",
        "proofs": proofs,
    }
    (OUT / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
    print(json.dumps({"proofs": len(proofs), "manifest": str(OUT / "manifest.json")}))


if __name__ == "__main__":
    main()
