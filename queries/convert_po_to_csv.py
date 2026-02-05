"""
PO File Converter - Fixed Width to CSV
Converts fixed-width PO files (format: 8888RTV) to CSV format.

Usage:
    python convert_po_to_csv.py <input_file> <output_file>
    OR
    python convert_po_to_csv.py  # Converts ADT_RXT_PO files in current directory
"""

import csv
import re
import sys
import os

def parse_fixed_width_line(line):
    """Parse a fixed-width PO line into fields using fixed positions"""
    line = line.rstrip('\n')
    line = line.rstrip(' \\n')
    line = line.rstrip()
    
    if len(line) < 8:
        return None
    
    record_type = line[0:8].strip()
    if record_type != "8888RTV":
        return None
    
    # Remove "8888RTV" prefix (8 chars)
    rest = line[8:].lstrip()
    
    # Split on 2+ spaces to get tokens
    tokens = [t.strip() for t in re.split(r'\s{2,}', rest) if t.strip()]
    
    # Expected structure: field1, field2, field3, field4, field5, part_number, quantity, field8, date, price, field11, field12, vendor
    # But part_number might be split, and vendor might be multiple words
    
    if len(tokens) < 9:
        return [record_type] + [""] * 13
    
    # Find date (8 digits)
    date_idx = None
    for i, token in enumerate(tokens):
        if re.match(r'^\d{8}$', token):
            date_idx = i
            break
    
    if not date_idx or date_idx < 8:
        return [record_type] + [""] * 13
    
    # Map fields
    # Structure: field1(0), field2(1), field3(2), field4(3), field5(4), part_number(5), quantity(6), field8(7), date(8), price(9), field11(10), field12(11), vendor(12+)
    # So: quantity = date_idx - 2, field8 = date_idx - 1
    field1 = tokens[0] if len(tokens) > 0 else ""
    field2 = tokens[1] if len(tokens) > 1 else ""
    field3 = tokens[2] if len(tokens) > 2 else ""
    field4 = tokens[3] if len(tokens) > 3 else ""
    field5 = tokens[4] if len(tokens) > 4 else ""
    
    if date_idx >= 8:
        part_number = tokens[5] if len(tokens) > 5 else ""
        quantity = tokens[date_idx-2] if date_idx >= 2 and len(tokens) > date_idx-2 else ""
        field8 = tokens[date_idx-1] if date_idx >= 1 and len(tokens) > date_idx-1 else ""
    else:
        part_number = tokens[5] if len(tokens) > 5 else ""
        quantity = tokens[6] if len(tokens) > 6 else ""
        field8 = tokens[7] if len(tokens) > 7 else ""
    
    date = tokens[date_idx] if date_idx is not None else ""
    price = tokens[date_idx+1] if len(tokens) > date_idx+1 else ""
    field11 = tokens[date_idx+2] if len(tokens) > date_idx+2 else ""
    field12 = tokens[date_idx+3] if len(tokens) > date_idx+3 else ""
    vendor_name = " ".join(tokens[date_idx+4:]) if len(tokens) > date_idx+4 else ""
    
    return [record_type, field1, field2, field3, field4, field5, part_number, quantity, field8, date, price, field11, field12, vendor_name]

def convert_file(input_file, output_file):
    """Convert a fixed-width PO file to CSV"""
    if not os.path.exists(input_file):
        print(f"Error: Input file '{input_file}' not found.")
        return False
    
    try:
        with open(input_file, 'r', encoding='utf-8') as infile:
            lines = infile.readlines()
    except Exception as e:
        print(f"Error reading file '{input_file}': {e}")
        return False
    
    header = ['RecordType', 'Field1', 'Field2', 'Field3', 'Field4', 'Field5', 'PartNumber', 'Quantity', 'Field8', 'Date', 'Price', 'Field11', 'Field12', 'VendorName']
    
    try:
        with open(output_file, 'w', encoding='utf-8', newline='') as outfile:
            writer = csv.writer(outfile)
            writer.writerow(header)
            
            row_count = 0
            for line in lines:
                # Skip header and footer lines
                if line.startswith("8888HDR") or line.startswith("8888FTR"):
                    continue
                parsed = parse_fixed_width_line(line)
                if parsed and parsed[0] == "8888RTV" and any(parsed[1:]):  # Only write if there's actual data
                    writer.writerow(parsed)
                    row_count += 1
        
        print(f"Successfully converted '{input_file}' to '{output_file}' ({row_count} rows)")
        return True
    except Exception as e:
        print(f"Error writing file '{output_file}': {e}")
        return False

if __name__ == "__main__":
    if len(sys.argv) == 3:
        # Convert specific files
        input_file = sys.argv[1]
        output_file = sys.argv[2]
        convert_file(input_file, output_file)
    elif len(sys.argv) == 1:
        # Default: Convert ADT_RXT_PO files in current directory
        files_to_convert = [
            ('ADT_RXT_PO_202601091600.txt', 'ADT_RXT_PO_202601091600.csv'),
            ('ADT_RXT_PO_202601161600.txt', 'ADT_RXT_PO_202601161600.csv')
        ]
        
        for input_file, output_file in files_to_convert:
            if os.path.exists(input_file):
                convert_file(input_file, output_file)
            else:
                print(f"File '{input_file}' not found, skipping...")
    else:
        print("Usage:")
        print("  python convert_po_to_csv.py <input_file> <output_file>")
        print("  python convert_po_to_csv.py  # Converts default ADT_RXT_PO files")






