from PIL import Image, ImageDraw, ImageFont
import os

def create_logo(filename, dark_mode=False):
    width = 560
    height = 120
    img = Image.new('RGBA', (width, height), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # 1. Desenhar Emblema LinkDesk (Azul Corporativo com Gradiente / Cantos Arredondados)
    badge_x = 20
    badge_y = 15
    badge_size = 90
    radius = 24
    
    # Fundo do Badge Azul Royal (#1D4ED8)
    badge_color = (29, 78, 216, 255)
    draw.rounded_rectangle([badge_x, badge_y, badge_x + badge_size, badge_y + badge_size], radius=radius, fill=badge_color)
    
    # Detalhe interno do emblema: Símbolo de Link / Conexão (Branco)
    center_x = badge_x + badge_size // 2
    center_y = badge_y + badge_size // 2
    
    # Círculo central e anéis de link
    draw.ellipse([center_x - 18, center_y - 18, center_x + 18, center_y + 18], outline=(255, 255, 255, 255), width=6)
    # Linhas de link / nós
    draw.line([center_x - 30, center_y - 15, center_x - 12, center_y], fill=(255, 255, 255, 255), width=5)
    draw.line([center_x + 12, center_y, center_x + 30, center_y + 15], fill=(255, 255, 255, 255), width=5)
    draw.ellipse([center_x - 33, center_y - 18, center_x - 27, center_y - 12], fill=(255, 255, 255, 255))
    draw.ellipse([center_x + 27, center_y + 12, center_x + 33, center_y + 18], fill=(255, 255, 255, 255))

    # 2. Tipografia "LinkDesk"
    # Tenta usar Segoe UI ou Arial do Windows
    font_main = None
    font_sub = None
    for f in ["C:/Windows/Fonts/segoeuib.ttf", "C:/Windows/Fonts/arialbd.ttf"]:
        if os.path.exists(f):
            font_main = ImageFont.truetype(f, 54)
            break
            
    for f in ["C:/Windows/Fonts/segoeui.ttf", "C:/Windows/Fonts/arial.ttf"]:
        if os.path.exists(f):
            font_sub = ImageFont.truetype(f, 20)
            break

    text_x = badge_x + badge_size + 24
    main_color = (248, 250, 252, 255) if dark_mode else (15, 23, 42, 255)
    blue_color = (37, 99, 235, 255)
    sub_color = (148, 163, 184, 255) if dark_mode else (100, 116, 139, 255)

    if font_main:
        # "Link" em main_color e "Desk" em azul
        draw.text((text_x, 20), "Link", font=font_main, fill=main_color)
        bbox = draw.textbbox((text_x, 20), "Link", font=font_main)
        link_w = bbox[2] - bbox[0]
        draw.text((text_x + link_w, 20), "Desk", font=font_main, fill=blue_color)
    else:
        draw.text((text_x, 20), "LinkDesk", fill=blue_color)

    if font_sub:
        draw.text((text_x + 2, 78), "ACESSO REMOTO SEGURO", font=font_sub, fill=sub_color)

    img.save(filename, 'PNG')
    print(f"Salvo logo em: {filename}")

os.makedirs("client/flutter/assets", exist_ok=True)
create_logo("client/flutter/assets/logo.png", dark_mode=False)
create_logo("client/flutter/assets/logo_light.png", dark_mode=False)
create_logo("client/flutter/assets/logo_dark.png", dark_mode=True)
