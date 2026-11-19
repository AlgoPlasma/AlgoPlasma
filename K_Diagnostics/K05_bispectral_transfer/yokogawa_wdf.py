# K05 contribution history (Git author dates; edit times include timezone).
# 2026-10-29 13:23 +08:00 | Yinjian Zhao | git 5604a5bb51cc
# 2026-11-18 16:11 +08:00 | Yinjian Zhao | edit (Codex-assisted)

"""Read the DL350 single-history Trace layout documented in IM DL350-01EN App. 9.

Only the layout used by the K05 sweep records is supported. Unsupported histories,
time offsets, types and truncated data fail explicitly instead of guessing scales.
"""
from pathlib import Path
import hashlib
import struct

import numpy as np


def read_wdf(path):
    path = Path(path)
    data = path.read_bytes()
    if data[:4] != b"%WDF" or len(data) < 64:
        raise ValueError("Not a complete WDF header")
    pos = struct.unpack_from(">I", data, 4)[0]
    if pos < 12 or pos > len(data):
        raise ValueError("Invalid common-header size")
    chunks = []
    while pos < len(data):
        if pos + 16 > len(data):
            raise ValueError("Truncated chunk header")
        kind, size = struct.unpack_from(">4sQ", data, pos)
        end = pos + 12 + size
        if end + 4 > len(data):
            raise ValueError("Truncated chunk payload")
        chunks.append((kind, pos + 12, end))
        pos = end + 4
        if kind == b"FeND":
            break
    if pos != len(data) or not chunks or chunks[-1][0] != b"FeND":
        raise ValueError("Expected one complete file ending in FeND")
    headers = [data[a:b] for kind, a, b in chunks if kind == b"XHDR"]
    if len(headers) != 1:
        raise ValueError("Expected one XHDR analysis header")
    header_text = headers[0].decode("ascii")
    sections = {}
    section = None
    for line in header_text.splitlines():
        fields = line.split()
        if not fields or fields[0].startswith("//"):
            continue
        if fields[0].startswith("$"):
            section = sections.setdefault(fields[0], {})
        elif section is not None:
            section[fields[0]] = fields[1:]
    public = sections["$PublicInfo"]
    private = sections["$PrivateInfo"]
    if public["Model"] != ["DL350"] or public["DataFormat"] != ["Trace"]:
        raise ValueError("Only DL350 Trace layout is supported")
    if public["Endian"] != ["Big"]:
        raise ValueError("Expected documented big-endian data")
    if any(float(x) != 0 for x in private.get("StartOffset1", [])):
        raise ValueError("Nonzero channel start offsets are not supported")
    pos = int(public["DataOffset"][0])
    raw_chunks = [(a, b) for kind, a, b in chunks if kind == b"DrAW"]
    if len(raw_chunks) != 1 or pos != raw_chunks[0][0] + 8:
        raise ValueError("Expected one DrAW chunk with an eight-byte prefix")
    traces = {}
    for gi in range(1, int(public["GroupNumber"][0]) + 1):
        group = sections[f"$Group{gi}"]
        if group["BlockNumber"] != ["1"]:
            raise ValueError("Multiple histories are not supported")
        count = int(group["TraceNumber"][0])
        keys = ("TraceName", "BlockSize", "VDataType", "VResolution", "VOffset",
                "VIllegalData", "VUnit", "HResolution", "HOffset", "HUnit")
        if any(len(group[k]) != count for k in keys):
            raise ValueError("Inconsistent per-trace metadata")
        for i, name in enumerate(group["TraceName"]):
            if name in traces or group["VDataType"][i] != "IS2":
                raise ValueError("Expected unique signed 16-bit traces")
            n = int(group["BlockSize"][i])
            if n <= 0 or pos + 2*n > raw_chunks[0][1]:
                raise ValueError("Trace exceeds DrAW payload")
            codes = np.frombuffer(data, dtype=">i2", count=n, offset=pos)
            pos += 2*n
            resolution = float(group["VResolution"][i])
            offset = float(group["VOffset"][i])
            values = codes.astype(float)*resolution + offset
            illegal = group["VIllegalData"][i]
            if illegal != "?":
                values[codes == int(illegal)] = np.nan
            dt = float(group["HResolution"][i])
            if dt <= 0 or group["HUnit"][i] != "s":
                raise ValueError("Expected a positive time interval in seconds")
            traces[name] = dict(values=values, dt_s=dt,
                                t0_s=float(group["HOffset"][i]), unit=group["VUnit"][i],
                                resolution=resolution, offset=offset,
                                invalid_count=int(np.isnan(values).sum()))
    if pos != raw_chunks[0][1] or len(traces) != int(public["TraceTotalNumber"][0]):
        raise ValueError("Raw size or trace count mismatch")
    return dict(file=path.name, sha256=hashlib.sha256(data).hexdigest(),
                model=public["Model"][0], header_text=header_text,
                trigger_time=" ".join(private.get("TrigTime1", [])), traces=traces)
