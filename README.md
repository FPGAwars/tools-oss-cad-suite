# Tools-oss-cad-suite

> **Note:** Please **do not** open issues in this repository.
> For any questions, discussions, or bug reports, use the [main Apio repository](https://github.com/FPGAwars/apio).

Apio package with selected binaries from the [YosysHQ/oss-cad-suite project](https://github.com/YosysHQ/oss-cad-suite-build)



## Parts indexes

Every package carries four documents at its root, generated at build time
from the databases inside the package itself (see
`.github/workflows/parts_indexes.py`): `ICE40-PARTS-INDEX.json`,
`ECP5-PARTS-INDEX.json`, `GOWIN-PARTS-INDEX.json` and `MACHXO2-PARTS-INDEX.json`
(catalog only). Each one lists the parts the packaged toolchain can serve; for
ice40, ecp5 and gowin every part carries a `default-definition`, the object
for the apio `fpgas.jsonc` entry with the same key.

The generator has tests, which the builder does not run:

```
OSS_CAD_SUITE_DIR=<an unpacked oss-cad-suite for this platform> \
APIO_DEFINITIONS_DIR=<clone of FPGAwars/apio-definitions> \
python -m pytest tests/ -v
```

## License

The Apio project itself is licensed under the GNU General Public License version 3.0 (GPL-3.0).
Pre-built packages may include third-party tools and components, which are subject to their
respective license terms.
