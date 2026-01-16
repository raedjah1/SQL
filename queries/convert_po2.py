import csv
import re

def parse_line(line):
    """Parse a line using regex to handle variable spacing"""
    # Remove trailing \n and clean
    line = line.rstrip('\r\n').rstrip()
    # Remove literal \n at the end if present
    if line.endswith('\\n'):
        line = line[:-2].rstrip()
    
    # Extract using regex patterns
    match = re.match(r'(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+([\d.]+)\s+(\S+)\s+(\S+)\s+(.+)', line)
    if match:
        return list(match.groups())
    
    # Fallback: split on 2+ spaces
    parts = re.split(r'\s{3,}', line.strip())
    if len(parts) >= 14:
        return parts[:14]
    elif len(parts) >= 10:
        # Pad if needed
        return parts + [''] * (14 - len(parts))
    
    # Last resort: fixed width
    return [
        line[0:8].strip() if len(line) > 8 else '',
        line[8:26].strip() if len(line) > 26 else '',
        line[26:44].strip() if len(line) > 44 else '',
        line[44:62].strip() if len(line) > 62 else '',
        line[62:80].strip() if len(line) > 80 else '',
        line[80:98].strip() if len(line) > 98 else '',
        line[98:116].strip() if len(line) > 116 else '',
        line[116:134].strip() if len(line) > 134 else '',
        line[134:152].strip() if len(line) > 152 else '',
        line[152:170].strip() if len(line) > 170 else '',
        line[170:188].strip() if len(line) > 188 else '',
        line[188:206].strip() if len(line) > 206 else '',
        line[206:224].strip() if len(line) > 224 else '',
        line[224:].strip()
    ]

# Read file - try multiple encodings
input_file = 'PO2.txt'
output_file = 'PO2.csv'

content = None
for encoding in ['utf-8', 'latin-1', 'cp1252']:
    try:
        with open(input_file, 'r', encoding=encoding) as f:
            content = f.read()
        break
    except:
        continue

if not content:
    print(f"Could not read {input_file}. Please ensure the file is saved.")
    exit(1)

lines = content.split('\n')
rows = []

for line in lines:
    line = line.rstrip('\r\n')
    # Remove literal \n at the end if present
    if line.endswith('\\n'):
        line = line[:-2].rstrip()
    if not line.strip() or '8888FTR' in line:
        continue
    if '8888RTV' in line and len(line) > 50:
        row = parse_line(line)
        # Clean fields - remove any remaining \n
        row = [field.replace('\\n', '').strip() for field in row]
        rows.append(row)

# Write CSV
with open(output_file, 'w', newline='', encoding='utf-8') as f:
    writer = csv.writer(f)
    writer.writerow(['RecordType', 'Field1', 'Field2', 'Field3', 'Field4', 'Field5', 'PartNumber', 'Quantity', 'Field8', 'Date', 'Price', 'Field11', 'Field12', 'VendorName'])
    writer.writerows(rows)

print(f'Successfully created {output_file} with {len(rows)} data rows')



