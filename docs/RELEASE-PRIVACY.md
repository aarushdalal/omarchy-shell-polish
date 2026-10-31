# Release privacy

Current release files use portable paths. The dated desktop showcase is the user-supplied recording selected for publication, with its soundtrack retained and container metadata removed. Its poster and short README animation derive from the same recording. The session-component image remains a sample-data layout fixture. Runtime logs, credentials and Git metadata copies are not release assets.

The showcase depicts the configured desktop rather than claiming that every visible tool or artwork is supplied by this repository. Reviewed media is recorded by SHA-256 in tools/approved-preview-media.json. The older SVG remains an illustration asset, while the current gallery plays the dated recording.

Existing Git history is preserved. Historical commits and media may retain older
metadata; this cleanup does not remove previously published copies. New commits use
a GitHub noreply address. Public repository URLs, stable plugin IDs and license
attribution remain as intentional project provenance.

Run `python3 tools/release_privacy_check.py` before publication. It scans the current
payload and rejects operational identity, credentials and unreviewed showcase media.
It is a release gate, not proof that arbitrary third-party files contain no secrets.
