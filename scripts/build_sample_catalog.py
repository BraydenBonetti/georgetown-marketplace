#!/usr/bin/env python3
"""Build ~100+ sample marketplace listings with downloaded product photos."""

from __future__ import annotations

import json
import subprocess
import urllib.request
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PHOTO_DIR = ROOT / "Georgetown Marketplace" / "Resources" / "SamplePhotos"
JSON_OUT = ROOT / "Georgetown Marketplace" / "Resources" / "sample_listings.json"

UA = "GeorgetownMarketplace/1.0 (sample data; educational)"


def u(photo_id: str, w: int = 900) -> str:
    return f"https://images.unsplash.com/{photo_id}?auto=format&fit=crop&w={w}&q=75"


def ol(isbn: str) -> str:
    return f"https://covers.openlibrary.org/b/isbn/{isbn}-L.jpg"


# Existing 9 keep their filenames; new ones use sample-lNN.jpg
EXISTING = [
    {
        "id": "l1", "sellerId": "u-maya", "title": "IKEA MICKE Desk (White)",
        "price": 45, "category": "Furniture", "condition": "Good", "location": "Harbin",
        "description": "White MICKE desk, 28 3/4x19 5/8\". Chair included. Pickup from Harbin lobby.",
        "imageSymbol": "desk", "imageColorHex": "4A6FA5", "hoursAgo": 5,
        "allowsLoan": False, "loanPricePerWeek": None, "savedBy": [],
        "photo": "sample-desk", "url": u("photo-1518455027359-f3f8164ba6bd"),
    },
    {
        "id": "l2", "sellerId": "u-jordan", "title": "Apple 30W USB-C Power Adapter",
        "price": 25, "category": "Electronics", "condition": "Like new", "location": "Main Campus",
        "description": "Original Apple 30W USB-C charger for MacBook Air M1. Works perfectly.",
        "imageSymbol": "cable.connector", "imageColorHex": "2F2F2F", "hoursAgo": 12,
        "allowsLoan": True, "loanPricePerWeek": 4, "savedBy": ["u-demo"],
        "photo": "sample-charger", "url": u("photo-1583863788434-e58a36330cf0"),
    },
    {
        "id": "l3", "sellerId": "u-demo",
        "title": "Calculus: Early Transcendentals, 8th Edition — James Stewart",
        "price": 30, "category": "Textbooks", "condition": "Good", "location": "Copley",
        "description": "Stewart Calculus 8e (ISBN 978-1-305-27033-6). Highlights in a few chapters. Buy or borrow for the semester.",
        "imageSymbol": "book.closed", "imageColorHex": "6B4F3A", "hoursAgo": 28,
        "allowsLoan": True, "loanPricePerWeek": 5, "savedBy": [],
        "photo": "sample-textbook", "url": ol("9781305270336"),
    },
    {
        "id": "l4", "sellerId": "u-maya", "title": "Igloo 3.2 Cu. Ft. Mini Fridge",
        "price": 60, "category": "Dorm Essentials", "condition": "Good", "location": "Village A",
        "description": "Quiet mini fridge. Cleaned out. Perfect for a dorm or small room.",
        "imageSymbol": "refrigerator", "imageColorHex": "5B7C99", "hoursAgo": 48,
        "allowsLoan": True, "loanPricePerWeek": 10, "savedBy": [],
        "photo": "sample-fridge", "url": u("photo-1571175443880-49e1d25b2bc5"),
    },
    {
        "id": "l5", "sellerId": "u-jordan", "title": "Champion Reverse Weave Hoodie — Navy, L",
        "price": 20, "category": "Clothing", "condition": "Like new", "location": "Main Campus",
        "description": "Worn twice. Size L. Smoke-free apartment.",
        "imageSymbol": "tshirt", "imageColorHex": "041E42", "hoursAgo": 8,
        "allowsLoan": False, "loanPricePerWeek": None, "savedBy": [],
        "photo": "sample-hoodie", "url": u("photo-1556821840-3a63f95609a7"),
    },
    {
        "id": "l6", "sellerId": "u-demo", "title": "IKEA TERTIAL Work Lamp (Dark Gray)",
        "price": 15, "category": "Dorm Essentials", "condition": "Good", "location": "Nevils",
        "description": "Classic architect-style desk lamp. Great for late nights.",
        "imageSymbol": "lamp.desk", "imageColorHex": "C4A35A", "hoursAgo": 72,
        "allowsLoan": True, "loanPricePerWeek": 3, "savedBy": [],
        "photo": "sample-lamp", "url": u("photo-1507473885765-e6ed057f782c"),
    },
    {
        "id": "l7", "sellerId": "u-maya", "title": "Free — Plastic Closet Hangers (25)",
        "price": 0, "category": "Dorm Essentials", "condition": "Good", "location": "Harbin",
        "description": "Bunch of plastic hangers. Free if you pick up today.",
        "imageSymbol": "hanger", "imageColorHex": "8A8A8A", "hoursAgo": 3,
        "allowsLoan": False, "loanPricePerWeek": None, "savedBy": [],
        "photo": "sample-hangers", "url": u("photo-1558618666-fcd25c85f82e"),
    },
    {
        "id": "l8", "sellerId": "u-jordan", "title": "Apple AirPods Pro (2nd generation)",
        "price": 120, "category": "Electronics", "condition": "Like new", "location": "Village C",
        "description": "Case included, lightly used. No scratches. MagSafe charging case.",
        "imageSymbol": "airpods.pro", "imageColorHex": "1A1A1A", "hoursAgo": 20,
        "allowsLoan": False, "loanPricePerWeek": None, "savedBy": ["u-demo"],
        "photo": "sample-airpods", "url": u("photo-1600294037681-c80b4cb5b434"),
    },
    {
        "id": "l9", "sellerId": "u-sam", "title": "Georgetown Hoyas Basketball Tickets (Pair)",
        "price": 40, "category": "Tickets", "condition": "New", "location": "Main Campus",
        "description": "Two seats together. Transfer via Ticketmaster.",
        "imageSymbol": "ticket", "imageColorHex": "8B1E1E", "hoursAgo": 6,
        "allowsLoan": False, "loanPricePerWeek": None, "savedBy": [],
        "photo": "sample-tickets", "url": u("photo-1461896836934-fff607ba5301"),
    },
]

# 100 additional listings (l10–l109)
NEW = [
    # --- Textbooks (exact titles via Open Library ISBNs) ---
    ("l10", "u-jordan", "Campbell Biology, 12th Edition — Urry et al.", 55, "Textbooks", "Good", "Main Campus",
     "ISBN 978-0-135-18874-3. Used for BIOL-101. Some highlighting.", "book.closed", "6B4F3A",
     True, 8, ol("9780135188743")),
    ("l11", "u-maya", "Principles of Economics, 9th Edition — N. Gregory Mankiw", 40, "Textbooks", "Like new", "Copley",
     "ISBN 978-0-357-13380-4. Barely used — switched majors.", "book.closed", "2F5D50",
     True, 6, ol("9780357133804")),
    ("l12", "u-sam", "Organic Chemistry, 9th Edition — John McMurry", 45, "Textbooks", "Good", "Off Campus",
     "ISBN 978-1-305-08048-5. Notes in margins. Solutions not included.", "book.closed", "8B4513",
     True, 7, ol("9781305080485")),
    ("l13", "u-demo", "Physics for Scientists and Engineers, 10th Edition — Serway/Jewett", 50, "Textbooks", "Good", "Main Campus",
     "ISBN 978-1-337-55329-2. Calculus-based physics. Spine worn.", "book.closed", "1A3A6B",
     True, 7, ol("9781337553292")),
    ("l14", "u-jordan", "Introduction to Algorithms, 3rd Edition — Cormen et al. (CLRS)", 35, "Textbooks", "Good", "Main Campus",
     "ISBN 978-0-262-03384-8. The classic MIT Press CLRS. Highlighting in early chapters.", "book.closed", "041E42",
     True, 5, ol("9780262033848")),
    ("l15", "u-maya", "The Art of Public Speaking, 13th Edition — Stephen Lucas", 25, "Textbooks", "Like new", "Harbin",
     "ISBN 978-1-259-92460-0. Used one semester for COMM.", "book.closed", "8B1E1E",
     False, None, ol("9781259924600")),
    ("l16", "u-sam", "Microeconomics, 5th Edition — Paul Krugman & Robin Wells", 30, "Textbooks", "Good", "Village A",
     "ISBN 978-1-319-09877-3. Clean copy.", "book.closed", "2F5D50",
     True, 5, ol("9781319098773")),
    ("l17", "u-demo", "Linear Algebra and Its Applications, 5th Edition — David Lay", 28, "Textbooks", "Good", "Copley",
     "ISBN 978-0-321-98238-4. MATH-150. Some problem sets checked.", "book.closed", "4A6FA5",
     True, 4, ol("9780321982384")),
    ("l18", "u-jordan", "American Government: Institutions and Policies, 16th Edition — Wilson", 22, "Textbooks", "Fair", "Main Campus",
     "ISBN 978-1-337-56639-1. Highlighted throughout.", "book.closed", "041E42",
     False, None, ol("9781337566391")),
    ("l19", "u-maya", "Chemistry: The Central Science, 14th Edition — Brown/LeMay", 48, "Textbooks", "Good", "Nevils",
     "ISBN 978-0-134-41423-2. General chem. Cover scuffed, pages fine.", "book.closed", "C41E3A",
     True, 6, ol("9780134414232")),
    ("l20", "u-sam", "World Politics: Interests, Interactions, Institutions — Frieden et al.", 32, "Textbooks", "Like new", "Off Campus",
     "ISBN 978-0-393-93789-3. GOVT core. Almost unused.", "book.closed", "1A3A6B",
     True, 5, ol("9780393937893")),
    ("l21", "u-demo", "Psychology, 13th Edition — David G. Myers & C. Nathan DeWall", 35, "Textbooks", "Good", "Village C",
     "ISBN 978-1-319-13210-1. Intro psych.", "book.closed", "6B4F3A",
     False, None, ol("9781319132101")),
    ("l22", "u-jordan", "The Norton Anthology of English Literature, 10th Edition (Vol. 1)", 20, "Textbooks", "Fair", "Main Campus",
     "ISBN 978-0-393-60302-6. Heavy but complete. Spine cracked.", "book.closed", "8B4513",
     False, None, ol("9780393603026")),
    ("l23", "u-maya", "Essentials of Statistics for the Behavioral Sciences — Gravetter", 27, "Textbooks", "Good", "Harbin",
     "ISBN 978-1-337-09812-0. Stats for psych majors.", "book.closed", "2F5D50",
     True, 4, ol("9781337098120")),
    ("l24", "u-sam", "International Economics: Theory and Policy, 11th Edition — Krugman/Obstfeld", 38, "Textbooks", "Good", "Main Campus",
     "ISBN 978-0-13-451957-9. SFS staple.", "book.closed", "041E42",
     True, 6, ol("9780134519579")),

    # --- Electronics ---
    ("l25", "u-jordan", "Apple MagSafe Charger (iPhone)", 22, "Electronics", "Like new", "Main Campus",
     "Official Apple MagSafe wireless charger. Cable included.", "cable.connector", "1A1A1A",
     True, 3, u("photo-1609091839311-b348475b0ce6")),
    ("l26", "u-maya", "Anker PowerCore 10000 Portable Charger", 18, "Electronics", "Good", "Village A",
     "10,000 mAh power bank. USB-A + USB-C. Fully charged.", "battery.100", "2F2F2F",
     True, 3, u("photo-1585338447937-7082f8fc763d")),
    ("l27", "u-sam", "Logitech MX Master 3S Wireless Mouse", 55, "Electronics", "Like new", "Off Campus",
     "Graphite. Quiet clicks. Unifying + Bluetooth. Box included.", "computermouse", "3A3A3A",
     True, 8, u("photo-1527864550417-7fd91fc51a46")),
    ("l28", "u-demo", "Keychron K2 Mechanical Keyboard (RGB)", 65, "Electronics", "Good", "Nevils",
     "Wireless/wired. Brown switches. Mac layout.", "keyboard", "1A1A1A",
     True, 10, u("photo-1511467687858-23d96c32e4ae")),
    ("l29", "u-jordan", "Samsung 27\" Odyssey G5 Monitor", 180, "Electronics", "Good", "Village C",
     "1440p 144Hz curved gaming monitor. HDMI + DP cables included.", "display", "0A0A0A",
     True, 25, u("photo-1527443224154-c4a3942d3acf")),
    ("l30", "u-maya", "Sony WH-1000XM4 Wireless Headphones", 140, "Electronics", "Like new", "Harbin",
     "Black. Noise cancelling. Case + cables. ~40 hrs battery.", "headphones", "1A1A1A",
     True, 15, u("photo-1546435770-a3e426bf472b")),
    ("l31", "u-sam", "Apple USB-C to Lightning Cable (1m)", 10, "Electronics", "Good", "Main Campus",
     "Genuine Apple cable. Works with older iPhones.", "cable.connector", "8A8A8A",
     False, None, u("photo-1583863788434-e58a36330cf0")),
    ("l32", "u-demo", "iPad (9th generation) 64GB Wi-Fi — Space Gray", 220, "Electronics", "Good", "Copley",
     "A13 chip. Screen protector on. Pencil not included.", "ipad", "2F2F2F",
     True, 30, u("photo-1544244015-0df4b3ffc6b0")),
    ("l33", "u-jordan", "Nintendo Switch OLED — White Joy-Con", 250, "Electronics", "Like new", "Main Campus",
     "OLED model. Dock + HDMI + joy-cons. Animal Crossing not included.", "gamecontroller", "E8E8E8",
     True, 35, u("photo-1578303512597-81e85f4d4c4c")),
    ("l34", "u-maya", "Amazon Echo Dot (5th Gen) — Charcoal", 25, "Electronics", "Good", "Village A",
     "Smart speaker. Works with Alexa. Power adapter included.", "hifispeaker", "3A3A3A",
     False, None, u("photo-1543512214-318c7553f230")),
    ("l35", "u-sam", "JBL Flip 6 Portable Bluetooth Speaker", 60, "Electronics", "Like new", "Off Campus",
     "Waterproof. Blue. Great bass for dorm parties.", "hifispeaker.fill", "1A3A6B",
     True, 8, u("photo-1608043152269-423dbba4e7e1")),
    ("l36", "u-demo", "Apple Magic Keyboard (US English)", 70, "Electronics", "Good", "Nevils",
     "Wireless for Mac. Scissor switches. Lightning charge cable.", "keyboard", "E8E8E8",
     True, 10, u("photo-1587829741301-dc798b83add3")),
    ("l37", "u-jordan", "Razer DeathAdder V2 Gaming Mouse", 28, "Electronics", "Good", "Village C",
     "Optical sensor. RGB. Wired USB.", "computermouse", "44D62C",
     False, None, u("photo-1527814050087-3793815479db")),
    ("l38", "u-maya", "GoPro HERO10 Black", 200, "Electronics", "Like new", "Harbin",
     "Action cam + dual battery charger. No microSD.", "camera", "1A1A1A",
     True, 25, u("photo-1502920917128-1aa500764cbd")),
    ("l39", "u-sam", "Kindle Paperwhite (11th Gen) 8GB", 80, "Electronics", "Good", "Main Campus",
     "6.8\" glare-free. Waterproof. Ad-supported model.", "book", "2F2F2F",
     True, 10, u("photo-1544716278-ca5e3f4abd8c")),
    ("l40", "u-demo", "Apple Watch Series 7 GPS 41mm — Midnight", 160, "Electronics", "Good", "Copley",
     "Aluminum case. Sport band. Screen has light wear.", "applewatch", "1A1A1A",
     False, None, u("photo-1434493789847-2f02dc6ca35d")),
    ("l41", "u-jordan", "Anker 6-Outlet Power Strip with USB", 15, "Electronics", "New", "Main Campus",
     "Surge protector. 3 USB ports. Never opened spare.", "poweroutlet", "8A8A8A",
     False, None, u("photo-1558449028-b53a94e6d3c6")),
    ("l42", "u-maya", "Bose QuietComfort Earbuds II", 150, "Electronics", "Like new", "Village A",
     "ANC earbuds. Charging case. Extra tips.", "earbuds", "1A1A1A",
     True, 18, u("photo-1590658268037-6bf12165a8df")),
    ("l43", "u-sam", "Dell XPS 13 Laptop Sleeve (13\")", 12, "Electronics", "Good", "Off Campus",
     "Neoprene sleeve. Fits most 13\" Ultrabooks.", "briefcase", "2F2F2F",
     False, None, u("photo-1553062407-98eeb64c6a62")),
    ("l44", "u-demo", "Webcam Logitech C920 HD Pro", 35, "Electronics", "Good", "Nevils",
     "1080p. Built-in mic. Tripod thread. Zoom-ready.", "web.camera", "1A1A1A",
     True, 5, u("photo-1587825140708-dfaf72ae4b04")),

    # --- Furniture ---
    ("l45", "u-maya", "IKEA POÄNG Armchair — Birch/Knisa Beige", 70, "Furniture", "Good", "Harbin",
     "Classic bentwood armchair. Cushion clean. Assembly already done.", "sofa", "C4A35A",
     True, 12, u("photo-1567538096630-e0c55bd6374c")),
    ("l46", "u-sam", "IKEA KALLAX 2x2 Shelf Unit — White", 40, "Furniture", "Good", "Off Campus",
     "Cube storage. Great for vinyl, books, or bins.", "square.grid.2x2", "E8E8E8",
     False, None, u("photo-1595428774223-ef52624120d2")),
    ("l47", "u-jordan", "Folding Card Table (34\")", 20, "Furniture", "Fair", "Village C",
     "Light gray folding table. Good for crafts or extra desk.", "table.furniture", "8A8A8A",
     False, None, u("photo-1611269154421-4e27233ac5c7")),
    ("l48", "u-demo", "IKEA MALM 2-Drawer Chest — White", 55, "Furniture", "Good", "Nevils",
     "Dresser. Soft-close drawers. Mirror not included.", "cabinet", "E8E8E8",
     False, None, u("photo-1595428774223-ef52624120d2")),
    ("l49", "u-maya", "Floor Bean Bag Chair — Gray XL", 25, "Furniture", "Good", "Village A",
     "Microfiber cover. Removable. Needs more beans optionally.", "oval.fill", "6B6B6B",
     True, 5, u("photo-1586023492125-27b2c045efd7")),
    ("l50", "u-sam", "IKEA LACK Side Table — Black", 12, "Furniture", "Like new", "Main Campus",
     "21 5/8\" square. Coffee / nightstand height.", "table.furniture", "1A1A1A",
     False, None, u("photo-1532372320572-cda256256de2")),
    ("l51", "u-jordan", "Bar Stool Set (Pair) — Black Metal", 45, "Furniture", "Good", "Off Campus",
     "Two stools. Counter height. Moving — must sell together.", "chair", "2F2F2F",
     False, None, u("photo-1503602642458-232111445657")),
    ("l52", "u-demo", "Rolling Laundry Hamper with Lid", 18, "Furniture", "Good", "Copley",
     "Mesh sides. Wheels. Fits a full load.", "basket", "8A8A8A",
     False, None, u("photo-1582735689369-4fe89db7114c")),
    ("l53", "u-maya", "Full-Length Mirror — Standing, Black Frame", 30, "Furniture", "Good", "Harbin",
     "65\" leaning mirror. No cracks.", "mirror", "1A1A1A",
     False, None, u("photo-1618220179428-22790b461013")),
    ("l54", "u-sam", "IKEA BILLY Bookcase — White", 50, "Furniture", "Good", "Village C",
     "31 1/2\" wide. Adjustable shelves. Perfect for textbooks.", "books.vertical", "E8E8E8",
     False, None, u("photo-1594620302200-9a762244a156")),

    # --- Clothing ---
    ("l55", "u-jordan", "Patagonia Better Sweater Fleece — Men's M, Navy", 55, "Clothing", "Like new", "Main Campus",
     "Full-zip. Worn a handful of times. Smoke-free home.", "tshirt", "041E42",
     False, None, u("photo-1544022613-e87ca75a784a")),
    ("l56", "u-maya", "Levi's 501 Original Jeans — Women's 27", 35, "Clothing", "Good", "Harbin",
     "Medium wash. Classic straight fit.", "tshirt", "4A6FA5",
     False, None, u("photo-1542272604-787c3835535d")),
    ("l57", "u-sam", "Nike Dunk Low Retro — Men's 10, White/Black", 90, "Clothing", "Like new", "Off Campus",
     "Panda colorway. Worn twice. Box included.", "shoe.fill", "1A1A1A",
     False, None, u("photo-1542291026-7eec264c27ff")),
    ("l58", "u-demo", "The North Face Borealis Backpack — Black", 45, "Clothing", "Good", "Nevils",
     "28L. Laptop sleeve. Water bottle pockets.", "backpack", "1A1A1A",
     False, None, u("photo-1553062407-98eeb64c6a62")),
    ("l59", "u-maya", "Lululemon Align High-Rise Pant 25\" — Size 4, Black", 50, "Clothing", "Like new", "Village A",
     "Nulu fabric. No pilling. Too small for me now.", "figure.stand", "1A1A1A",
     False, None, u("photo-1506629082955-511b1aa782c0")),
    ("l60", "u-jordan", "Columbia Rain Jacket — Men's L, Black", 30, "Clothing", "Good", "Main Campus",
     "Waterproof shell. Packable hood. Great for DC drizzle.", "cloud.rain", "2F2F2F",
     False, None, u("photo-1591047139829-d91aecb6ca87")),
    ("l61", "u-sam", "Adidas Ultraboost 22 — Men's 9.5, Core Black", 70, "Clothing", "Good", "Village C",
     "Running shoes. ~80 miles on them. Cleaned.", "shoe.fill", "1A1A1A",
     False, None, u("photo-1606107557195-0e29a4b5b4aa")),
    ("l62", "u-demo", "Carhartt Acrylic Watch Hat — Black", 12, "Clothing", "New", "Copley",
     "Beanie. Never worn. Tags on.", "comb.fill", "1A1A1A",
     False, None, u("photo-1576871337632-b9aef4c17ab9")),
    ("l63", "u-maya", "Ralph Lauren Polo Shirt — Men's M, Navy", 25, "Clothing", "Good", "Harbin",
     "Classic fit. Mesh piqué. Embroidered pony.", "tshirt", "041E42",
     False, None, u("photo-1586790170083-2f9ceadc732d")),
    ("l64", "u-jordan", "Canada Goose HyBridge Lite Vest — Men's S", 180, "Clothing", "Like new", "Main Campus",
     "Black. Packable. Mid-layer for winter.", "vestment", "1A1A1A",
     False, None, u("photo-1544022613-e87ca75a784a")),
    ("l65", "u-sam", "Vans Old Skool — Unisex 8, Black/White", 28, "Clothing", "Good", "Off Campus",
     "Classic skate shoe. Some sole wear.", "shoe.fill", "1A1A1A",
     False, None, u("photo-1525966222134-fcfa99b8ae25")),
    ("l66", "u-demo", "Uniqlo Ultra Light Down Jacket — Women's M, Olive", 40, "Clothing", "Like new", "Nevils",
     "Packable into pouch. Perfect fall layer.", "jacket", "556B2F",
     False, None, u("photo-1551028719-00167b16eac5")),
    ("l67", "u-maya", "Aritzia Melina Pant — Size 2, Black", 45, "Clothing", "Good", "Village A",
     "Vegan leather look. Mid-rise. Flattering cut.", "figure.stand", "1A1A1A",
     False, None, u("photo-1594633312681-425c7b97ccd1")),
    ("l68", "u-jordan", "Georgetown Hoyas Crewneck Sweatshirt — L", 22, "Clothing", "Good", "Main Campus",
     "Bookstore buy. Soft fleece. Size L.", "tshirt", "041E42",
     False, None, u("photo-1556821840-3a63f95609a7")),

    # --- Dorm essentials ---
    ("l69", "u-maya", "Twin XL Sheet Set — White (3-piece)", 18, "Dorm Essentials", "Like new", "Harbin",
     "Fitted + flat + pillowcase. Washed once. Dorm size.", "bed.double", "E8E8E8",
     False, None, u("photo-1522771739844-6a9f6d5f14af")),
    ("l70", "u-sam", "Casper Foam Pillow (Standard)", 25, "Dorm Essentials", "Good", "Off Campus",
     "One pillow. Medium loft. Clean cover.", "bed.double.fill", "F5F5DC",
     False, None, u("photo-1631049307264-da0ec9d70304")),
    ("l71", "u-demo", "Keurig K-Mini Single Serve Coffee Maker", 40, "Dorm Essentials", "Good", "Nevils",
     "Black. Descaled. Pods not included.", "cup.and.saucer.fill", "1A1A1A",
     True, 6, u("photo-1514432324607-a09d9b4aefdd")),
    ("l72", "u-jordan", "Instant Pot Duo 6-Quart", 50, "Dorm Essentials", "Like new", "Village C",
     "7-in-1 pressure cooker. Used twice. Moving out.", "cooktop", "8A8A8A",
     True, 8, u("photo-1585515320310-259814abb0ac")),
    ("l73", "u-maya", "Dyson V8 Absolute Cordless Vacuum", 180, "Dorm Essentials", "Good", "Village A",
     "Stick vacuum + attachments. Battery holds ~20 min.", "fan", "1A1A1A",
     True, 20, u("photo-1558317374-067fb5f30001")),
    ("l74", "u-sam", "Target Threshold Area Rug 5x7 — Gray", 35, "Dorm Essentials", "Good", "Main Campus",
     "Low-pile. Vacuumed. Soft underfoot.", "square", "6B6B6B",
     False, None, u("photo-1600166898405-da9535204843")),
    ("l75", "u-demo", "Command Hook Variety Pack (Unused)", 8, "Dorm Essentials", "New", "Copley",
     "Damage-free hooks. Assorted sizes. Sealed.", "paperclip", "8A8A8A",
     False, None, u("photo-1615874959474-d609969a20ed")),
    ("l76", "u-jordan", "Brita Stream Filter Pitcher", 15, "Dorm Essentials", "Good", "Main Campus",
     "10-cup. Filter half-life left. BPA-free.", "drop.fill", "4A6FA5",
     False, None, u("photo-1564419320461-68708832211c")),
    ("l77", "u-maya", "Electric Kettle — COSORI 1.7L Stainless", 22, "Dorm Essentials", "Like new", "Harbin",
     "Auto shutoff. Perfect for ramen + tea.", "cup.fill", "C0C0C0",
     True, 3, u("photo-1565193566173-7a0ee3dbe261")),
    ("l78", "u-sam", "Storage Bins with Lids (Set of 4)", 20, "Dorm Essentials", "Good", "Off Campus",
     "Clear plastic. Stackable. Under-bed friendly.", "shippingbox", "E8E8E8",
     False, None, u("photo-1595079676339-98b2c946e44d")),
    ("l79", "u-demo", "Essential Oil Diffuser — 300ml Ultrasonic", 12, "Dorm Essentials", "Good", "Nevils",
     "LED lights. Remote. Oils not included.", "humidity", "C4A35A",
     False, None, u("photo-1608571423902-eed4a5ad8108")),
    ("l80", "u-jordan", "Space Heater — Lasko Ceramic 1500W", 25, "Dorm Essentials", "Good", "Village C",
     "Oscillating. Tip-over protection. Quiet.", "thermometer", "8B1E1E",
     True, 5, u("photo-1545259741-2ea3ebf61fa3")),
    ("l81", "u-maya", "Ironing Board + Rowenta Steam Iron", 20, "Dorm Essentials", "Good", "Village A",
     "Compact board + iron. Good for interviews.", "flame", "4A6FA5",
     False, None, u("photo-1517677208171-4bd1efbdfa05")),
    ("l82", "u-sam", "Full-Length Over-the-Door Mirror", 15, "Dorm Essentials", "Fair", "Main Campus",
     "Hooks over door. Frame scratched, glass fine.", "mirror", "8A8A8A",
     False, None, u("photo-1618220179428-22790b461013")),
    ("l83", "u-demo", "Desk Organizer Set — Bamboo", 14, "Dorm Essentials", "Like new", "Copley",
     "Pen cup + letter tray + sticky-note holder.", "tray", "C4A35A",
     False, None, u("photo-1456735190827-d1262f71b8a3")),
    ("l84", "u-jordan", "Blackout Curtains — 2 panels, Navy 84\"", 28, "Dorm Essentials", "Good", "Main Campus",
     "Rod pocket. Blocks morning light. Grommets.", "blinds.horizontal", "041E42",
     False, None, u("photo-1513694203232-719a280e022f")),
    ("l85", "u-maya", "Mattress Topper Twin XL — 3\" Memory Foam", 40, "Dorm Essentials", "Good", "Harbin",
     "Gel-infused. Removable cover. Dorm-size.", "bed.double", "F5F5DC",
     False, None, u("photo-1631049307264-da0ec9d70304")),
    ("l86", "u-sam", "Trash Can with Lid — 13 Gallon Stainless", 18, "Dorm Essentials", "Good", "Off Campus",
     "Foot pedal. Removable liner bucket.", "trash", "C0C0C0",
     False, None, u("photo-1610557892470-55d9e80c0bce")),
    ("l87", "u-demo", "Whiteboard 18x24\" with Markers", 12, "Dorm Essentials", "New", "Nevils",
     "Magnetic. Dry-erase markers + eraser included.", "character.textbox", "E8E8E8",
     False, None, u("photo-1586281380349-632531db7ed4")),
    ("l88", "u-jordan", "Surge-Protected Extension Cord 10ft", 10, "Dorm Essentials", "New", "Village C",
     "3-outlet. Flat plug. Orange for visibility.", "powercord", "E65C00",
     False, None, u("photo-1558449028-b53a94e6d3c6")),

    # --- Tickets ---
    ("l89", "u-sam", "Kennedy Center Symphony Tickets (Pair) — Orchestra", 75, "Tickets", "New", "Main Campus",
     "Saturday night. Transfer via Kennedy Center account.", "ticket", "8B1E1E",
     False, None, u("photo-1465847899084-d164df4dedc6")),
    ("l90", "u-maya", "Nationals Baseball Tickets (2) — Lower Level", 55, "Tickets", "New", "Harbin",
     "Sunday afternoon game. Section 136. Mobile transfer.", "ticket", "C41E3A",
     False, None, u("photo-1566577739112-5190acb5b5c5")),
    ("l91", "u-jordan", "Capital One Arena Concert GA — Floor", 95, "Tickets", "New", "Main Campus",
     "One general admission floor ticket. Will transfer ASAP.", "ticket", "1A1A1A",
     False, None, u("photo-1470229722913-7c0e2dbbafd3")),
    ("l92", "u-demo", "Smithsonian Museum Late Night Pass (2)", 0, "Tickets", "New", "Copley",
     "Free extras from a friend. This Friday 6–9pm.", "ticket", "041E42",
     False, None, u("photo-1565060169187-583bb326be62")),
    ("l93", "u-sam", "Washington Wizards Tickets (Pair) — Upper Bowl", 48, "Tickets", "New", "Off Campus",
     "Weeknight game. Side-by-side seats.", "ticket", "8B1E1E",
     False, None, u("photo-1504450758481-7338eba7524a")),
    ("l94", "u-maya", "Georgetown Theatre Production Tickets (2)", 20, "Tickets", "New", "Village A",
     "Campus show this weekend. Student ID helpful.", "ticket", "6B4F3A",
     False, None, u("photo-1503095396549-807759245b35")),

    # --- Other ---
    ("l95", "u-jordan", "Yeti Rambler 26 oz Bottle — Navy", 25, "Other", "Like new", "Main Campus",
     "Chug Cap. Keeps ice all day. Dent-free.", "waterbottle", "041E42",
     False, None, u("photo-1602143407151-7111542de6e8")),
    ("l96", "u-sam", "Hydro Flask 32 oz Wide Mouth — Black", 22, "Other", "Good", "Village C",
     "Flex Cap. Stickers removable. No leaks.", "waterbottle.fill", "1A1A1A",
     False, None, u("photo-1523362628745-0c100150b54b")),
    ("l97", "u-demo", "Set of 4 Ceramic Dinner Plates — White", 15, "Other", "Good", "Nevils",
     "IKEA DINERA style. Microwave safe.", "circle", "E8E8E8",
     False, None, u("photo-1578500494198-2428bcb26148")),
    ("l98", "u-maya", "Cast Iron Skillet — Lodge 10.25\"", 20, "Other", "Good", "Harbin",
     "Seasoned. No rust. Great for one-pan meals.", "frying.pan", "2F2F2F",
     True, 4, u("photo-1556910103-1c02745aae4d")),
    ("l99", "u-jordan", "Bicycle — Trek FX 2 Disc (Hybrid)", 280, "Other", "Good", "Main Campus",
     "Size M. Disc brakes. Lights + lock included. Needs tune.", "bicycle", "1A3A6B",
     True, 40, u("photo-1485963631004-f1f0e1fad1f5")),
    ("l100", "u-sam", "Scooter — Xiaomi Mi Electric Scooter 3", 220, "Other", "Like new", "Off Campus",
     "~15 mi range. Foldable. Helmet not included.", "scooter", "1A1A1A",
     True, 30, u("photo-1604357209793-fca5dca89f97")),
    ("l101", "u-demo", "Board Game: Catan (5th Edition)", 25, "Other", "Like new", "Copley",
     "Complete set. All pieces accounted for.", "dice", "C41E3A",
     True, 5, u("photo-1606092195730-5d7b9af1efc5")),
    ("l102", "u-maya", "Yoga Mat — Manduka PRO 6mm, Black", 45, "Other", "Good", "Village A",
     "Lifetime guarantee model. Light wear. No odor.", "figure.yoga", "1A1A1A",
     True, 6, u("photo-1544367567-0f2fcb009e0b")),
    ("l103", "u-jordan", "Dumbbell Set — 2x15 lb Neoprene", 30, "Other", "Good", "Main Campus",
     "Pair of 15s. Hex shape. Won't roll.", "dumbbell.fill", "1A1A1A",
     True, 5, u("photo-1517836357463-d25dfeac3438")),
    ("l104", "u-sam", "Plant: Monstera Deliciosa in 8\" Pot", 28, "Other", "Good", "Harbin",
     "Healthy. Includes ceramic pot + saucer.", "leaf", "2F5D50",
     False, None, u("photo-1463320726281-696a485928c7")),
    ("l105", "u-demo", "Desk Fan — Honeywell TurboForce", 14, "Other", "Good", "Nevils",
     "3 speeds. Quiet enough for studying.", "fan", "8A8A8A",
     False, None, u("photo-1558317374-067fb5f30001")),
    ("l106", "u-maya", "Polaroid Now Instant Camera — White", 70, "Other", "Like new", "Village A",
     "Autofocus. One pack of film included (8 shots).", "camera.fill", "E8E8E8",
     True, 12, u("photo-1526170375885-4d8ecf77b99f")),
    ("l107", "u-jordan", "Guitar — Fender Player Stratocaster (Sunburst)", 350, "Other", "Good", "Main Campus",
     "Maple neck. Soft case. Needs new strings.", "guitars", "C4A35A",
     True, 40, u("photo-1510915361894-db8b60106cb1")),
    ("l108", "u-sam", "Suitcase — Away The Bigger Carry-On, Navy", 120, "Other", "Like new", "Off Campus",
     "Spinner wheels. Compression system. TSA lock.", "suitcase.rolling", "041E42",
     False, None, u("photo-1565021716607-8166952c3cc8")),
    ("l109", "u-demo", "Printer — HP DeskJet 2755e Wireless", 45, "Other", "Good", "Copley",
     "Ink partially full. Instant Ink eligible. Wi-Fi setup.", "printer", "1A1A1A",
     True, 8, u("photo-1612815154858-60aa4c59eaa6")),
]


def expand_new(rows):
    out = []
    for i, row in enumerate(rows):
        (lid, seller, title, price, cat, cond, loc, desc, symbol, color, loan, loan_pw, url) = row
        out.append({
            "id": lid,
            "sellerId": seller,
            "title": title,
            "price": price,
            "category": cat,
            "condition": cond,
            "location": loc,
            "description": desc,
            "imageSymbol": symbol,
            "imageColorHex": color,
            "hoursAgo": 1 + (i % 90),
            "allowsLoan": loan,
            "loanPricePerWeek": loan_pw,
            "savedBy": ["u-demo"] if i % 11 == 0 else [],
            "photo": f"sample-{lid}",
            "url": url,
        })
    return out


def download_one(item: dict) -> tuple[str, bool, str]:
    photo = item["photo"]
    url = item["url"]
    dest = PHOTO_DIR / f"{photo}.jpg"
    # Keep existing files if present and > 5KB unless forced rebuild of new ids
    if dest.exists() and dest.stat().st_size > 5000 and item["id"] in {e["id"] for e in EXISTING}:
        return photo, True, "kept"
    try:
        req = urllib.request.Request(url, headers={"User-Agent": UA})
        with urllib.request.urlopen(req, timeout=30) as resp:
            data = resp.read()
        if len(data) < 2000:
            return photo, False, f"too small ({len(data)})"
        # Detect HTML error pages
        head = data[:200].lstrip().lower()
        if head.startswith(b"<!doctype") or head.startswith(b"<html"):
            return photo, False, "html response"
        dest.write_bytes(data)
        # Resize with sips if available
        try:
            subprocess.run(
                ["sips", "-Z", "1000", str(dest)],
                check=False, capture_output=True,
            )
        except Exception:
            pass
        return photo, True, f"{len(data)} bytes"
    except Exception as e:
        return photo, False, str(e)


def main():
    catalog = EXISTING + expand_new(NEW)
    assert len(catalog) == 109, len(catalog)
    PHOTO_DIR.mkdir(parents=True, exist_ok=True)

    print(f"Downloading {len(catalog)} photos…")
    ok = fail = 0
    with ThreadPoolExecutor(max_workers=12) as ex:
        futs = {ex.submit(download_one, item): item for item in catalog}
        for fut in as_completed(futs):
            name, success, msg = fut.result()
            if success:
                ok += 1
                print(f"  ✓ {name}: {msg}")
            else:
                fail += 1
                print(f"  ✗ {name}: {msg}")

    # Write JSON without url field
    seeds = []
    for item in catalog:
        seeds.append({k: v for k, v in item.items() if k != "url"})
    JSON_OUT.write_text(json.dumps(seeds, indent=2))
    print(f"\nWrote {JSON_OUT} ({len(seeds)} listings)")
    print(f"Photos ok={ok} fail={fail}")


if __name__ == "__main__":
    main()
