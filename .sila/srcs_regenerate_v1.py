from __future__ import annotations

from pathlib import Path
import os
import re
import shutil
import sys

if len(sys.argv) != 3:
    raise SystemExit('USAGE: srcs_regenerate_v1.py <upstream-worktree> <output-dir>')

SRC = Path(sys.argv[1]).resolve()
OUT = Path(sys.argv[2]).resolve()
if not SRC.is_dir():
    raise SystemExit(f'UPSTREAM_SOURCE_MISSING:{SRC}')
if OUT.exists():
    shutil.rmtree(OUT)
OUT.mkdir(parents=True)

URL_RE = re.compile(r'https?://[^\s\)\]\}\>\"\']+')
MD_LINK_RE = re.compile(r'\[([^\]]+)\]\((https?://[^\)]+)\)')
ETH_RESEARCH_MD_RE = re.compile(r'\[([^\]]+)\]\(https?://ethresear\.ch/[^\)]+\)')
ETH_RESEARCH_FRONTMATTER_RE = re.compile(r'(?m)^discussions-to:\s*https?://ethresear\.ch/\S+\s*\n')

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


def case_token(token: str, upper: str, title: str, lower: str) -> str:
    if token.isupper():
        return upper
    if token[:1].isupper():
        return title
    return lower


def token_geth(text: str) -> str:
    patterns = (
        (r'(?<![A-Za-z0-9])GETH(?=$|[^A-Za-z0-9])', 'SILA'),
        (r'(?<![A-Za-z0-9])Geth(?=$|[^A-Za-z0-9])', 'Sila'),
        (r'(?<![A-Za-z0-9])geth(?=$|[^A-Za-z0-9])', 'sila'),
        (r'(?<![A-Za-z0-9])GETH(?=[A-Z])', 'SILA'),
        (r'(?<![A-Za-z0-9])Geth(?=[A-Z])', 'Sila'),
        (r'(?<![A-Za-z0-9])geth(?=[A-Z])', 'sila'),
    )
    for pattern, repl in patterns:
        text = re.sub(pattern, repl, text)
    return text


def protocol_identity(text: str) -> str:
    # Explicit compound identities first.
    exact = [
        ('IWETH', 'IWSIL'), ('WETH', 'WSIL'), ('IERC', 'ISRC'), ('AERC', 'ASRC'), ('IEIP', 'ISIP'),
        ('GETH_NAME', 'SILA_NAME'),
    ]
    for a, b in exact:
        text = text.replace(a, b)

    # Ethereum is an unambiguous product/protocol identity token, including CamelCase identifiers.
    text = text.replace('ETHEREUM', 'SILA').replace('Ethereum', 'Sila').replace('ethereum', 'sila')

    # ERC/EIP identities: labels, numeric forms, and CamelCase identifier segments.
    rules = (
        (r'(?<![A-Za-z0-9])ERCS(?=$|[^A-Za-z0-9])', 'SRCS'),
        (r'(?<![A-Za-z0-9])ERCs(?=$|[^A-Za-z0-9])', 'SRCs'),
        (r'(?<![A-Za-z0-9])ercs(?=$|[^A-Za-z0-9])', 'srcs'),
        (r'(?<![A-Za-z0-9])ERC(?=$|[^A-Za-z0-9])', 'SRC'),
        (r'(?<![A-Za-z0-9])Erc(?=$|[^A-Za-z0-9])', 'Src'),
        (r'(?<![A-Za-z0-9])erc(?=$|[^A-Za-z0-9])', 'src'),
        (r'(?<![A-Za-z0-9])EIPS(?=$|[^A-Za-z0-9])', 'SIPS'),
        (r'(?<![A-Za-z0-9])EIPs(?=$|[^A-Za-z0-9])', 'SIPs'),
        (r'(?<![A-Za-z0-9])eips(?=$|[^A-Za-z0-9])', 'sips'),
        (r'(?<![A-Za-z0-9])EIP(?=$|[^A-Za-z0-9])', 'SIP'),
        (r'(?<![A-Za-z0-9])Eip(?=$|[^A-Za-z0-9])', 'Sip'),
        (r'(?<![A-Za-z0-9])eip(?=$|[^A-Za-z0-9])', 'sip'),
        (r'ERC(?=[0-9])', 'SRC'),
        (r'EIP(?=[0-9])', 'SIP'),
        (r'(?<=[a-z])ERC(?=[A-Z0-9])', 'SRC'),
        (r'(?<=[a-z])EIP(?=[A-Z0-9])', 'SIP'),
    )
    for pattern, repl in rules:
        text = re.sub(pattern, repl, text)

    # Lowercase protocol labels attached to digits/separators.
    text = re.sub(r'(?<![A-Za-z0-9])erc(?=[0-9_.-])', 'src', text)
    text = re.sub(r'(?<![A-Za-z0-9])eip(?=[0-9_.-])', 'sip', text)

    # ETH identity only when syntactically protocol-like. Never rewrite substrings in normal words.
    text = re.sub(r'(?<![A-Za-z0-9])ETH(?=$|[^A-Za-z0-9])', 'SIL', text)
    text = re.sub(r'(?<![A-Za-z0-9])Eth(?=$|[^A-Za-z0-9])', 'Sil', text)
    text = re.sub(r'(?<![A-Za-z0-9])eth(?=$|[^A-Za-z0-9])', 'sil', text)
    text = re.sub(r'(?<![A-Za-z0-9])ETH(?=[0-9_-])', 'SIL', text)
    text = re.sub(r'(?<![A-Za-z0-9])Eth(?=[0-9_-])', 'Sil', text)
    text = re.sub(r'(?<![A-Za-z0-9])eth(?=[0-9_-])', 'sil', text)
    text = re.sub(r'(?<![A-Za-z0-9_])eth_([A-Za-z0-9_]+)', r'sil_\1', text)
    text = re.sub(r'(?<![A-Za-z0-9])eth(?=[A-Z])', 'sil', text)
    text = re.sub(r'(?<![A-Za-z0-9])ETH(?=[A-Z0-9_])', 'SIL', text)
    text = re.sub(r'(?<![A-Za-z0-9])(?:ETH|Eth|eth)(?=falcon)',
                  lambda m: case_token(m.group(0), 'SIL', 'Sil', 'sil'), text, flags=re.IGNORECASE)

    # Ether as a standalone identity or identifier prefix; do not corrupt Ethernet, etc.
    text = re.sub(r'(?<![A-Za-z0-9])Ether(?=$|[^A-Za-z0-9])', 'Sila', text)
    text = re.sub(r'(?<![A-Za-z0-9])ether(?=$|[^A-Za-z0-9])', 'sila', text)
    text = re.sub(r'(?<![A-Za-z0-9])Ether(?=[A-Z0-9_])', 'Sila', text)
    text = re.sub(r'(?<![A-Za-z0-9])ether(?=[A-Z0-9_])', 'sila', text)

    text = token_geth(text)

    # Pure Sila VM policy intentionally converts every EVM spelling, including embedded identifiers.
    text = re.sub(r'(?i)evm', lambda m: 'SVM' if m.group(0).isupper() else ('Svm' if m.group(0)[:1].isupper() else 'svm'), text)
    return text


def transform_url(url: str) -> str | None:
    lower = url.lower()
    if 'ethresear.ch/' in lower:
        return None
    url = re.sub(r'(?i)github\.com/ethereum/go-ethereum', 'github.com/sila-chain/go-sila', url)
    url = re.sub(r'(?i)raw\.githubusercontent\.com/ethereum/go-ethereum', 'raw.githubusercontent.com/sila-chain/go-sila', url)
    url = re.sub(r'(?i)github\.com/ethereum/(?:eth2\.0-specs|eth2spec)', 'github.com/sila-chain/consensus-specs', url)
    l2 = url.lower()
    if any(x in l2 for x in ('evmone', 'openethereum', 'ethereum.github.io/evmc', 'py-evm', 'pyethereum', 'cpp-ethereum', 'ethereumj', 'ethash', 'ethcore', 'ethcc')):
        return None
    url = re.sub(r'(?i)github\.com/ethereum/', 'github.com/sila-chain/', url)
    url = re.sub(r'(?i)raw\.githubusercontent\.com/ethereum/', 'raw.githubusercontent.com/sila-chain/', url)
    url = url.replace('eips.ethereum.org', 'sips.sila.org')
    url = url.replace('ethereum-magicians.org', 'sila-magicians.org')
    url = url.replace('ethereum.stackexchange.com', 'sila.stackexchange.com')
    url = url.replace('notes.ethereum.org', 'notes.sila.org')
    url = url.replace('blog.ethereum.org', 'blog.sila.org')
    url = url.replace('ethereum.org', 'sila.org')
    url = re.sub(r'(?i)(sips\.sila\.org)/erc(?=$|[/#?])', r'\1/src', url)
    url = protocol_identity(url)
    if re.search(r'(?i)(ethereum|(?:^|[/_.+\-])eips?(?:[/_.+\-]|[0-9])|(?:^|[/_.+\-])ercs?(?:[/_.+\-]|[0-9])|evm|geth|eth2spec|eth_)', url):
        return None
    return url


def transform_text(text: str) -> str:
    text = text.replace('\\x19Ethereum Signed Message:', '\\x19Sila Signed Message:')
    text = ETH_RESEARCH_FRONTMATTER_RE.sub('', text)
    text = ETH_RESEARCH_MD_RE.sub(lambda m: m.group(1), text)
    text = text.replace('../assets/eip-712/eth_sign.png', '../assets/eip-712/sil_sign.png')
    text = text.replace('../assets/eip-712/eth_signTypedData.png', '../assets/eip-712/sil_signTypedData.png')

    def md_link_repl(m: re.Match[str]) -> str:
        label, url = m.group(1), m.group(2)
        transformed = transform_url(url)
        return label if transformed is None else f'[{label}]({transformed})'
    text = MD_LINK_RE.sub(md_link_repl, text)

    saved_urls: list[str] = []
    def url_repl(m: re.Match[str]) -> str:
        original = m.group(0)
        transformed = transform_url(original)
        if transformed is None:
            return ''
        if transformed != original:
            return transformed
        token = f'__SILA_URL_{len(saved_urls):06d}__'
        saved_urls.append(original)
        return token
    text = URL_RE.sub(url_repl, text)

    exact = [
        ('github.com/ethereum/go-ethereum', 'github.com/sila-chain/go-sila'),
        ('ethereum/go-ethereum', 'sila-chain/go-sila'), ('go-ethereum', 'go-sila'),
        ('PyEthereum', 'PySila'), ('pyethereum', 'pysila'),
        ('CPP-Ethereum', 'CPP-Sila'), ('cpp-ethereum', 'cpp-sila'),
        ('EthereumJ', 'SilaJ'), ('ethereumj', 'silaj'),
        ('ETHASH', 'SILASH'), ('Ethash', 'Silash'), ('ethash', 'silash'),
        ('ETHCORE', 'SILCORE'), ('Ethcore', 'Silcore'), ('ethcore', 'silcore'),
        ('EthCC', 'Sila community conference'),
        ('eth2.0-specs', 'consensus-specs'), ('eth2spec', 'consensus-specs'),
        ('Py-EVM', 'Py-SVM'), ('py-evm', 'py-svm'),
        ('openethereum-evm', 'sila-svm'), ('OpenEthereum', 'Sila'), ('openethereum', 'sila'),
        ('web+evm', 'web+svm'), ('EVM64', 'SVM64'), ('Evm64', 'Svm64'), ('evm64', 'svm64'),
        ('gasEVM', 'gasSVM'), ('GasEVM', 'GasSVM'), ('GASEVM', 'GASSVM'),
        ('test_setEVM', 'test_setSVM'), ('mldsa_evm', 'mldsa_svm'),
        ('evmone', 'svmone'), ('EVMONE', 'SVMONE'), ('EVMC', 'SVMC'), ('evmc', 'svmc'),
        ('eip-review-bot', 'sip-review-bot'), ('EIP-Review-Bot', 'SIP-Review-Bot'),
        ('eipw-action', 'sipw-action'), ('EIPW', 'SIPW'), ('eipw', 'sipw'),
        ('Ethereum Foundation', 'Sila Foundation'), ('ethereum Foundation', 'Sila Foundation'),
        ('Ethereum Magicians', 'Sila Magicians'), ('Ethereum Stack Exchange', 'Sila Stack Exchange'),
        ('Ethereum Research', 'Sila Research'), ('Etherscan', 'SilaScan'), ('etherscan', 'silascan'),
        ('ethereumjs', 'silajs'), ('EthereumJS', 'SilaJS'), ('@ethereumjs', '@silajs'),
        ('/eth2/', '/sila/'), ('/eth/', '/sila/'),
    ]
    for a, b in exact:
        text = text.replace(a, b)

    text = re.sub(r'(?i)(?<![A-Za-z0-9_])ethereum_([A-Za-z0-9_]+)', r'sila_\1', text)
    text = re.sub(r'(?<![A-Za-z0-9_.-])ethereum/', 'sila-chain/', text)
    text = protocol_identity(text)

    network_rules = [
        ('Mainnet','SilaMainnet'),('MAINNET','SILA_MAINNET'),('mainnet','sila-mainnet'),
        ('Sepolia','SilaSepolia'),('Holesky','SilaHolesky'),('Deneb','SilaDeneb'),('Fulu','SilaFulu'),('PeerDAS','SilaPeerDAS'),
        ('Cancun','SilaCancun'),('Shanghai','SilaShanghai'),('Prague','SilaPrague'),('Osaka','SilaOsaka'),
        ('Paris','SilaParis'),('Amsterdam','SilaAmsterdam'),('Kovan','SilaKovan'),
    ]
    for a, b in network_rules:
        text = re.sub(rf'(?<![A-Za-z0-9_]){re.escape(a)}(?![A-Za-z0-9_])', b, text)

    for i, value in enumerate(saved_urls):
        text = text.replace(f'__SILA_URL_{i:06d}__', value)
    return text


def transform_path(rel: str) -> str:
    text = rel
    exact = [
        ('go-ethereum','go-sila'),
        ('PyEthereum','PySila'),('pyethereum','pysila'),('CPP-Ethereum','CPP-Sila'),('cpp-ethereum','cpp-sila'),
        ('EthereumJ','SilaJ'),('ethereumj','silaj'),('ETHASH','SILASH'),('Ethash','Silash'),('ethash','silash'),
        ('ETHCORE','SILCORE'),('Ethcore','Silcore'),('ethcore','silcore'),
        ('eth2.0-specs','consensus-specs'),('eth2spec','consensus-specs'),
        ('Py-EVM','Py-SVM'),('py-evm','py-svm'),('openethereum-evm','sila-svm'),
        ('web+evm','web+svm'),('EVM64','SVM64'),('evm64','svm64'),('gasEVM','gasSVM'),
        ('test_setEVM','test_setSVM'),('mldsa_evm','mldsa_svm'),('evmone','svmone'),('EVMC','SVMC'),('evmc','svmc'),
        ('eip-review-bot','sip-review-bot'),('EIP-Review-Bot','SIP-Review-Bot'),('eipw-action','sipw-action'),('eipw','sipw'),
        ('ethereumjs','silajs'),('EthereumJS','SilaJS'),
    ]
    for a, b in exact:
        text = text.replace(a, b)
    text = protocol_identity(text)
    network_rules = [
        ('Mainnet','SilaMainnet'),('MAINNET','SILA_MAINNET'),('mainnet','sila-mainnet'),
        ('Sepolia','SilaSepolia'),('Holesky','SilaHolesky'),('Deneb','SilaDeneb'),('Fulu','SilaFulu'),('PeerDAS','SilaPeerDAS'),
        ('Cancun','SilaCancun'),('Shanghai','SilaShanghai'),('Prague','SilaPrague'),('Osaka','SilaOsaka'),
        ('Paris','SilaParis'),('Amsterdam','SilaAmsterdam'),('Kovan','SilaKovan'),
    ]
    for a, b in network_rules:
        text = re.sub(rf'(?<![A-Za-z0-9_]){re.escape(a)}(?![A-Za-z0-9_])', b, text)
    return text


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


mapped: dict[str, str] = {}
regular = symlinks = text_count = binary_count = changed_text = path_renames = 0
binary_byte_mismatch = 0
entries = [p for p in SRC.rglob('*') if p.name != '.git' and '.git' not in p.parts]
entries.sort(key=lambda p: (len(p.relative_to(SRC).parts), str(p.relative_to(SRC))))
for src in entries:
    rel = src.relative_to(SRC).as_posix()
    dst_rel = transform_path(rel)
    if dst_rel in mapped and mapped[dst_rel] != rel:
        raise SystemExit(f'PATH_COLLISION:{mapped[dst_rel]}::{rel}=>{dst_rel}')
    mapped[dst_rel] = rel
    path_renames += int(dst_rel != rel)
    dst = OUT / dst_rel
    if src.is_symlink():
        symlinks += 1
        dst.parent.mkdir(parents=True, exist_ok=True)
        os.symlink(transform_path(os.readlink(src)), dst)
    elif src.is_dir():
        dst.mkdir(parents=True, exist_ok=True)
    else:
        regular += 1
        dst.parent.mkdir(parents=True, exist_ok=True)
        data = src.read_bytes()
        if is_text(src, data):
            text_count += 1
            s = data.decode('utf-8')
            t = transform_text(s)
            changed_text += int(t != s)
            dst.write_text(t, encoding='utf-8')
        else:
            binary_count += 1
            dst.write_bytes(data)
            if dst.read_bytes() != data:
                binary_byte_mismatch += 1
        try:
            shutil.copystat(src, dst, follow_symlinks=False)
        except OSError:
            pass

if binary_byte_mismatch:
    raise SystemExit(f'BINARY_BYTE_IDENTITY_MISMATCH_COUNT={binary_byte_mismatch}')

generated = sum(1 for p in OUT.rglob('*') if p.is_file() or p.is_symlink())
if generated != regular + symlinks:
    raise SystemExit(f'FILE_COUNT_MISMATCH:{generated}:{regular+symlinks}')

# Deterministic SRC-2535 local repair. The upstream source has not changed since 2023.
src2535 = OUT / 'SRCS/src-2535.md'
if src2535.is_file():
    lines = src2535.read_text(encoding='utf-8').splitlines(keepends=True)
    hits = [i for i, line in enumerate(lines) if 'Download it as a zip file:' in line]
    if len(hits) != 1:
        raise SystemExit(f'SRC2535_ZIP_REPAIR_AUTHORITY_MISMATCH:{len(hits)}')
    del lines[hits[0]]
    src2535.write_text(''.join(lines), encoding='utf-8')
else:
    raise SystemExit('SRC2535_MISSING')

# Pure-Sila identity gate: protocol-shaped legacy identity only, not English substrings.
forbidden = [
    r'(?i)ethereum',
    r'(?<![A-Za-z0-9])(?:EIP|EIPs|EIPS|eip|eips)(?=$|[^A-Za-z0-9])',
    r'(?<![A-Za-z0-9])(?:ERC|ERCs|ERCS|erc|ercs)(?=$|[^A-Za-z0-9])',
    r'ERC(?=[0-9])', r'EIP(?=[0-9])', r'(?<=[a-z])ERC(?=[A-Z0-9])', r'(?<=[a-z])EIP(?=[A-Z0-9])',
    r'github\.com/ethereum/', r'eips\.ethereum\.org', r'ethresear\.ch/',
    r'(?<![A-Za-z0-9])go-ethereum(?=$|[^A-Za-z0-9])',
    r'(?<![A-Za-z0-9])(?:geth|Geth|GETH)(?=$|[^A-Za-z0-9])',
    r'(?<![A-Za-z0-9_])eth_[A-Za-z0-9_]+', r'(?<![A-Za-z0-9])eth(?=[A-Z])',
    r'eth2spec', r'eth2\.0-specs', r'Py-EVM', r'py-evm', r'openethereum-evm', r'web\+evm',
    r'(?i)evm', r'(?i)(?<![A-Za-z0-9_])pyethereum(?![A-Za-z0-9_])',
    r'(?i)(?<![A-Za-z0-9_])cpp-ethereum(?![A-Za-z0-9_])', r'(?i)(?<![A-Za-z0-9_])ethereumj(?![A-Za-z0-9_])',
    r'(?i)(?<![A-Za-z0-9_])ethash(?![A-Za-z0-9_])', r'(?i)(?<![A-Za-z0-9_])ethcore(?![A-Za-z0-9_])',
    r'(?i)(?<![A-Za-z0-9_])ethfalcon[A-Za-z0-9_]*', r'(?<![A-Za-z0-9_])EthCC(?![A-Za-z0-9_])',
]
forbidden_rx = [re.compile(x) for x in forbidden]
residuals: list[str] = []
for p in OUT.rglob('*'):
    rel = p.relative_to(OUT).as_posix()
    for rx in forbidden_rx:
        if rx.search(rel):
            residuals.append(f'PATH::{rel}::{rx.pattern}')
            break
    if p.is_file() and not p.is_symlink():
        data = p.read_bytes()
        if is_text(p, data):
            txt = data.decode('utf-8')
            for rx in forbidden_rx:
                if rx.search(txt):
                    residuals.append(f'TEXT::{rel}::{rx.pattern}')
                    break
if residuals:
    print('PURE_SILA_RESIDUALS_BEGIN')
    print('\n'.join(residuals[:500]))
    print('PURE_SILA_RESIDUALS_END')
    raise SystemExit(f'PURE_SILA_IDENTITY_RESIDUAL_COUNT={len(residuals)}')

corrupt_tokens = ('wh'+'sila', 'soms'+'iling', 'togs'+'ila', 'tos'+'ilaer', 'nons'+'ileless')
corruption: list[str] = []
for p in OUT.rglob('*'):
    if not p.is_file() or p.is_symlink():
        continue
    data = p.read_bytes()
    if not is_text(p, data):
        continue
    txt = data.decode('utf-8')
    for token in corrupt_tokens:
        if token in txt:
            corruption.append(f'{p.relative_to(OUT)}::{token}')
if corruption:
    print('KNOWN_CORRUPTION_BEGIN')
    print('\n'.join(corruption[:500]))
    print('KNOWN_CORRUPTION_END')
    raise SystemExit(f'KNOWN_CORRUPTION_RESIDUAL_COUNT={len(corruption)}')

path_canaries = {
    'ERCS/erc-20.md': 'SRCS/src-20.md',
    'assets/erc-2535/reference/example.sol': 'assets/src-2535/reference/example.sol',
    'assets/eip-712/eth_sign.png': 'assets/sip-712/sil_sign.png',
    'assets/erc-1155/geth_processing.png': 'assets/src-1155/sila_processing.png',
}
for old, new in path_canaries.items():
    got = transform_path(old)
    if got != new:
        raise SystemExit(f'PATH_CANARY_FAIL:{old}:{got}:{new}')

semantic_canaries = {
    'together': 'together',
    'something': 'something',
    'whether': 'whether',
    'method': 'method',
    'onERC1155Received': 'onSRC1155Received',
    'EthereumRevocationRegistry': 'SilaRevocationRegistry',
    'ethSignedMessageHash': 'silSignedMessageHash',
    'geth client': 'sila client',
    'eth_getBalance': 'sil_getBalance',
    'GETH_NAME': 'SILA_NAME',
    'go-ethereum': 'go-sila',
    'Py-EVM': 'Py-SVM',
    'EVMC_CALL': 'SVMC_CALL',
    'evmone': 'svmone',
    'EVM64': 'SVM64',
    'gasEVMPlusDECADD': 'gasSVMPlusDECADD',
    'web+evm': 'web+svm',
    '\\x19Ethereum Signed Message:': '\\x19Sila Signed Message:',
    'ethereum_best_known_block_number': 'sila_best_known_block_number',
    'PyEthereum': 'PySila',
    'ethash': 'silash',
    'ethcore': 'silcore',
    'EthCC': 'Sila community conference',
    'ethfalcon512': 'silfalcon512',
}
for old, new in semantic_canaries.items():
    got = transform_text(old)
    if got != new:
        raise SystemExit(f'SEMANTIC_CANARY_FAIL:{old}:{got}:{new}')

print(f'UPSTREAM_REGULAR_FILE_COUNT={regular}')
print(f'UPSTREAM_SYMLINK_COUNT={symlinks}')
print(f'GENERATED_FILE_COUNT={generated}')
print(f'TEXT_FILE_COUNT={text_count}')
print(f'BINARY_FILE_COUNT={binary_count}')
print(f'TRANSFORMED_TEXT_FILE_COUNT={changed_text}')
print(f'PATH_RENAME_COUNT={path_renames}')
print('PATH_COLLISION_COUNT=0')
print('PATH_CANARY_FAILURE_COUNT=0')
print('SEMANTIC_CANARY_FAILURE_COUNT=0')
print('BINARY_BYTE_IDENTITY_MISMATCH_COUNT=0')
print('SRC2535_BROKEN_ZIP_REPAIR_GATE=PASS')
print('KNOWN_CORRUPTION_RESIDUAL_COUNT=0')
print('PURE_SILA_IDENTITY_RESIDUAL_COUNT=0')
print('ACTIONABLE_IDENTITY_RESIDUAL_COUNT=0')
print('PURE_SILA_GENERATION_GATE=PASS')
print('GENERATION_GATE=PASS')
