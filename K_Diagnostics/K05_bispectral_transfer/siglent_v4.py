# K05 contribution history (Git author dates; edit times include timezone).
# 2026-10-28 16:37 +08:00 | Yinjian Zhao | git 288e21275be3
# 2026-11-18 16:11 +08:00 | Yinjian Zhao | edit (Codex-assisted)

"""Strict reader for single-channel, unzoomed SIGLENT V4 voltage captures.

Source: SIGLENT, How to Extract Data from the Binary File, EN03A (2024),
V4.0 tables pp. 38-46. The header is little-endian; payload endian is explicit.
Unsupported layouts fail instead of silently producing plausible waveforms.
"""
from pathlib import Path
import hashlib
import struct

import numpy as np


def read_capture(path, offset_sign=None):
    """Return (metadata, voltage); default to record-centred fluctuations.

    The supplied lab reader subtracts the vertical offset, whereas EN03A adds
    it. Default centring avoids assuming an unverified DC calibration. Explicit
    +1/-1 selects a candidate DC convention for independent calibration checks.
    """
    path = Path(path)
    with path.open("rb") as stream:
        h = stream.read(4096)
    if len(h) != 4096:
        raise ValueError("Truncated header")
    u32 = lambda offset: struct.unpack_from("<I", h, offset)[0]
    f64 = lambda offset: struct.unpack_from("<d", h, offset)[0]

    def quantity(offset, unit=None):
        magnitude = u32(offset + 8)
        if magnitude > 16:
            raise ValueError("Unknown magnitude index")
        if unit is not None and struct.unpack_from("<7i", h, offset + 12) != unit:
            raise ValueError("Unsupported physical unit in capture header")
        return f64(offset) * 10.0 ** (3 * (magnitude - 8))

    volt = (0, 1, 1, 0, 1, 0, 1)
    second = (0, 0, 1, 0, 1, 1, 1)
    if u32(0) != 4 or u32(4) != 4096:
        raise ValueError("Only the 4096-byte V4 header is supported")
    enabled = [j for j in range(4) if u32(8 + 4*j)]
    if len(enabled) != 1 or u32(0x158) or any(u32(0x280 + 4*j) for j in range(4)):
        raise ValueError("Expected one analog channel, no math/digital payload")
    if any(u32(0x664 + 4*j) for j in range(4)) or u32(0xAF4):
        raise ValueError("Memory/zoom captures are not supported")
    if h[0x264] not in (0, 1) or h[0x265] not in (0, 1):
        raise ValueError("Unknown payload width/endian")
    channel = enabled[0]
    width = (8, 16)[h[0x264]]
    n = u32(0x1EC)
    if path.stat().st_size != 4096 + n * (width // 8):
        raise ValueError("Payload length does not match the header")
    fs = quantity(0x1F0)
    vdiv = quantity(0x18 + 40*channel, volt)
    offset = quantity(0xB8 + 40*channel, volt)
    codes_per_div = u32(0x270 + 4*channel)
    tdiv = quantity(0x19C, second)
    delay = quantity(0x1C4, second)
    probe = f64(0x244 + 8*channel)
    if probe != 1:
        raise ValueError("This reader requires probe factor 1; verify other scaling first")
    if not (n > 0 and fs > 0 and vdiv > 0 and codes_per_div > 0):
        raise ValueError("Nonpositive capture scale")
    if not np.isclose(n/fs, u32(0x26C)*tdiv, rtol=1e-6):
        raise ValueError("Record duration differs from timebase; inspect acquisition mode")
    dtype = ("<" if h[0x265] == 0 else ">") + ("u1" if width == 8 else "u2")
    codes = np.fromfile(path, dtype=dtype, offset=4096)
    code_voltage = (codes.astype(np.float64) - 2**(width-1)) * vdiv/codes_per_div
    code_mean = float(code_voltage.mean())
    if offset_sign not in (None, -1, 1):
        raise ValueError("offset_sign must be None, -1 or +1")
    voltage = code_voltage-code_mean if offset_sign is None else code_voltage+offset_sign*offset
    meta = dict(file=path.name, sha256=hashlib.sha256(path.read_bytes()).hexdigest(),
                version=4, channel=channel+1, samples=n, fs_hz=fs,
                duration_s=n/fs, dt_s=1/fs, nyquist_hz=fs/2,
                storage_bits=width, payload_endian="little" if h[0x265] == 0 else "big",
                v_per_div=vdiv, offset_v=offset, codes_per_div=codes_per_div,
                probe_factor=probe, t_start_s=-tdiv*u32(0x26C)/2-delay,
                voltage_reference="record mean" if offset_sign is None else "candidate DC convention",
                offset_sign=offset_sign, dc_level_verified=False,
                code_centered_mean_v=code_mean,
                mean_v_if_add_offset=code_mean+offset,
                mean_v_if_subtract_offset=code_mean-offset,
                displayed_mean_v=float(voltage.mean()), std_v=float(voltage.std()),
                min_v=float(voltage.min()), max_v=float(voltage.max()),
                min_code=int(codes.min()), max_code=int(codes.max()),
                storage_rail_count=int(np.sum((codes == 0) | (codes == 2**width-1))))
    return meta, voltage
