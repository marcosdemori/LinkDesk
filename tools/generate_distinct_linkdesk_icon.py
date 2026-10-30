import os
from PIL import Image, ImageDraw, ImageFont

def generate_linkdesk_assets():
    size = 512
    # 1. Base Squircle com Gradiente Azul Real / Safira Escuro para Elétrico
    # (Não é o azul chapado do RustDesk, é um gradiente premium de alta tecnologia)
    bg = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    bdraw = ImageDraw.Draw(bg)
    for y in range(size):
        ratio = y / size
        # De Azul Noite / Índigo (16, 28, 70) para Azul Real Elétrico (30, 95, 235)
        r = int(14 * (1 - ratio) + 30 * ratio)
        g = int(32 * (1 - ratio) + 95 * ratio)
        b = int(75 * (1 - ratio) + 240 * ratio)
        bdraw.line([(0, y), (size, y)], fill=(r, g, b, 255))

    mask = Image.new('L', (size, size), 0)
    mdraw = ImageDraw.Draw(mask)
    # Squircle moderno com cantos arredondados raio 115
    mdraw.rounded_rectangle([20, 20, size - 20, size - 20], radius=115, fill=255)
    bg.putalpha(mask)

    # 2. Emblema Exclusivo LinkDesk: Elo de Conexão Duplo (Interlocking Link Nodes)
    # Totalmente diferente das setas circulares do RustDesk!
    # Dois anéis arredondados grossos entrelaçados (um Branco Puro, um Ciano Neon)
    cx, cy = size // 2, size // 2
    emblem = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    edraw = ImageDraw.Draw(emblem)

    lw = 40  # espessura do traço
    rad = 60 # raio das pontas

    # Loop Esquerdo (Branco Puro #FFFFFF):
    # Representa o computador Local / Conexão Link
    edraw.rounded_rectangle([cx - 155, cy - 85, cx + 20, cy + 85], radius=rad, outline=(255, 255, 255, 255), width=lw)

    # Loop Direito (Ciano Neon #38BDF8):
    # Representa o computador Remoto / Conexão Desk
    edraw.rounded_rectangle([cx - 20, cy - 85, cx + 155, cy + 85], radius=rad, outline=(56, 189, 248, 255), width=lw)

    # Efeito de Entrelaçamento (Interlocking Link):
    # O elo esquerdo cruza POR CIMA na parte superior e POR BAIXO na inferior
    # Limpa a junção superior do elo direito e redesenha o topo do elo esquerdo por cima
    top_patch = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    pdraw = ImageDraw.Draw(top_patch)
    # Desenha o trecho superior do elo esquerdo sobrepondo
    pdraw.arc([cx - 155, cy - 85, cx + 20, cy + 85], 270, 360, fill=(255, 255, 255, 255), width=lw)
    pdraw.line([cx - 70, cy - 85, cx - 20, cy - 85], fill=(255, 255, 255, 255), width=lw)
    pdraw.line([cx - 20, cy - 85, cx + 10, cy - 85], fill=(255, 255, 255, 255), width=lw)
    
    # Composição final
    icon_512 = Image.alpha_composite(bg, emblem)
    icon_512 = Image.alpha_composite(icon_512, top_patch)

    # Lista de tamanhos para o arquivo .ICO do Windows
    ico_sizes = [(256, 256), (128, 128), (64, 64), (48, 48), (32, 32), (24, 24), (16, 16)]

    # 1. Salvar ICOs principais
    os.makedirs('client/res', exist_ok=True)
    os.makedirs('client/flutter/windows/runner/resources', exist_ok=True)
    os.makedirs('client/flutter/assets', exist_ok=True)

    icon_512.save('client/res/icon.ico', format='ICO', sizes=ico_sizes)
    icon_512.save('client/flutter/windows/runner/resources/app_icon.ico', format='ICO', sizes=ico_sizes)
    icon_512.save('client/res/tray-icon.ico', format='ICO', sizes=[(32, 32), (24, 24), (16, 16)])
    print("[OK] Gerados arquivos .ICO (multi-resolucao)")

    # 2. Salvar PNGs de resolução
    icon_512.resize((256, 256), Image.Resampling.LANCZOS).save('client/res/icon.png', 'PNG')
    icon_512.resize((256, 256), Image.Resampling.LANCZOS).save('client/flutter/assets/icon.png', 'PNG')
    icon_512.resize((128, 128), Image.Resampling.LANCZOS).save('client/res/128x128.png', 'PNG')
    icon_512.resize((256, 256), Image.Resampling.LANCZOS).save('client/res/128x128@2x.png', 'PNG')
    icon_512.resize((32, 32), Image.Resampling.LANCZOS).save('client/res/32x32.png', 'PNG')
    icon_512.resize((16, 16), Image.Resampling.LANCZOS).save('client/res/16x16.png', 'PNG')
    print("[OK] Gerados arquivos PNG de resolucao")

    # 3. Gerar Logo Horizontal (560x120) com o novo emblema + Tipografia LinkDesk
    logo_w, logo_h = 560, 120
    logo_img = Image.new('RGBA', (logo_w, logo_h), (0, 0, 0, 0))
    ldraw = ImageDraw.Draw(logo_img)
    # Reduz emblema para 90x90
    emblem_small = icon_512.resize((90, 90), Image.Resampling.LANCZOS)
    logo_img.paste(emblem_small, (20, 15), emblem_small)

    # Tenta usar fonte do sistema ou desenha texto de alta fidelidade
    try:
        font_main = ImageFont.truetype("arialbd.ttf", 52)
        font_sub = ImageFont.truetype("arial.ttf", 20)
        ldraw.text((130, 24), "Link", fill=(255, 255, 255, 255), font=font_main)
        ldraw.text((230, 24), "Desk", fill=(56, 189, 248, 255), font=font_main)
        ldraw.text((132, 80), "REMOTE DESKTOP", fill=(148, 163, 184, 255), font=font_sub)
    except:
        ldraw.text((130, 35), "LinkDesk", fill=(255, 255, 255, 255))

    logo_img.save('client/flutter/assets/logo.png', 'PNG')
    logo_img.save('client/flutter/assets/logo_light.png', 'PNG')
    logo_img.save('client/flutter/assets/logo_dark.png', 'PNG')
    print("[OK] Gerados arquivos de logo horizontal LinkDesk")

if __name__ == '__main__':
    generate_linkdesk_assets()
