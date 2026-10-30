from PIL import Image, ImageDraw

def create_linkdesk_icon():
    # Base em alta resolução (512x512) para downscaling perfeito
    size = 512
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Fundo do Badge Azul Royal Corporativo (#1D4ED8)
    badge_color = (29, 78, 216, 255)
    margin = 32
    draw.rounded_rectangle([margin, margin, size - margin, size - margin], radius=110, fill=badge_color)

    # Detalhe interno do emblema: Símbolo de Link / Conexão (Branco)
    center_x = size // 2
    center_y = size // 2

    # Círculo central com anéis de link
    draw.ellipse([center_x - 88, center_y - 88, center_x + 88, center_y + 88], outline=(255, 255, 255, 255), width=28)
    # Linhas de link / nós
    draw.line([center_x - 140, center_y - 70, center_x - 60, center_y], fill=(255, 255, 255, 255), width=24)
    draw.line([center_x + 60, center_y, center_x + 140, center_y + 70], fill=(255, 255, 255, 255), width=24)
    draw.ellipse([center_x - 160, center_y - 90, center_x - 120, center_y - 50], fill=(255, 255, 255, 255))
    draw.ellipse([center_x + 120, center_y + 50, center_x + 160, center_y + 90], fill=(255, 255, 255, 255))

    icon_sizes = [(256, 256), (128, 128), (64, 64), (48, 48), (32, 32), (24, 24), (16, 16)]

    # 1. client/res/icon.ico
    img.save('client/res/icon.ico', format='ICO', sizes=icon_sizes)
    print("Salvo client/res/icon.ico")

    # 2. client/res/tray-icon.ico
    img.save('client/res/tray-icon.ico', format='ICO', sizes=[(32, 32), (24, 24), (16, 16)])
    print("Salvo client/res/tray-icon.ico")

    # 3. client/flutter/windows/runner/resources/app_icon.ico
    img.save('client/flutter/windows/runner/resources/app_icon.ico', format='ICO', sizes=icon_sizes)
    print("Salvo client/flutter/windows/runner/resources/app_icon.ico")

    # Também salvar png 256x256 e 32x32
    img.resize((256, 256), Image.Resampling.LANCZOS).save('client/flutter/assets/icon.png', 'PNG')
    img.resize((32, 32), Image.Resampling.LANCZOS).save('client/res/32x32.png', 'PNG')
    img.resize((128, 128), Image.Resampling.LANCZOS).save('client/res/128x128.png', 'PNG')
    img.resize((256, 256), Image.Resampling.LANCZOS).save('client/res/128x128@2x.png', 'PNG')
    print("Atualizados PNGs de resolução")

create_linkdesk_icon()
