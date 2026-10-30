from PIL import Image, ImageDraw

width = 256
height = 256
img = Image.new('RGBA', (width, height), (0, 0, 0, 0))
draw = ImageDraw.Draw(img)

# Fundo do Badge Azul Royal (#1D4ED8)
badge_color = (29, 78, 216, 255)
draw.rounded_rectangle([16, 16, 240, 240], radius=56, fill=badge_color)

# Detalhe interno do emblema: Símbolo de Link / Conexão (Branco)
center_x = 128
center_y = 128

# Círculo central e anéis de link
draw.ellipse([center_x - 44, center_y - 44, center_x + 44, center_y + 44], outline=(255, 255, 255, 255), width=14)
# Linhas de link / nós
draw.line([center_x - 70, center_y - 35, center_x - 30, center_y], fill=(255, 255, 255, 255), width=12)
draw.line([center_x + 30, center_y, center_x + 70, center_y + 35], fill=(255, 255, 255, 255), width=12)
draw.ellipse([center_x - 80, center_y - 45, center_x - 60, center_y - 25], fill=(255, 255, 255, 255))
draw.ellipse([center_x + 60, center_y + 25, center_x + 80, center_y + 45], fill=(255, 255, 255, 255))

img.save("client/flutter/assets/icon.png", 'PNG')
print("Salvo client/flutter/assets/icon.png")
