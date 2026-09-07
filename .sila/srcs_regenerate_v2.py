from __future__ import annotations

from pathlib import Path
import hashlib
import os
import re
import shutil
import subprocess
import sys
import tempfile

if len(sys.argv) != 3:
    raise SystemExit('USAGE: srcs_regenerate_v2.py <upstream-worktree> <output-dir>')

SRC = Path(sys.argv[1]).resolve()
OUT = Path(sys.argv[2]).resolve()
BASE_GENERATOR = Path(__file__).with_name('srcs_regenerate_v1.py').resolve()
if not SRC.is_dir():
    raise SystemExit(f'UPSTREAM_SOURCE_MISSING:{SRC}')
if not BASE_GENERATOR.is_file():
    raise SystemExit(f'BASE_GENERATOR_MISSING:{BASE_GENERATOR}')

# These are identity compounds observed in official ERC source paths/templates.
# They are intentionally exact/identity-shaped rather than broad substring rules.
PATH_REPLACEMENTS = (
    ('eipnums', 'sipnums'),
    ('EIPNUMS', 'SIPNUMS'),
    ('eiptable', 'siptable'),
    ('EIPTABLE', 'SIPTABLE'),
    ('sass-eip', 'sass-sip'),
    ('SASS-EIP', 'SASS-SIP'),
    ('nonerc', 'nonsrc'),
    ('NONERC', 'NONSRC'),
    ('NonERC', 'NonSRC'),
    ('etherscan', 'silascan'),
    ('Etherscan', 'SilaScan'),
    ('ETHERSCAN', 'SILASCAN'),
)

TEXT_REPLACEMENTS = (
    ('eipnums', 'sipnums'),
    ('EIPNUMS', 'SIPNUMS'),
    ('eiptable', 'siptable'),
    ('EIPTABLE', 'SIPTABLE'),
    ('sass-eip', 'sass-sip'),
    ('SASS-EIP', 'SASS-SIP'),
    ('nonerc', 'nonsrc'),
    ('NONERC', 'NONSRC'),
    ('NonERC', 'NonSRC'),
    ('etherscan', 'silascan'),
    ('Etherscan', 'SilaScan'),
    ('ETHERSCAN', 'SILASCAN'),
)

BINARY_EXTENSIONS = {
    '.pdf', '.png', '.jpg', '.jpeg', '.gif', '.webp', '.ico', '.bmp', '.tif', '.tiff',
    '.zip', '.gz', '.tgz', '.xz', '.bz2', '.7z', '.rar', '.tar', '.wasm', '.woff', '.woff2',
    '.ttf', '.otf', '.eot', '.mp3', '.mp4', '.mov', '.avi', '.webm', '.ogg', '.wav', '.flac',
    '.bin', '.dat', '.db', '.sqlite', '.pyc', '.class', '.jar', '.so', '.dll', '.dylib', '.exe',
}
BINARY_MAGIC = (
    b'%PDF-', b'\x89PNG\r\n\x1a\n', b'\xff\xd8\xff', b'GIF87a', b'GIF89a', b'PK\x03\x04',
    b'PK\x05\x06', b'PK\x07\x08', b'\x1f\x8b', b'7z\xbc\xaf\x27\x1c', b'Rar!\x1a\x07',
    b'\x00asm', b'\x7fELF', b'MZ',
)
LEGACY_RX = re.compile(r'(?i)(eipnums|eiptable|sass-eip|nonerc|etherscan)')


def transform_path(rel: str) -> str:
    out = rel
    for old, new in PATH_REPLACEMENTS:
        out = out.replace(old, new)
    return out


def is_text(path: Path, data: bytes) -> bool:
    if path.suffix.lower() in BINARY_EXTENSIONS:
        return False
    if any(data.startswith(magic) for magic in BINARY_MAGIC):
        return False
    if b'\x00' in data:
        return False
    try:
        data.decode('utf-8')
        return True
    except UnicodeDecodeError:
        return False


def transform_text(text: str) -> str:
    out = text
    for old, new in TEXT_REPLACEMENTS:
        out = out.replace(old, new)
    return out


with tempfile.TemporaryDirectory(prefix='srcs-v2-') as td:
    stage = Path(td) / 'v1'
    subprocess.run([sys.executable, str(BASE_GENERATOR), str(SRC), str(stage)], check=True)

    if OUT.exists():
        shutil.rmtree(OUT)
    OUT.mkdir(parents=True)

    path_map: dict[str, str] = {}
    text_changed = 0
    binary_count = 0
    binary_hash_mismatch = 0
    path_changed = 0
    regular_count = 0
    symlink_count = 0

    entries = [p for p in stage.rglob('*')]
    entries.sort(key=lambda p: (len(p.relative_to(stage).parts), str(p.relative_to(stage))))
    for src in entries:
        rel = src.relative_to(stage).as_posix()
        dst_rel = transform_path(rel)
        if dst_rel in path_map and path_map[dst_rel] != rel:
            raise SystemExit(f'V2_PATH_COLLISION:{path_map[dst_rel]}::{rel}=>{dst_rel}')
        path_map[dst_rel] = rel
        path_changed += int(dst_rel != rel)
        dst = OUT / dst_rel

        if src.is_symlink():
            symlink_count += 1
            dst.parent.mkdir(parents=True, exist_ok=True)
            target = os.readlink(src)
            os.symlink(transform_path(target), dst)
            continue
        if src.is_dir():
            dst.mkdir(parents=True, exist_ok=True)
            continue

        regular_count += 1
        dst.parent.mkdir(parents=True, exist_ok=True)
        data = src.read_bytes()
        if is_text(src, data):
            text = data.decode('utf-8')
            transformed = transform_text(text)
            text_changed += int(transformed != text)
            dst.write_text(transformed, encoding='utf-8')
        else:
            binary_count += 1
            before = hashlib.sha256(data).digest()
            dst.write_bytes(data)
            after = hashlib.sha256(dst.read_bytes()).digest()
            binary_hash_mismatch += int(before != after)
        try:
            shutil.copystat(src, dst, follow_symlinks=False)
        except OSError:
            pass

    if binary_hash_mismatch:
        raise SystemExit(f'V2_BINARY_BYTE_IDENTITY_MISMATCH_COUNT={binary_hash_mismatch}')

# Path/content identity gate for the newly classified compounds.
residuals: list[str] = []
for p in OUT.rglob('*'):
    rel = p.relative_to(OUT).as_posix()
    if LEGACY_RX.search(rel):
        residuals.append(f'PATH::{rel}')
    if p.is_file() and not p.is_symlink():
        data = p.read_bytes()
        if is_text(p, data):
            text = data.decode('utf-8')
            if LEGACY_RX.search(text):
                residuals.append(f'TEXT::{rel}')
if residuals:
    print('V2_LEGACY_RESIDUALS_BEGIN')
    print('\n'.join(residuals[:500]))
    print('V2_LEGACY_RESIDUALS_END')
    raise SystemExit(f'V2_LEGACY_IDENTITY_RESIDUAL_COUNT={len(residuals)}')

path_canaries = {
    '_includes/eipnums.html': '_includes/sipnums.html',
    '_includes/eiptable.html': '_includes/siptable.html',
    'rss/nonerc.xml': 'rss/nonsrc.xml',
    'rss/nonerc-last-call.xml': 'rss/nonsrc-last-call.xml',
    'assets/src-1967/Sample-proxy-on-etherscan.png': 'assets/src-1967/Sample-proxy-on-silascan.png',
    'x/sass-eip.scss': 'x/sass-sip.scss',
}
for old, expected in path_canaries.items():
    got = transform_path(old)
    if got != expected:
        raise SystemExit(f'V2_PATH_CANARY_FAIL:{old}:{got}:{expected}')

text_canaries = {
    '{% include eipnums.html eips=page.requires %}': '{% include sipnums.html eips=page.requires %}',
    '{% include eiptable.html eips=site.pages %}': '{% include siptable.html eips=site.pages %}',
    'rss/nonerc.xml': 'rss/nonsrc.xml',
    'Sample-proxy-on-etherscan.png': 'Sample-proxy-on-silascan.png',
    'together': 'together',
    'method': 'method',
}
for old, expected in text_canaries.items():
    got = transform_text(old)
    if got != expected:
        raise SystemExit(f'V2_TEXT_CANARY_FAIL:{old}:{got}:{expected}')

required = (
    '_includes/sipnums.html',
    '_includes/siptable.html',
    'rss/nonsrc.xml',
    'rss/nonsrc-last-call.xml',
    'assets/src-1967/Sample-proxy-on-silascan.png',
    'SRCS/src-2535.md',
    'SRCS/src-7730.md',
)
missing = [x for x in required if not (OUT / x).exists()]
if missing:
    raise SystemExit('V2_REQUIRED_PATH_MISSING:' + ','.join(missing))

file_count = sum(1 for p in OUT.rglob('*') if p.is_file() or p.is_symlink())
print(f'V2_GENERATED_FILE_COUNT={file_count}')
print(f'V2_REGULAR_FILE_COUNT={regular_count}')
print(f'V2_SYMLINK_COUNT={symlink_count}')
print(f'V2_BINARY_FILE_COUNT={binary_count}')
print(f'V2_PATH_RENAME_COUNT={path_changed}')
print(f'V2_TRANSFORMED_TEXT_FILE_COUNT={text_changed}')
print('V2_PATH_COLLISION_COUNT=0')
print('V2_BINARY_BYTE_IDENTITY_MISMATCH_COUNT=0')
print('V2_PATH_CANARY_FAILURE_COUNT=0')
print('V2_TEXT_CANARY_FAILURE_COUNT=0')
print('V2_LEGACY_IDENTITY_RESIDUAL_COUNT=0')
print('SRC_NATIVE_V2_GATE=PASS')
