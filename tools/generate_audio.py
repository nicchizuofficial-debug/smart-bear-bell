"""
WAV音声ファイル生成
 - bell.wav      : 熊鈴（倍音構成 + 緩やかな減衰）
 - iron_bell.wav : 鉄鈴（高音・短い減衰・金属感）
 - electronic.wav: 電子音（3連チャープ）
 - repel.wav     : 緊急撃退サイレン
"""
import wave, struct, math, os

SAMPLE_RATE = 44100

def write_wav(path, samples):
    with wave.open(path, 'w') as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(SAMPLE_RATE)
        for s in samples:
            val = max(-1.0, min(1.0, s))
            f.writeframes(struct.pack('<h', int(val * 32767)))

def sine(freq, t):
    return math.sin(2 * math.pi * freq * t)

# ── 熊鈴（まろやかな倍音 + 長めの余韻）──
def generate_bell():
    dur = 2.0
    harmonics = [(880, 0.50), (1320, 0.25), (1760, 0.15), (2640, 0.10)]
    samples = []
    for i in range(int(SAMPLE_RATE * dur)):
        t = i / SAMPLE_RATE
        env = (t / 0.005) if t < 0.005 else math.exp(-(t - 0.005) / 0.7)
        s = sum(v * sine(f, t) for f, v in harmonics) * env
        samples.append(s * 0.85)
    return samples

# ── 鉄鈴（高音・短い金属音）──
def generate_iron_bell():
    dur = 1.5
    harmonics = [(1200, 0.55), (2400, 0.25), (3600, 0.12), (4800, 0.08)]
    samples = []
    for i in range(int(SAMPLE_RATE * dur)):
        t = i / SAMPLE_RATE
        env = (t / 0.003) if t < 0.003 else math.exp(-(t - 0.003) / 0.35)
        s = sum(v * sine(f, t) for f, v in harmonics) * env
        samples.append(s * 0.80)
    return samples

# ── 電子音（3連チャープ: 周波数が上昇）──
def generate_electronic():
    dur = 1.8
    samples = []
    chirp_len   = 0.18   # チャープ1つの長さ（秒）
    gap_len     = 0.08   # チャープ間の無音
    chirp_count = 3
    cycle = chirp_len + gap_len

    for i in range(int(SAMPLE_RATE * dur)):
        t = i / SAMPLE_RATE
        phase = t % cycle
        chirp_idx = int(t / cycle)
        if phase < chirp_len and chirp_idx < chirp_count:
            # チャープ内で 900→1600 Hzへ上昇
            sweep = phase / chirp_len
            freq = 900 + 700 * sweep
            # エンベロープ: チャープ前後を滑らか
            env = math.sin(math.pi * sweep)
            s = 0.75 * sine(freq, t) + 0.15 * sine(freq * 2, t)
            samples.append(s * env)
        else:
            samples.append(0.0)
    return samples

# ── 撃退サイレン（2音交互スウィープ）──
def generate_repel():
    dur = 2.5
    samples = []
    sweep_period = 0.12
    for i in range(int(SAMPLE_RATE * dur)):
        t = i / SAMPLE_RATE
        phase = (t % sweep_period) / sweep_period
        freq = 800 + 600 * phase if int(t / sweep_period) % 2 == 0 else 1400 - 600 * phase
        s = 0.7 * sine(freq, t) + 0.2 * sine(freq * 3, t) + 0.1 * sine(freq * 5, t)
        env = min(1.0, t / 0.03)
        samples.append(s * env * 0.90)
    return samples

os.makedirs('assets/audio', exist_ok=True)

write_wav('assets/audio/bell.wav',       generate_bell())
print('OK: bell.wav')
write_wav('assets/audio/iron_bell.wav',  generate_iron_bell())
print('OK: iron_bell.wav')
write_wav('assets/audio/electronic.wav', generate_electronic())
print('OK: electronic.wav')
write_wav('assets/audio/repel.wav',      generate_repel())
print('OK: repel.wav')
