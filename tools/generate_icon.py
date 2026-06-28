"""
くますず アプリアイコン生成
bear_bell_icon.dart の形状を正確に再現（音波なし・適切なスケール）
"""
import math
from PIL import Image, ImageDraw

SIZE = 1024
BG        = (13, 13, 13)
GOLD      = (255, 215, 0)
GOLD_DARK = (160, 120, 0)
EAR_INNER = (255, 235, 130)  # 半透明ゴールドをBG混合した色

def cubic_bezier(p0, p1, p2, p3, steps=100):
    pts = []
    for i in range(steps + 1):
        t = i / steps
        u = 1 - t
        x = u**3*p0[0] + 3*u**2*t*p1[0] + 3*u*t**2*p2[0] + t**3*p3[0]
        y = u**3*p0[1] + 3*u**2*t*p1[1] + 3*u*t**2*p2[1] + t**3*p3[1]
        pts.append((x, y))
    return pts

def quad_bezier(p0, p1, p2, steps=50):
    pts = []
    for i in range(steps + 1):
        t = i / steps
        u = 1 - t
        x = u**2*p0[0] + 2*u*t*p1[0] + t**2*p2[0]
        y = u**2*p0[1] + 2*u*t*p1[1] + t**2*p2[1]
        pts.append((x, y))
    return pts

def circle(draw, cx, cy, r, color):
    draw.ellipse([cx-r, cy-r, cx+r, cy+r], fill=color)

def draw_icon(size=SIZE):
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))

    # 角丸背景
    bg = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    ImageDraw.Draw(bg).rounded_rectangle(
        [0, 0, size-1, size-1], radius=int(size*0.22), fill=(*BG, 255))
    img.alpha_composite(bg)

    draw = ImageDraw.Draw(img)

    # ── ベルをアイコン内に収めるため80%スケールで中央配置 ──
    pad  = size * 0.10   # 上下左右パディング
    s    = size - pad * 2
    ox   = pad           # 原点オフセット
    oy   = pad

    def p(rx, ry):
        """相対座標 → 絶対座標"""
        return (ox + rx * s, oy + ry * s)

    w, h = s, s

    # ── ベル本体ポリゴン（Dartパスと同じ制御点）──
    bell = []
    bell += cubic_bezier(p(0.50,0.10), p(0.20,0.10), p(0.08,0.38), p(0.08,0.62))
    bell.append(p(0.08, 0.68))
    bell += quad_bezier(p(0.08,0.68), p(0.08,0.76), p(0.18,0.76))
    bell.append(p(0.82, 0.76))
    bell += quad_bezier(p(0.82,0.76), p(0.92,0.76), p(0.92,0.68))
    bell.append(p(0.92, 0.62))
    bell += cubic_bezier(p(0.92,0.62), p(0.92,0.38), p(0.80,0.10), p(0.50,0.10))
    draw.polygon(bell, fill=(*GOLD, 255))

    # 横棒
    bx1, by1 = p(0.06, 0.74)
    bx2, by2 = p(0.06+0.88, 0.74+0.07)
    draw.rounded_rectangle([bx1, by1, bx2, by2],
                            radius=int(w*0.04), fill=(*GOLD, 255))

    # ── 熊の耳 ──
    ear_r  = w * 0.13
    ear_ri = w * 0.07
    for rx, ry in [(0.20, 0.18), (0.80, 0.18)]:
        ex, ey = p(rx, ry)
        circle(draw, ex, ey, ear_r, (*GOLD, 255))
        circle(draw, ex, ey, ear_ri, (*EAR_INNER, 255))

    # ── ハンガー（頂上の弧）──
    # center=(w*0.50, h*0.10), rx=w*0.09, ry=h*0.07
    # Flutter: start=π, sweep=π (時計回り y-down) = 下半楕円 = 逆U字
    hcx, hcy = p(0.50, 0.10)
    hrx = w * 0.09
    hry = h * 0.07
    hang_lw = int(w * 0.06)
    # PIL: start=180°→360° clockwise = 下半分の弧
    draw.arc(
        [hcx-hrx, hcy-hry, hcx+hrx, hcy+hry],
        start=180, end=360,
        fill=(*GOLD, 255), width=hang_lw
    )

    # ── クラッパー（振り子） ──
    clx, cly = p(0.50, 0.84)
    circle(draw, clx, cly, w*0.07, (*GOLD, 255))

    # ── 角丸マスクで切り抜き ──
    mask = Image.new("L", (size, size), 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        [0, 0, size-1, size-1], radius=int(size*0.22), fill=255)
    out = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    out.paste(img, mask=mask)
    return out

icon = draw_icon(SIZE)
icon.save("assets/icon/app_icon.png")
print("OK: app_icon.png")

splash = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
ls  = int(SIZE * 0.54)
off = (SIZE - ls) // 2
logo = draw_icon(ls)
splash.paste(logo, (off, off), logo)
splash.save("assets/splash/splash_logo.png")
print("OK: splash_logo.png")
