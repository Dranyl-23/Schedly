"""
Reminda AI - Advanced Synthetic Schedule Dataset Generator
Produces photorealistic Philippine academic study loads, hospital duty rosters,
and corporate timetables with camera perspective distortion, shadows, and HuggingFace metadata.jsonl.
"""

import os
import json
import random
import math
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, ImageFilter, ImageEnhance, ImageOps

OUTPUT_DIR = Path("ai_training/dataset")
IMAGES_DIR = OUTPUT_DIR / "images"
LABELS_DIR = OUTPUT_DIR / "labels"

IMAGES_DIR.mkdir(parents=True, exist_ok=True)
LABELS_DIR.mkdir(parents=True, exist_ok=True)

INSTITUTIONS = [
    {"name": "COR JESU COLLEGE, INC.", "campus": "Sacred Heart Ave, Digos City", "term": "1st Semester, AY 2026-2027", "role": "class"},
    {"name": "UNIVERSITY OF MINDANAO", "campus": "Digos College / Matina Campus", "term": "1st Semester, AY 2026-2027", "role": "class"},
    {"name": "ATENEO DE DAVAO UNIVERSITY", "campus": "E. Jacinto St, Davao City", "term": "1st Semester, AY 2026-2027", "role": "class"},
    {"name": "UNIVERSITY OF THE PHILIPPINES MINDANAO", "campus": "Mintal, Tugbok District, Davao City", "term": "1st Semester, AY 2026-2027", "role": "class"},
    {"name": "DAVAO MEDICAL SCHOOL FOUNDATION", "campus": "Medical School Drive, Davao City", "term": "Academic Term 2026", "role": "class"},
    {"name": "SOUTHERN PHILIPPINES MEDICAL CENTER", "campus": "J.P. Laurel Ave, Davao City", "term": "Clinical Rotation (August 2026)", "role": "duty"},
    {"name": "DAVAO DOCTORS HOSPITAL", "campus": "E. Quirino Ave, Davao City", "term": "Clinical Duty Shift (August 2026)", "role": "duty"},
    {"name": "DIGOS DOCTORS HOSPITAL", "campus": "Rizal Ave, Digos City", "term": "Duty Shift Schedule (2026)", "role": "duty"},
    {"name": "JOLLIBEE FOODS CORP. - DIGOS", "campus": "Branch #412 - Digos City", "term": "Store Crew Weekly Schedule", "role": "work"},
    {"name": "CONCENTRIX DAVAO", "campus": "Damosa IT Park, Davao City", "term": "BPO Operations Timetable", "role": "work"},
]

COURSES_POOL = [
    {"code": "ITIAS2", "title": "Information Assurance & Security 2", "units": "3.0", "category": "class"},
    {"code": "ITIAS2L", "title": "Information Assurance & Security 2 (Lab)", "units": "1.0", "category": "class"},
    {"code": "ITSAM", "title": "Systems Administration & Maintenance", "units": "3.0", "category": "class"},
    {"code": "ITNET2", "title": "Advanced Networking & Routing", "units": "3.0", "category": "class"},
    {"code": "CC105", "title": "Data Structures & Algorithms", "units": "3.0", "category": "class"},
    {"code": "CC106", "title": "Application Development & Emerging Tech", "units": "3.0", "category": "class"},
    {"code": "ITCAP1", "title": "Capstone Project & Research 1", "units": "3.0", "category": "class"},
    {"code": "PATHFIT 3", "title": "Physical Activity Towards Health", "units": "2.0", "category": "class"},
    {"code": "MATH101", "title": "Differential Calculus & Matrices", "units": "3.0", "category": "class"},
    {"code": "ENG102", "title": "Purposive Communication", "units": "3.0", "category": "class"},
    {"code": "NUR311", "title": "Care of Clients with Maladaptive Patterns", "units": "4.0", "category": "duty"},
    {"code": "NUR312", "title": "Clinical Rotation: Medical-Surgical Ward", "units": "3.0", "category": "duty"},
    {"code": "NUR-ER", "title": "Emergency Room Duty Rotation", "units": "4.0", "category": "duty"},
    {"code": "NUR-ICU", "title": "Intensive Care Unit (ICU) Duty", "units": "4.0", "category": "duty"},
    {"code": "STORE-OPS", "title": "Morning Store Operations & Cashiering", "units": "N/A", "category": "work"},
    {"code": "BPO-CSR", "title": "Technical Support Specialist Shift", "units": "N/A", "category": "work"},
    {"code": "KITCHEN-PREP", "title": "Kitchen Preparation & Grilling Station", "units": "N/A", "category": "work"},
]

INSTRUCTORS_POOL = [
    "Engr. Daryl Ivan Hisola, MIT",
    "Prof. Maria Santos, PhD",
    "Dr. Juan Dela Cruz, MD",
    "Prof. Reynante Morales, MSCS",
    "Head Nurse Elena Ramos, RN",
    "Prof. Christopher Lim, MIT",
    "Supervisor Mark Anthony Tan",
    "Dr. Arthur Pendelton, FPCP",
    "Prof. Angela Gomez, CPA, MBA",
]

ROOMS_POOL = [
    "CLB 4", "LAN LAB 2", "ROOM 302", "ENG 204", "NURSING LAB 1", "WARD 3", "ER STATION 2", "MAIN BLDG 101", "GYM 1", "RM 405"
]

DAYS_PATTERNS = [
    {"label": "MWF", "days": [1, 3, 5]},
    {"label": "TTH", "days": [2, 4]},
    {"label": "TH", "days": [4]},
    {"label": "SAT", "days": [6]},
    {"label": "FS", "days": [5, 6]},
    {"label": "M-F", "days": [1, 2, 3, 4, 5]},
    {"label": "T-SAT", "days": [2, 3, 4, 5, 6]},
]

TIME_SLOTS = [
    ("07:30", "09:00"),
    ("09:00", "10:30"),
    ("10:30", "12:00"),
    ("13:00", "14:30"),
    ("14:30", "16:00"),
    ("16:00", "17:30"),
    ("17:30", "19:00"),
    ("19:00", "21:00"),
    ("22:00", "06:00"),
]

def apply_realistic_camera_effects(image: Image.Image) -> Image.Image:
    """Applies realistic perspective, lighting gradients, shadows, and subtle blur."""
    w, h = image.size

    # 1. Perspective Transform (Camera tilt)
    if random.random() > 0.3:
        dx = random.randint(10, 45)
        dy = random.randint(10, 35)
        coeffs = (
            1 + random.uniform(-0.03, 0.03), random.uniform(-0.02, 0.02), dx,
            random.uniform(-0.02, 0.02), 1 + random.uniform(-0.03, 0.03), dy,
            random.uniform(-0.0001, 0.0001), random.uniform(-0.0001, 0.0001)
        )
        image = image.transform((w, h), Image.PERSPECTIVE, coeffs, Image.BICUBIC, fillcolor=(240, 240, 240))

    # 2. Lighting Gradient / Vignette
    if random.random() > 0.4:
        gradient = Image.new('L', (w, h), color=255)
        g_draw = ImageDraw.Draw(gradient)
        for i in range(h):
            factor = int(255 - (i / h) * random.randint(15, 45))
            g_draw.line([(0, i), (w, i)], fill=factor)
        image = ImageOps.colorize(gradient, black="#1A1A1A", white="#FFFFFF")
        image = Image.blend(image, image, 0.9)

    # 3. Paper Texture & Subtle Blur
    if random.random() > 0.5:
        image = image.filter(ImageFilter.GaussianBlur(radius=random.uniform(0.3, 0.8)))

    # 4. Contrast & Brightness Jitter
    enhancer = ImageEnhance.Contrast(image)
    image = enhancer.enhance(random.uniform(0.9, 1.15))
    b_enhancer = ImageEnhance.Brightness(image)
    image = b_enhancer.enhance(random.uniform(0.92, 1.05))

    return image

def generate_schedule(index: int) -> dict:
    width, height = 1200, 1600
    # Realistic paper tone (light off-white)
    bg_color = (random.randint(250, 255), random.randint(249, 255), random.randint(246, 252))
    image = Image.new("RGB", (width, height), color=bg_color)
    draw = ImageDraw.Draw(image)

    inst = random.choice(INSTITUTIONS)
    num_entries = random.randint(4, 9)
    selected_courses = random.sample(COURSES_POOL, k=min(num_entries, len(COURSES_POOL)))

    # Top Header
    draw.rectangle([(40, 30), (width - 40, 160)], outline=(203, 213, 225), width=2)
    draw.text((width // 2 - 190, 45), inst["name"], fill=(15, 23, 42))
    draw.text((width // 2 - 150, 75), inst["campus"], fill=(71, 85, 105))
    draw.text((width // 2 - 170, 105), f"OFFICIAL CERTIFICATE OF MATRICULATION - {inst['term']}", fill=(37, 99, 235))
    draw.text((60, 135), f"STUDENT ID: 2023-{random.randint(10000, 99999)}    NAME: POLACAS, ALFIE LYNARD P.    COURSE: BSIT-3", fill=(100, 116, 139))

    # Table Grid
    table_top = 190
    row_height = 85
    cols = [
        ("SUBJ CODE", 60),
        ("DESCRIPTION", 220),
        ("UNITS", 550),
        ("DAYS", 640),
        ("TIME", 750),
        ("ROOM", 900),
        ("INSTRUCTOR", 1020),
    ]

    draw.rectangle([(50, table_top), (width - 50, table_top + 45)], fill=(226, 232, 240))
    for col_name, x_pos in cols:
        draw.text((x_pos, table_top + 15), col_name, fill=(15, 23, 42))

    ground_truth_entries = []
    current_y = table_top + 50

    for c in selected_courses:
        day_pat = random.choice(DAYS_PATTERNS)
        time_slot = random.choice(TIME_SLOTS)
        room = random.choice(ROOMS_POOL)
        instructor = random.choice(INSTRUCTORS_POOL)

        draw.line([(50, current_y), (width - 50, current_y)], fill=(226, 232, 240), width=1)

        draw.text((60, current_y + 20), c["code"], fill=(15, 23, 42))
        draw.text((220, current_y + 20), c["title"][:26], fill=(51, 65, 85))
        draw.text((550, current_y + 20), c["units"], fill=(71, 85, 105))
        draw.text((640, current_y + 20), day_pat["label"], fill=(37, 99, 235))
        draw.text((750, current_y + 20), f"{time_slot[0]}-{time_slot[1]}", fill=(15, 23, 42))
        draw.text((900, current_y + 20), room, fill=(71, 85, 105))
        draw.text((1020, current_y + 20), instructor[:16], fill=(71, 85, 105))

        ground_truth_entries.append({
            "title": f"{c['code']} - {c['title']}",
            "category": c["category"],
            "daysOfWeek": day_pat["days"],
            "startTime": time_slot[0],
            "endTime": time_slot[1],
            "spansNextDay": time_slot[0] > time_slot[1],
            "location": room,
            "notes": f"{c['title']} / {instructor}"
        })

        current_y += row_height

    # Footer & Registrar Stamp
    draw.line([(50, current_y + 20), (width - 50, current_y + 20)], fill=(148, 163, 184), width=2)
    draw.text((60, current_y + 40), f"TOTAL UNITS: {len(selected_courses) * 3}.0    STATUS: ENROLLED / VALIDATED", fill=(15, 23, 42))
    draw.text((60, current_y + 65), f"REMINDA PROPRIETARY DATASET • SAMPLE ID: #{index:06d}", fill=(148, 163, 184))

    # Registrar Stamp Box
    draw.rectangle([(width - 260, current_y + 30), (width - 60, current_y + 110)], outline=(239, 68, 68), width=2)
    draw.text((width - 245, current_y + 45), "OFFICIALLY ENROLLED", fill=(239, 68, 68))
    draw.text((width - 230, current_y + 75), "OFFICE OF THE REGISTRAR", fill=(239, 68, 68))

    # Apply Photorealistic Camera Effects
    image = apply_realistic_camera_effects(image)

    img_filename = f"sched_{index:06d}.jpg"
    json_filename = f"sched_{index:06d}.json"

    img_path = IMAGES_DIR / img_filename
    json_path = LABELS_DIR / json_filename

    image.save(img_path, "JPEG", quality=88)
    with open(json_path, "w", encoding="utf-8") as f:
        json.dump(ground_truth_entries, f, indent=2)

    return {
        "file_name": img_filename,
        "ground_truth": json.dumps({"schedules": ground_truth_entries})
    }

if __name__ == "__main__":
    count = 100
    print(f"Generating {count} photorealistic Philippine schedule samples...")
    metadata_lines = []
    
    for i in range(1, count + 1):
        item = generate_schedule(i)
        metadata_lines.append(json.dumps(item))
        if i % 25 == 0:
            print(f"  Processed {i}/{count} samples...")

    metadata_path = OUTPUT_DIR / "metadata.jsonl"
    with open(metadata_path, "w", encoding="utf-8") as f:
        f.write("\n".join(metadata_lines))

    print(f"[SUCCESS] Successfully generated {count} photorealistic schedule images!")
    print(f"[DATASET] Images: {IMAGES_DIR}")
    print(f"[METADATA] HuggingFace Metadata: {metadata_path}")
