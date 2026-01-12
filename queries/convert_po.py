import csv
import sys
import re

def parse_line(line):
    """Parse a line using regex to handle variable spacing"""
    # Remove trailing \n and clean
    line = line.rstrip('\\n').rstrip('\r\n').rstrip()
    
    # Use regex to split on 2+ spaces, but preserve the structure
    # Pattern: 8888RTV spaces 0 spaces 5773456 spaces 392...
    # Try to match the pattern more flexibly
    
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
    
    # Last resort: fixed width with better positions
    return [
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
        line[224:].strip().rstrip('\\n').strip()
    ]

# Get input and output filenames from command line arguments
input_file = sys.argv[1] if len(sys.argv) > 1 else 'PO.TXT'
output_file = sys.argv[2] if len(sys.argv) > 2 else 'PO.csv'

# Read file
try:
    with open(input_file, 'r', encoding='utf-8') as f:
        content = f.read()
except:
    try:
        with open(input_file, 'r', encoding='latin-1') as f:
            content = f.read()
    except:
        print(f"Could not read {input_file} file.")
        sys.exit(1)

lines = content.split('\n')
rows = []

for line in lines:
    line = line.rstrip('\r\n')
    # Remove literal \n at the end if present
    if line.endswith('\\n'):
        line = line[:-2]
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
