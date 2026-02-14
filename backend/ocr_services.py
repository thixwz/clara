import pytesseract
from PIL import Image, ImageEnhance, ImageFilter
import io
import os
import re

# Set Tesseract path - IMPORTANT for Windows
pytesseract.pytesseract.tesseract_cmd = r'C:\Program Files\Tesseract-OCR\tesseract.exe'

def preprocess_image(image):
    image = image.convert('L')  # Grayscale
    image = image.filter(ImageFilter.MedianFilter())  # Reduce noise
    enhancer = ImageEnhance.Contrast(image)
    image = enhancer.enhance(2.5)
    enhancer = ImageEnhance.Sharpness(image)
    image = enhancer.enhance(2.0)
    if min(image.size) < 1000:
        scale = 1000 / min(image.size)
        new_size = (int(image.size[0]*scale), int(image.size[1]*scale))
        image = image.resize(new_size, Image.LANCZOS)
    return image

def clean_ocr_text(text):
    text = re.sub(r'[^\x20-\x7E\n]', '', text)
    text = re.sub(r'\n+', '\n', text)
    text = re.sub(r'[ ]{2,}', ' ', text)
    text = text.replace('0.', 'O.')
    text = text.replace('mgldl', 'mg/dl')
    text = text.replace('millcumm', 'mill/cumm')
    text = text.replace('lakhs', 'Lakhs')
    text = text.strip()
    return text

def extract_medical_fields(text):
    fields = {}
    patterns = {
        "Hemoglobin": r"H[ae]moglobin\s*[:\-]?\s*([\d\.]+)",
        "Total RBC": r"Total R\.?B\.?C\.?\s*[:\-]?\s*([\d\.]+)",
        "Total WBC": r"Total W\.?\s*B\.?\s*C\.?\s*[:\-]?\s*([\d\.]+)",
        "Platelet Count": r"Platelet Count\s*[:\-]?\s*([\d\.]+)",
        "HCT": r"H\.?C\.?T\.?\s*[:\-]?\s*([\d\.]+)",
        "MCV": r"M\.?C\.?V\.?\s*[:\-]?\s*([\d\.]+)",
        "MCH": r"M\.?C\.?H\.?\s*[:\-]?\s*([\d\.]+)",
        "MCHC": r"M\.?C\.?H\.?C\.?\s*[:\-]?\s*([\d\.]+)",
        "RDW": r"R\.?D\.?W\.?\s*[:\-]?\s*([\d\.]+)",
        "MPV": r"M\.?P\.?V\.?\s*[:\-]?\s*([\d\.]+)",
    }
    for field, pattern in patterns.items():
        match = re.search(pattern, text, re.IGNORECASE)
        if match:
            fields[field] = match.group(1)
    return fields

def process_image(image_bytes, save_to=None):
    try:
        image = Image.open(io.BytesIO(image_bytes))
        image = preprocess_image(image)
        text = pytesseract.image_to_string(image)
        cleaned = clean_ocr_text(text)
        fields = extract_medical_fields(cleaned)
        if save_to:
            with open(save_to, 'w', encoding='utf-8') as f:
                f.write(cleaned)
        return {
            "raw_text": text.strip(),
            "cleaned_text": cleaned,
            "fields": fields
        }
    except Exception as e:
        print(f"OCR Error: {e}")
        return {
            "error": f"Error processing image: {str(e)}"
        }

def process_image_file(file_path, save_to=None):
    try:
        with open(file_path, 'rb') as f:
            return process_image(f.read(), save_to=save_to)
    except Exception as e:
        print(f"File Error: {e}")
        return {
            "error": f"Error reading file: {str(e)}"
        }

if __name__ == "__main__":
    import sys
    if len(sys.argv) > 1:
        test_image = sys.argv[1]
        print(f"Testing OCR on image: {test_image}")
        result = process_image_file(test_image, save_to="last_ocr.txt")
        print("\nExtracted text:")
        print("--------------")
        print(result["cleaned_text"])
        print("\nExtracted fields:")
        print(result["fields"])
    else:
        print("Please provide an image path. Example:")
        print("python ocr_services.py C:\\path\\to\\test-image.jpg")