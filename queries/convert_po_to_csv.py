import csv
import re

# Since the file appears to be in editor, let's parse the data we know exists
# Based on the file content shown, parse the fixed-width format

# Sample line structure:
# 8888RTV         0                 5773456                       392                           2741                          1                             CB130T              12          612                 20251222  8.68                11260642                                8996            ADI

# Read file - try different encodings
content = None
for encoding in ['utf-8', 'latin-1', 'cp1252']:
    try:
        with open('PO.TXT', 'r', encoding=encoding) as f:
            content = f.read()
        break
    except:
        continue

if not content:
    # If file read fails, create from known structure
    print("File read failed, creating CSV from template structure")
    content = ""

# Split by lines
lines = content.split('\n') if content else []

rows = []
for line in lines:
    line = line.rstrip('\r\n')
    if not line.strip() or '8888FTR' in line:
        continue
    
    if '8888RTV' in line and len(line) > 100:
        # Parse fixed-width - using regex to split on multiple spaces
        parts = re.split(r'\s{2,}', line.strip())
        if len(parts) >= 14:
            row = parts[:14]
        else:
            # Fallback to fixed-width parsing
            row = [
                line[0:8].strip(),
                line[8:26].strip(),
                line[26:44].strip(),
                line[44:62].strip(),
                line[62:80].strip(),
                line[80:98].strip(),
                line[98:116].strip(),
                line[116:134].strip(),
                line[134:152].strip(),
                line[152:170].strip(),
                line[170:188].strip(),
                line[188:206].strip(),
                line[206:224].strip(),
                line[224:].strip()
            ]
        rows.append(row)

# Write to CSV
with open('PO.csv', 'w', newline='', encoding='utf-8') as f:
    writer = csv.writer(f)
    writer.writerow(['RecordType', 'Field1', 'Field2', 'Field3', 'Field4', 'Field5', 'PartNumber', 'Quantity', 'Field8', 'Date', 'Price', 'Field11', 'Field12', 'VendorName'])
    writer.writerows(rows)

print(f'Created PO.csv with {len(rows)} rows')
