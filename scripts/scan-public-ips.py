#!/usr/bin/env python3
"""
scan-public-ips.py — Çalışma dizininde, staged değişikliklerde veya git geçmişinde
PUBLIC (internete açık) IP adreslerini ve şüpheli SSH port değerlerini arar.

Private / loopback / link-local / dokümantasyon aralıkları (10/8, 192.168/16,
127/8, 192.0.2/24 ...) Python'un ipaddress modülüyle otomatik elenir.

Kullanım:
  python3 scripts/scan-public-ips.py              # çalışma dizini
  python3 scripts/scan-public-ips.py --history    # çalışma dizini + tüm git geçmişi
  python3 scripts/scan-public-ips.py --staged     # sadece commit'lenecek satırlar (pre-commit)

Bilinen zararsız değerler için repo kökünde .ip-allowlist dosyası (satır başına bir IP
veya port; # ile yorum) kullanılabilir.

Çıkış kodu: bulgu varsa 1, yoksa 0.
"""
import argparse
import ipaddress
import re
import subprocess
import sys
from pathlib import Path

IPV4 = re.compile(
    r"(?<![\d.])(?:(?:25[0-5]|2[0-4]\d|1?\d?\d)\.){3}(?:25[0-5]|2[0-4]\d|1?\d?\d)(?![\d.])"
)
# Geniş yakalar; geçerlilik ipaddress ile doğrulanır (saat, MAC vb. elenir).
IPV6 = re.compile(r"(?<![0-9A-Fa-f:])(?:[0-9A-Fa-f]{0,4}:){2,7}[0-9A-Fa-f]{0,4}(?![0-9A-Fa-f:])")
SSH_PORT = re.compile(
    r"(?i)\b([A-Z_]*SSH_PORT|ssh_port|custom_ssh_port|ansible_port)\b\s*[=:]\s*[\"']?(\d{2,5})\b"
)
# Repo içinde örnek/varsayılan olarak kullanılması bilinçli olan portlar
DEFAULT_SAFE_PORTS = {"22", "55555"}

SKIP_DIRS = {".git", ".vagrant", "node_modules", "__pycache__"}
SELF = Path(__file__).resolve()


def load_allowlist(root: Path) -> set:
    f = root / ".ip-allowlist"
    if not f.exists():
        return set()
    out = set()
    for line in f.read_text(encoding="utf-8").splitlines():
        line = line.split("#", 1)[0].strip()
        if line:
            out.add(line)
    return out


def find_in_line(line: str, allow: set):
    hits = []
    for rx, kind in ((IPV4, "IPv4"), (IPV6, "IPv6")):
        for m in rx.findall(line):
            try:
                ip = ipaddress.ip_address(m)
            except ValueError:
                continue
            if ip.is_global and str(ip) not in allow:
                hits.append((kind, str(ip)))
    for name, port in SSH_PORT.findall(line):
        if port not in DEFAULT_SAFE_PORTS and port not in allow:
            hits.append(("SSH-PORT", f"{name}={port}"))
    return hits


def is_binary(path: Path) -> bool:
    try:
        with path.open("rb") as fh:
            return b"\0" in fh.read(8192)
    except OSError:
        return True


def is_env_file(p: Path) -> bool:
    # .env, .env.local, .env.production ... (sırlar) — ama .env.example taranır
    return p.name.startswith(".env") and p.name != ".env.example"


def list_files(root: Path):
    """Git varsa: .gitignore'a uyan dosyaları atla (commit'lenecek olanları tara).
    Git yoksa: tüm dosyalar, ama .env* her durumda atlanır."""
    if (root / ".git").exists():
        out = git(root, "ls-files", "-co", "--exclude-standard", "-z")
        return sorted(root / f for f in out.split("\0") if f)
    return sorted(root.rglob("*"))


def scan_tree(root: Path, allow: set):
    findings = []
    for p in list_files(root):
        if not p.is_file() or any(part in SKIP_DIRS for part in p.relative_to(root).parts):
            continue
        if is_env_file(p):
            continue
        if p.resolve() == SELF or p.name == ".ip-allowlist" or is_binary(p):
            continue
        try:
            text = p.read_text(encoding="utf-8", errors="replace")
        except OSError:
            continue
        for n, line in enumerate(text.splitlines(), 1):
            for kind, val in find_in_line(line, allow):
                findings.append(f"[tree]    {p.relative_to(root)}:{n}  {kind}  {val}")
    return findings


def git(root: Path, *args) -> str:
    return subprocess.run(
        ["git", "-C", str(root), *args], capture_output=True, text=True, errors="replace"
    ).stdout


def scan_diff(text: str, label: str, allow: set):
    findings, commit, path = [], "", ""
    for line in text.splitlines():
        if line.startswith("commit "):
            commit = line.split()[1][:10]
        elif line.startswith("+++ "):
            path = line[6:] if line.startswith("+++ b/") else line[4:]
        elif line.startswith(("+", "-")) and not line.startswith(("+++", "---")):
            for kind, val in find_in_line(line, allow):
                where = f"{commit} " if commit else ""
                findings.append(f"[{label}] {where}{path}  {kind}  {val}")
    return findings


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--history", action="store_true", help="tüm git geçmişini de tara")
    ap.add_argument("--staged", action="store_true", help="sadece staged değişiklikleri tara")
    ap.add_argument("--root", default=".", help="repo kökü (varsayılan: .)")
    a = ap.parse_args()

    root = Path(a.root).resolve()
    allow = load_allowlist(root)
    findings = []

    if a.staged:
        findings += scan_diff(git(root, "diff", "--cached", "-U0", "--no-color"), "staged", allow)
    else:
        findings += scan_tree(root, allow)
        if a.history:
            if (root / ".git").exists():
                log = git(root, "log", "-p", "--all", "--no-color", "--no-ext-diff")
                findings += scan_diff(log, "history", allow)
            else:
                print("NOT: .git yok, geçmiş taraması atlandı.", file=sys.stderr)

    findings = sorted(set(findings))
    if findings:
        print(f"⚠️  {len(findings)} bulgu (public IP / şüpheli SSH portu):\n")
        print("\n".join(findings))
        print("\nZararsız olanları .ip-allowlist dosyasına ekleyebilirsin.")
        return 1
    print("✅ Public IP veya şüpheli SSH portu bulunamadı.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
