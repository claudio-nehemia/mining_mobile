# Script to create padded logo for adaptive icon
# This creates a version of the logo with padding to prevent cropping

from PIL import Image, ImageOps

def create_padded_logo():
    # Open the original logo
    try:
        img = Image.open('assets/logo.jpeg')
        
        # Get original size
        width, height = img.size
        print(f"Original size: {width}x{height}")
        
        # Calculate new size with 20% padding on each side
        # This means the logo will be 60% of the total canvas
        padding_percent = 0.20
        new_width = int(width / (1 - 2 * padding_percent))
        new_height = int(height / (1 - 2 * padding_percent))
        
        # Create new image with white background
        new_img = Image.new('RGB', (new_width, new_height), (255, 255, 255))
        
        # Calculate position to paste original logo (centered)
        paste_x = int((new_width - width) / 2)
        paste_y = int((new_height - height) / 2)
        
        # Paste original logo in center
        new_img.paste(img, (paste_x, paste_y))
        
        # Save as PNG for better quality
        new_img.save('assets/logo_padded.png', 'PNG')
        print(f"Created padded logo: {new_width}x{new_height}")
        print("Saved as assets/logo_padded.png")
        
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    create_padded_logo()
