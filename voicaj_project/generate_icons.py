#!/usr/bin/env python3
"""
Скрипт для генерации иконок iOS приложения VoiceActionJournal
"""

from PIL import Image, ImageDraw
import os

def create_icon(size):
    """Создает иконку заданного размера"""
    # Создаем новое изображение с прозрачным фоном
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Размеры для масштабирования
    scale = size / 1024.0
    
    # Фон - градиент от синего к фиолетовому
    bg_color = (74, 144, 226)  # #4A90E2
    bg_color2 = (123, 104, 238)  # #7B68EE
    
    # Рисуем закругленный прямоугольник для фона
    margin = int(50 * scale)
    draw.rounded_rectangle([margin, margin, size - margin, size - margin], 
                          radius=int(100 * scale), fill=bg_color)
    
    # Центр изображения
    center_x, center_y = size // 2, size // 2
    
    # Микрофон
    mic_width = int(60 * scale)
    mic_height = int(200 * scale)
    mic_x = center_x - mic_width // 2
    mic_y = center_y - mic_height // 2
    
    # Корпус микрофона (белый)
    draw.rounded_rectangle([mic_x, mic_y, mic_x + mic_width, mic_y + mic_height], 
                          radius=int(30 * scale), fill=(255, 255, 255))
    
    # Верхняя часть микрофона
    top_width = int(80 * scale)
    top_height = int(40 * scale)
    top_x = center_x - top_width // 2
    top_y = mic_y - top_height // 2
    draw.ellipse([top_x, top_y, top_x + top_width, top_y + top_height], 
                 fill=(255, 255, 255))
    
    # Основание микрофона
    base_width = int(80 * scale)
    base_height = int(20 * scale)
    base_x = center_x - base_width // 2
    base_y = mic_y + mic_height
    draw.rounded_rectangle([base_x, base_y, base_x + base_width, base_y + base_height], 
                          radius=int(10 * scale), fill=(255, 255, 255))
    
    # Сетка микрофона (синие круги)
    grid_center_y = mic_y + int(20 * scale)
    draw.ellipse([center_x - int(25 * scale), grid_center_y - int(25 * scale),
                  center_x + int(25 * scale), grid_center_y + int(25 * scale)], 
                 outline=bg_color, width=int(3 * scale))
    draw.ellipse([center_x - int(15 * scale), grid_center_y - int(15 * scale),
                  center_x + int(15 * scale), grid_center_y + int(15 * scale)], 
                 outline=bg_color, width=int(2 * scale))
    
    # Голосовые волны (белые)
    wave_start_x = center_x + int(150 * scale)
    wave_y = center_y - int(100 * scale)
    
    # Волна 1
    for i in range(3):
        x1 = wave_start_x + i * int(100 * scale)
        y1 = wave_y + i * int(20 * scale)
        x2 = x1 + int(100 * scale)
        y2 = y1 - int(50 * scale)
        x3 = x2 + int(100 * scale)
        y3 = y1
        draw.arc([x1, y1 - int(25 * scale), x3, y1 + int(25 * scale)], 
                 start=0, end=180, fill=(255, 255, 255), width=int(8 * scale))
    
    # Волны слева
    wave_start_x_left = center_x - int(350 * scale)
    for i in range(3):
        x1 = wave_start_x_left + i * int(100 * scale)
        y1 = wave_y + i * int(20 * scale)
        x2 = x1 + int(100 * scale)
        y2 = y1 - int(50 * scale)
        x3 = x2 + int(100 * scale)
        y3 = y1
        draw.arc([x1, y1 - int(25 * scale), x3, y1 + int(25 * scale)], 
                 start=0, end=180, fill=(255, 255, 255), width=int(8 * scale))
    
    # Точки активности
    for i in range(3):
        # Справа
        x = center_x + int(180 * scale) + i * int(20 * scale)
        y = wave_y - int(20 * scale) - i * int(20 * scale)
        radius = int((8 - i * 2) * scale)
        draw.ellipse([x - radius, y - radius, x + radius, y + radius], 
                     fill=(255, 255, 255))
        
        # Слева
        x = center_x - int(180 * scale) - i * int(20 * scale)
        draw.ellipse([x - radius, y - radius, x + radius, y + radius], 
                     fill=(255, 255, 255))
    
    return img

def main():
    """Основная функция"""
    # Размеры иконок для iOS
    icon_sizes = [
        20, 29, 40, 58, 60, 76, 80, 87, 120, 152, 167, 180, 1024
    ]
    
    # Создаем папку для иконок
    output_dir = "generated_icons"
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)
    
    print("Генерирую иконки для iOS...")
    
    for size in icon_sizes:
        # Создаем иконку
        icon = create_icon(size)
        
        # Сохраняем
        filename = f"{output_dir}/icon_{size}x{size}.png"
        icon.save(filename, "PNG")
        print(f"✅ Создана иконка {size}x{size} - {filename}")
    
    print(f"\n🎉 Все иконки созданы в папке '{output_dir}'!")
    print("\n📱 Теперь нужно:")
    print("1. Открыть Xcode")
    print("2. Перетащить иконки в AppIcon.appiconset")
    print("3. Или заменить существующие файлы в Assets.xcassets")

if __name__ == "__main__":
    main()
