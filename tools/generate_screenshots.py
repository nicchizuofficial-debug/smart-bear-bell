"""
App Store スクリーンショット生成 (1284x2778px, RGB)
絵文字を描画で代替、中央コンテンツを充実
"""
import os, math
from PIL import Image, ImageDraw, ImageFont

W, H = 1284, 2778
BG        = (13,  13,  13)
GOLD      = (255, 215,   0)
GOLD_DIM  = (120, 100,   0)
RED       = (180,  20,  20)
RED_L     = (220,  40,  40)
CARD      = ( 22,  22,  22)
CARD2     = ( 28,  22,   0)
BORDER    = ( 48,  48,  48)
BORDER_G  = ( 80,  60,   0)
WHITE     = (255, 255, 255)
GREY      = (140, 140, 140)
GREY_D    = ( 70,  70,  70)
GREEN     = ( 68, 170,  68)
BLUE      = (  0, 136, 255)
ORANGE    = (255, 100,  20)

FONT_R  = r"C:\Windows\Fonts\BIZ-UDGothicR.ttc"
FONT_B  = r"C:\Windows\Fonts\BIZ-UDGothicB.ttc"
FONT_KO = r"C:\Windows\Fonts\NanumGothic-Regular.ttf"

def f(size, bold=False):
    try: return ImageFont.truetype(FONT_B if bold else FONT_R, size)
    except: return ImageFont.load_default()

def fko(size):
    try: return ImageFont.truetype(FONT_KO, size)
    except: return f(size)

def new_img():
    img = Image.new("RGB", (W, H), BG)
    d   = ImageDraw.Draw(img)
    return img, d

def rr(d, xy, r, fill=None, outline=None, width=2):
    x1,y1,x2,y2 = xy
    if fill:    d.rounded_rectangle([x1,y1,x2,y2], radius=r, fill=fill)
    if outline: d.rounded_rectangle([x1,y1,x2,y2], radius=r, outline=outline, width=width)

def tc(d, y, txt, font, color=WHITE):
    bb = d.textbbox((0,0), txt, font=font)
    tw = bb[2]-bb[0]
    d.text(((W-tw)//2, y), txt, font=font, fill=color)

# ── アイコン描画ユーティリティ ──
def draw_bear_icon(d, cx, cy, s):
    # 耳
    for ex, ey in [(cx-int(s*0.30), cy-int(s*0.30)),
                   (cx+int(s*0.30), cy-int(s*0.30))]:
        d.ellipse([ex-int(s*0.14),ey-int(s*0.14),ex+int(s*0.14),ey+int(s*0.14)], fill=GOLD)
        d.ellipse([ex-int(s*0.08),ey-int(s*0.08),ex+int(s*0.08),ey+int(s*0.08)], fill=(180,140,0))
    # 本体
    d.ellipse([cx-int(s*0.38),cy-int(s*0.28),cx+int(s*0.38),cy+int(s*0.34)], fill=GOLD)
    # 底横棒
    d.rounded_rectangle([cx-int(s*0.38),cy+int(s*0.26),cx+int(s*0.38),cy+int(s*0.34)],
                        radius=int(s*0.04), fill=(200,168,0))
    # クラッパー
    cr = int(s*0.08)
    d.ellipse([cx-cr,cy+int(s*0.38)-cr,cx+cr,cy+int(s*0.38)+cr], fill=(180,140,0))

def draw_shield(d, cx, cy, s, color=GREEN):
    pts = [
        (cx, cy-s), (cx+s*0.8, cy-s*0.4),
        (cx+s*0.8, cy+s*0.2), (cx, cy+s),
        (cx-s*0.8, cy+s*0.2), (cx-s*0.8, cy-s*0.4),
    ]
    d.polygon(pts, fill=color)
    # チェック
    lw = max(3, int(s*0.1))
    d.line([(cx-s*0.3,cy+s*0.1),(cx-s*0.05,cy+s*0.4),(cx+s*0.45,cy-s*0.25)],
           fill=WHITE, width=lw)

def draw_warn(d, cx, cy, s, color=ORANGE):
    pts = [(cx, cy-s),(cx+s*0.9,cy+s*0.7),(cx-s*0.9,cy+s*0.7)]
    d.polygon(pts, fill=color)
    d.rectangle([cx-int(s*0.07),cy-int(s*0.35),cx+int(s*0.07),cy+int(s*0.25)],
                fill=(30,20,0))
    d.ellipse([cx-int(s*0.08),cy+int(s*0.35)-int(s*0.08),
               cx+int(s*0.08),cy+int(s*0.35)+int(s*0.08)], fill=(30,20,0))

def draw_map_icon(d, cx, cy, s, color=BLUE):
    # 地図ピン
    d.ellipse([cx-int(s*0.5),cy-int(s*0.8),cx+int(s*0.5),cy+int(s*0.2)], fill=color)
    d.ellipse([cx-int(s*0.25),cy-int(s*0.55),cx+int(s*0.25),cy-int(s*0.05)], fill=BG)
    # 下の点
    d.polygon([(cx-int(s*0.5),cy+int(s*0.05)),(cx+int(s*0.5),cy+int(s*0.05)),(cx,cy+int(s*0.8))],
              fill=color)

def draw_wave_icon(d, cx, cy, s, color=GOLD):
    # 音波3本
    for i, r_frac in enumerate([0.4,0.65,0.9]):
        r = int(s*r_frac)
        a = d.arc
        lw = max(2, int(s*0.07))
        d.arc([cx-r,cy-r,cx+r,cy+r], start=-60, end=60, fill=color, width=lw)
        d.arc([cx-r,cy-r,cx+r,cy+r], start=120, end=240, fill=color, width=lw)

def draw_globe(d, cx, cy, s, color=BLUE):
    # 地球（円 + 経線）
    d.ellipse([cx-s,cy-s,cx+s,cy+s], outline=color, width=max(2,int(s*0.07)))
    d.line([(cx, cy-s),(cx, cy+s)], fill=color, width=max(2,int(s*0.07)))
    d.arc([cx-s//2,cy-s,cx+s//2,cy+s], start=0, end=180, fill=color, width=max(2,int(s*0.07)))
    d.arc([cx-s//2,cy-s,cx+s//2,cy+s], start=180, end=360, fill=color, width=max(2,int(s*0.07)))
    d.line([(cx-s,cy),(cx+s,cy)], fill=color, width=max(2,int(s*0.07)))

def draw_bell_simple(d, cx, cy, s, color=GOLD):
    d.ellipse([cx-int(s*0.35),cy-int(s*0.28),cx+int(s*0.35),cy+int(s*0.30)], fill=color)
    d.rounded_rectangle([cx-int(s*0.35),cy+int(s*0.22),cx+int(s*0.35),cy+int(s*0.30)],
                        radius=int(s*0.05), fill=(200,168,0))
    cr = int(s*0.08)
    d.ellipse([cx-cr,cy+int(s*0.34)-cr,cx+cr,cy+int(s*0.34)+cr], fill=(180,140,0))

def draw_status_bar(d):
    d.rectangle([0,0,W,80], fill=(10,10,10))
    d.text((60,22), "9:41", font=f(38,True), fill=WHITE)
    bx = W-120
    d.rounded_rectangle([bx,24,bx+70,52], radius=6, outline=GREY, width=3)
    d.rounded_rectangle([bx+70,34,bx+76,44], radius=2, fill=GREY)
    d.rounded_rectangle([bx+4,28,bx+52,48], radius=4, fill=GREEN)
    # WiFi (3本線)
    for i,r2 in enumerate([8,16,24]):
        d.arc([bx-60-r2,36-r2//2,bx-60+r2,36+r2//2], start=200, end=340,
              fill=GREEN if i<2 else GREY, width=3)

def draw_header(d, subtitle="くますず"):
    draw_status_bar(d)
    y = 100
    draw_bear_icon(d, 82, y+36, 52)
    d.text((146, y+8),  "Smart Bear Bell", font=f(46,True), fill=WHITE)
    d.text((148, y+62), subtitle, font=f(28), fill=GREY)

def draw_bell_card(d, enabled=True, y1=280):
    x1,y2 = 40, y1+140
    fill   = CARD2 if enabled else CARD
    border = BORDER_G if enabled else BORDER
    rr(d,[x1,y1,W-40,y2],28,fill=fill,outline=border,width=3)
    ix,iy = 78, y1+28
    rr(d,[ix,iy,ix+84,iy+84],18,fill=(42,32,0) if enabled else (28,28,28))
    draw_bear_icon(d, ix+42, iy+42, 48)
    tx = 184
    d.text((tx,y1+28), "予防モード（スマート鈴）", font=f(34,True), fill=WHITE if enabled else (80,80,80))
    d.text((tx,y1+76), "歩行中に自動で音を鳴らします" if enabled else "オフ",
           font=f(26), fill=GOLD if enabled else GREY_D)
    # トグル
    toggle_x = W-112
    toggle_y = y1+70
    if enabled:
        d.rounded_rectangle([toggle_x-58,toggle_y-22,toggle_x+58,toggle_y+22],radius=22,fill=GOLD)
        d.ellipse([toggle_x+14,toggle_y-18,toggle_x+50,toggle_y+18],fill=(20,20,20))
    else:
        d.rounded_rectangle([toggle_x-58,toggle_y-22,toggle_x+58,toggle_y+22],radius=22,fill=(50,50,50))
        d.ellipse([toggle_x-50,toggle_y-18,toggle_x-14,toggle_y+18],fill=GREY)

def draw_risk_card(d, high=False, y1=440):
    y2 = y1+140
    rr(d,[40,y1,W-40,y2],28,fill=CARD,outline=BORDER,width=2)
    level_c = ORANGE if high else GREEN
    label   = "高め" if high else "低め"
    # シールドアイコン
    draw_shield(d, 80, y1+50, 26, color=level_c)
    d.text((120,y1+22), "現在の危険度", font=f(32), fill=GREY)
    d.text((W-160,y1+22), label, font=f(34,True), fill=level_c)
    bx1,bx2 = 60, W-60
    by = y1+88
    d.rounded_rectangle([bx1,by,bx2,by+14],radius=7,fill=(42,42,42))
    lvl = 0.72 if high else 0.35
    d.rounded_rectangle([bx1,by,bx1+int((bx2-bx1)*lvl),by+14],radius=7,fill=level_c)
    msg = "夜明け・夕暮れはクマが活発です。予防モードをONに。" if high else "現在の時間帯は比較的安全です。"
    d.text((60,y1+116), msg, font=f(24), fill=GREY_D)

def draw_emergency_btn(d, active=False):
    x1,y1 = 40, H-230
    x2,y2 = W-40, H-60
    if active:
        rr(d,[x1,y1,x2,y2],36,fill=RED_L)
        rr(d,[x1-8,y1-8,x2+8,y2+8],42,outline=RED,width=8)
        # 警告三角
        draw_warn(d, W//2-240, y1+90, 38, color=(255,200,80))
        tc(d, y1+52, "撃退中", f(58,True), WHITE)
        tc(d, y1+126, "タップして停止", f(36), (255,200,200))
    else:
        rr(d,[x1,y1,x2,y2],36,fill=RED)
        draw_warn(d, W//2-240, y1+90, 38)
        tc(d, y1+52, "緊急撃退モード", f(52,True), WHITE)
        tc(d, y1+118, "強く振る / 長押しで発動", f(30), (255,180,180))

# ── Feature card (3列) ──
def draw_feature_cards(d, y_start):
    items = [
        (draw_bell_simple, GOLD,  "スマート鈴音",  "歩行検知で自動ON"),
        (draw_map_icon,    BLUE,  "ミュートエリア","自宅周辺は静音"),
        (draw_globe,       GREEN, "多言語対応",    "日英中韓"),
    ]
    card_w = (W - 80) // 3
    for i,(icon_fn, color, title, sub) in enumerate(items):
        cx = 40 + i*card_w + card_w//2
        x1 = 40 + i*card_w + 8
        x2 = x1 + card_w - 16
        rr(d,[x1,y_start,x2,y_start+240],24,fill=CARD,outline=BORDER,width=2)
        icon_fn(d, cx, y_start+70, 34, color)
        # タイトル
        bb = d.textbbox((0,0),title,font=f(26,True))
        tw = bb[2]-bb[0]
        d.text((cx-tw//2, y_start+126), title, font=f(26,True), fill=WHITE)
        bb2 = d.textbbox((0,0),sub,font=f(22))
        tw2 = bb2[2]-bb2[0]
        d.text((cx-tw2//2, y_start+162), sub, font=f(22), fill=GREY)

# ── Screenshot 1: メイン画面 ──
def ss_main():
    img,d = new_img()
    for y in range(H):
        t = y/H
        r = int(26*(1-t)+13*t); g = int(18*(1-t)+13*t)
        d.line([(0,y),(W,y)], fill=(r,g,13))
    draw_header(d)
    draw_bell_card(d, enabled=True)
    draw_risk_card(d, high=False)
    # 特徴カード
    draw_feature_cards(d, 610)
    # 音波ビジュアル
    cy_wave = 1020
    for i,r2 in enumerate([60,100,145,195]):
        alpha_col = [120,80,50,25][i]
        d.ellipse([W//2-r2, cy_wave-r2, W//2+r2, cy_wave+r2],
                  outline=(255,215,0,alpha_col), width=3)
    draw_bear_icon(d, W//2, cy_wave, 60)
    tc(d, 1110, "歩行を感知すると自動で鈴が鳴ります", f(32), GOLD)
    # 統計バナー
    stats_y = 1200
    rr(d,[40,stats_y,W-40,stats_y+200],28,fill=CARD,outline=BORDER,width=2)
    for i,(num,label,color) in enumerate([
        ("2,500+","年間目撃件数",ORANGE),
        ("88%","市街地での発生",RED_L),
        ("0","遭遇回避 目標",GREEN)]):
        sx = 40 + (W-80)//3*i + (W-80)//6
        d.text((sx-50,stats_y+28), num, font=f(48,True), fill=color)
        bb = d.textbbox((0,0),label,font=f(24))
        d.text((sx-bb[2]//2,stats_y+92), label, font=f(24), fill=GREY)
    draw_emergency_btn(d, active=False)
    return img

# ── Screenshot 2: 緊急撃退モード ──
def ss_emergency():
    img,d = new_img()
    for y in range(H):
        t = y/H
        r = int(44*(1-t)+13*t)
        d.line([(0,y),(W,y)], fill=(r,13,13))
    draw_header(d)
    # SOSバナー
    rr(d,[40,252,W-40,320],16,fill=(40,10,10),outline=(150,30,30),width=2)
    tc(d, 268, "GPS座標付きSOSを連絡先に送信しました", f(26), (255,140,140))
    draw_bell_card(d, enabled=True, y1=340)
    draw_risk_card(d, high=True, y1=500)
    # 発動ビジュアル: 同心円パルス
    cy_p = 1100
    for i,r2 in enumerate([200,155,115,80]):
        alpha = [18,30,50,80][i]
        d.ellipse([W//2-r2,cy_p-r2,W//2+r2,cy_p+r2], fill=(180,20,20))
    draw_bear_icon(d, W//2, cy_p, 80)
    # サイレン波
    for r2 in [240,285,330]:
        d.arc([W//2-r2,cy_p-r2,W//2+r2,cy_p+r2], 0, 360, fill=(100,0,0), width=4)
    tc(d, 1260, "スマホを振るだけで緊急モード自動発動", f(30), (255,120,120))
    # 機能説明
    feat_y = 1360
    rr(d,[40,feat_y,W-40,feat_y+360],28,fill=CARD,outline=(80,20,20),width=2)
    for i,(icon_fn, color, title, sub) in enumerate([
        (draw_warn,       ORANGE,  "自動シェイク検知",  "強い振動を感知して即発動"),
        (draw_bell_simple,RED_L,   "撃退音サイレン",    "クマを追い払う高音を再生"),
        (draw_map_icon,   (200,80,80), "SOS送信",      "GPS座標を連絡先に通知"),
    ]):
        fy = feat_y + 30 + i*110
        icon_fn(d, 100, fy+35, 26, color)
        d.text((160, fy+16), title, font=f(32,True), fill=WHITE)
        d.text((160, fy+58), sub, font=f(26), fill=GREY)
        if i<2: d.rectangle([60,fy+98,W-60,fy+100], fill=BORDER)
    draw_emergency_btn(d, active=True)
    return img

# ── Screenshot 3: 設定画面 ──
def ss_settings():
    img,d = new_img()
    d.rectangle([0,0,W,160], fill=(26,26,26))
    d.rectangle([0,158,W,162], fill=BORDER)
    draw_status_bar(d)
    d.text((80,96), "<", font=f(52), fill=WHITE)
    tc(d, 100, "設定", f(46,True), WHITE)

    y = 190
    def section(label, yy):
        d.text((56,yy), label, font=f(34,True), fill=GOLD)
        return yy+58

    # 言語
    y = section("言語", y)
    langs = [("日本語",True,False),("English",False,False),("中文",False,False),("한국어",False,True)]
    lx = 56
    for name, sel, is_ko in langs:
        fnt = fko(32) if is_ko else (f(32,True) if sel else f(30))
        bb = d.textbbox((0,0),name,font=fnt)
        ww = bb[2]-bb[0]+40
        bg = GOLD if sel else (30,30,30)
        fc = (0,0,0) if sel else WHITE
        rr(d,[lx,y,lx+ww,y+64],14,fill=bg)
        d.text((lx+18,y+14), name, font=fnt, fill=fc)
        lx += ww+14
    y += 92
    d.rectangle([40,y,W-40,y+2],fill=BORDER); y+=44

    # 鈴音の種類
    y = section("鈴音の種類", y)
    sounds = [("熊鈴",True),("鉄鈴",False),("電子音",False)]
    lx = 56
    for name, sel in sounds:
        ww = len(name)*34+48
        rr(d,[lx,y,lx+ww,y+70],16,fill=GOLD if sel else (30,30,30))
        d.text((lx+18,y+16), name, font=f(34,True) if sel else f(32),
               fill=(0,0,0) if sel else WHITE)
        lx += ww+18
    y += 100

    # 試聴
    rr(d,[56,y,W-56,y+84],16,outline=GOLD,width=2)
    # 再生三角形
    pts = [(176,y+22),(176,y+62),(218,y+42)]
    d.polygon(pts, fill=GOLD)
    tc(d, y+26, "試聴する", f(36), GOLD)
    y += 116
    d.rectangle([40,y,W-40,y+2],fill=BORDER); y+=44

    # 音量
    y = section("音量", y)
    d.text((W-156,y-58), "70%", font=f(36,True), fill=GOLD)
    bx1,bx2,by = 56,W-56,y+12
    d.rounded_rectangle([bx1,by,bx2,by+14],radius=7,fill=(50,50,50))
    fill_end = bx1+int((bx2-bx1)*0.70)
    d.rounded_rectangle([bx1,by,fill_end,by+14],radius=7,fill=GOLD)
    d.ellipse([fill_end-20,by-10,fill_end+20,by+24],fill=GOLD)
    y += 88
    d.rectangle([40,y,W-40,y+2],fill=BORDER); y+=44

    # SOS連絡先
    y = section("緊急SOS連絡先", y)
    for label,val in [("名前","山田 太郎"),("電話番号","090-XXXX-XXXX")]:
        rr(d,[56,y,W-56,y+94],16,fill=(26,26,26),outline=BORDER,width=2)
        d.text((82,y+14), label, font=f(26), fill=GREY)
        d.text((82,y+50), val, font=f(34), fill=WHITE)
        y += 114
    y += 16
    d.rectangle([40,y,W-40,y+2],fill=BORDER); y+=44

    # バージョン
    tc(d, y+20, "バージョン  1.0.0", f(26), GREY_D)

    return img

# ── Screenshot 4: ミュートエリア ──
def ss_geofence():
    img,d = new_img()
    d.rectangle([0,0,W,160], fill=(26,26,26))
    d.rectangle([0,158,W,162], fill=BORDER)
    draw_status_bar(d)
    d.text((80,96), "<", font=f(52), fill=WHITE)
    tc(d, 100, "ミュートエリア", f(46,True), WHITE)
    # 地図アイコン(右上)
    draw_map_icon(d, W-96, 116, 28, GOLD)

    map_top = 162
    map_h   = H-430
    # 地図背景
    map_img = Image.new("RGB",(W,map_h),(210,210,200))
    md = ImageDraw.Draw(map_img)
    # 街区
    for gx in range(0,W,160):
        for gy in range(0,map_h,200):
            md.rectangle([gx+10,gy+10,gx+150,gy+190],fill=(222,220,210))
    for gy in range(0,map_h,200): md.rectangle([0,gy,W,gy+18],fill=(242,240,232))
    for gx in range(0,W,160):    md.rectangle([gx,0,gx+18,map_h],fill=(242,240,232))
    # 公園（緑）
    md.rounded_rectangle([180,260,560,580],radius=20,fill=(175,210,155))
    bb = md.textbbox((0,0),"公園",font=f(32))
    md.text((310,400),"公園",font=f(32),fill=(70,120,50))
    # 川（青）
    md.rounded_rectangle([0,700,W,748],radius=0,fill=(180,210,240))
    md.text((60,708),"川",font=f(28),fill=(100,140,180))
    # 2つ目のジオフェンス（職場）
    cx2,cy2,r2 = 900, 900, 140
    ov2 = Image.new("RGBA",(W,map_h),(0,0,0,0))
    od2 = ImageDraw.Draw(ov2)
    od2.ellipse([cx2-r2,cy2-r2,cx2+r2,cy2+r2],fill=(255,100,0,50))
    od2.ellipse([cx2-r2,cy2-r2,cx2+r2,cy2+r2],outline=(200,80,0,200),width=6)
    map_img_rgba = map_img.convert("RGBA"); map_img_rgba.alpha_composite(ov2)
    md3 = ImageDraw.Draw(map_img_rgba)
    md3.rounded_rectangle([cx2-80,cy2-26,cx2+80,cy2+26],radius=10,fill=(10,10,10))
    md3.text((cx2-68,cy2-18),"職場 100m",font=f(28),fill=WHITE)
    md3.ellipse([cx2-14,cy2-14,cx2+14,cy2+14],fill=(255,120,0))
    # 自宅ジオフェンス
    cx1,cy1,r1 = 480, 430, 210
    ov1 = Image.new("RGBA",(W,map_h),(0,0,0,0))
    od1 = ImageDraw.Draw(ov1)
    od1.ellipse([cx1-r1,cy1-r1,cx1+r1,cy1+r1],fill=(0,136,255,60))
    od1.ellipse([cx1-r1,cy1-r1,cx1+r1,cy1+r1],outline=(0,100,200,220),width=8)
    map_img_rgba.alpha_composite(ov1)
    md4 = ImageDraw.Draw(map_img_rgba)
    md4.rounded_rectangle([cx1-80,cy1-26,cx1+80,cy1+26],radius=10,fill=(10,10,10))
    md4.text((cx1-70,cy1-18),"自宅 150m",font=f(28),fill=WHITE)
    md4.ellipse([cx1-16,cy1-16,cx1+16,cy1+16],fill=BLUE)
    map_img = map_img_rgba.convert("RGB")
    img.paste(map_img,(0,map_top))

    # ヒントバナー
    hint_y = map_top+22
    rr(d,[W//2-340,hint_y,W//2+340,hint_y+58],29,fill=(20,20,20,))
    tc(d, hint_y+12, "地図をタップしてミュートエリアを追加", f(28), (180,180,180))

    # 下部リスト
    list_y = H-270
    d.rectangle([0,list_y,W,H],fill=(18,18,18))
    d.rectangle([0,list_y,W,list_y+3],fill=BORDER)
    for i,(name,radius,color) in enumerate([("自宅","150","#0088FF"),("職場","100","#FF6414")]):
        ly = list_y + 20 + i*110
        # ミュートアイコン（スピーカー×）
        mx = 68; my = ly+40
        d.rounded_rectangle([mx-24,my-16,mx+10,my+16],radius=4,fill=GREY)
        d.polygon([(mx+10,my-16),(mx+10,my+16),(mx+30,my+30),(mx+30,my-30)],fill=GREY)
        d.line([(mx+40,my-20),(mx+60,my+20)],fill=RED_L,width=4)
        d.line([(mx+60,my-20),(mx+40,my+20)],fill=RED_L,width=4)
        d.text((mx+80,ly+16), name, font=f(36,True), fill=WHITE)
        d.text((mx+80,ly+60), f"半径 {radius} m", font=f(28), fill=GREY)
        if i==0: d.rectangle([60,ly+100,W-60,ly+102],fill=BORDER)

    return img

# ── Screenshot 5: オンボーディング ──
def ss_onboarding():
    img,d = new_img()
    draw_status_bar(d)
    d.rounded_rectangle([56,100,136,110],radius=4,fill=(200,60,0))

    # 大きな熊ベルイラスト
    bear_y = 420
    draw_bear_icon(d, W//2, bear_y, 160)
    # 音波
    for r2 in [200,250,300]:
        d.arc([W//2-r2,bear_y-r2,W//2+r2,bear_y+r2], start=-50, end=50,
              fill=(80,60,0), width=4)
        d.arc([W//2-r2,bear_y-r2,W//2+r2,bear_y+r2], start=130, end=230,
              fill=(80,60,0), width=4)

    tc(d, 680, "街に熊が出没しています", f(62,True), WHITE)

    lines = [
        ("近年、全国の市街地・住宅街・公園で", f(38), (200,200,200)),
        ("ツキノワグマの目撃が急増しています。", f(38), (200,200,200)),
        ("", None, None),
        ("Smart Bear Bell はあなたと熊との", f(38), (200,200,200)),
        ("不意な遭遇を防ぐアプリです。", f(38), (200,200,200)),
    ]
    ly = 790
    for text,fnt,col in lines:
        if fnt: tc(d, ly, text, fnt, col)
        ly += 56

    # 特徴ハイライト
    feat_y = 1120
    rr(d,[56,feat_y,W-56,feat_y+300],28,fill=CARD,outline=BORDER,width=2)
    feats = [
        (draw_bell_simple, GOLD,  "自動鈴音",   "歩行を感知して鳴る"),
        (draw_warn,        ORANGE,"緊急SOS",    "振るだけで発報"),
        (draw_map_icon,    BLUE,  "エリア登録", "自宅周辺は静音"),
    ]
    col_w = (W-112)//3
    for i,(fn,col,title,sub) in enumerate(feats):
        cx = 56+col_w*i+col_w//2
        fn(d, cx, feat_y+70, 28, col)
        bb = d.textbbox((0,0),title,font=f(28,True))
        d.text((cx-bb[2]//2,feat_y+118),title,font=f(28,True),fill=WHITE)
        bb2 = d.textbbox((0,0),sub,font=f(22))
        d.text((cx-bb2[2]//2,feat_y+158),sub,font=f(22),fill=GREY)
        if i<2: d.rectangle([56+col_w*(i+1)-1,feat_y+30,56+col_w*(i+1)+1,feat_y+270],fill=BORDER)

    # 目撃件数グラフバー
    graph_y = 1480
    tc(d, graph_y, "全国クマ目撃件数（年別）", f(28), GREY)
    years = [("2020",0.35),("2021",0.45),("2022",0.60),("2023",0.85),("2024",1.00)]
    bar_h = 200
    bw = (W-160)//len(years)
    for i,(yr,ratio) in enumerate(years):
        bx = 80+i*bw
        h_bar = int(bar_h*ratio)
        col = RED_L if ratio>=0.9 else ORANGE if ratio>=0.6 else GOLD
        d.rounded_rectangle([bx+12,graph_y+40+bar_h-h_bar,bx+bw-12,graph_y+40+bar_h],
                            radius=6,fill=col)
        bb = d.textbbox((0,0),yr,font=f(22))
        d.text((bx+(bw-bb[2])//2,graph_y+252),yr,font=f(22),fill=GREY)

    # ドット
    dot_y = H-300
    for i in range(5):
        cx = W//2+(i-2)*46
        color = GOLD if i==0 else (70,70,70)
        w_dot = 38 if i==0 else 14
        d.rounded_rectangle([cx-w_dot//2,dot_y-9,cx+w_dot//2,dot_y+9],radius=9,fill=color)

    # ボタン
    btn_y = H-220
    rr(d,[100,btn_y,W-100,btn_y+118],32,fill=GOLD)
    tc(d, btn_y+28, "次へ", f(58,True), (0,0,0))
    return img

os.makedirs("assets/screenshots", exist_ok=True)
screens = [
    ("ss_01_main",       ss_main),
    ("ss_02_emergency",  ss_emergency),
    ("ss_03_settings",   ss_settings),
    ("ss_04_geofence",   ss_geofence),
    ("ss_05_onboarding", ss_onboarding),
]
for name,fn in screens:
    img = fn()
    img.save(f"assets/screenshots/{name}.png","PNG")
    print(f"OK: {name}.png")
