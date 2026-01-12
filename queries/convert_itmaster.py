import csv
import re

def parse_line(line):
    """Parse an itmaster line using pattern matching"""
    # Remove trailing \n and clean
    line = line.rstrip('\r\n').rstrip()
    # Remove literal \n at the end if present
    if line.endswith('\\n'):
        line = line[:-2].rstrip()
    
    # Pattern: 8888RTV spaces 0 spaces PartNumber spaces Status spaces Number spaces Status2 spaces Date spaces Description EA PartNumber2 Codes Numbers...
    # Use regex to match the pattern more flexibly
    
    # Match: 8888RTV, 0, PartNumber (starts with C), Status, Number, Status2, Date (8 digits), Description (until EA), EA, PartNumber2, Codes, Numbers...
    pattern = r'8888RTV\s+0\s+([C][\w-]+)\s+(CLIENT|Active|FLDUSE|TMPHOLD)\s+(\d+)\s+(CLIENT|Active|FLDUSE|TMPHOLD)\s+(\d{8})\s+(.+?)\s+EA\s+([\w-]+)\s+([N\s\w]+)\s+(\d+)\s+(\d{8})\s+(\d+)\s+(\d+)\s+([\d.]+)C\s+(\d+)(\w+)\s+(\d+)'
    
    match = re.match(pattern, line)
    if match:
        return [
            '8888RTV',
            '0',
            match.group(1),  # PartNumber
            match.group(2),  # Status1
            match.group(3),  # Number1
            match.group(4),  # Status2
            match.group(5),  # Date
            match.group(6).strip(),  # Description
            'EA',
            match.group(7),  # PartNumber2
            match.group(8).strip(),  # Codes
            match.group(9),  # Number2
            match.group(10),  # Date2
            match.group(11),  # Number3
            match.group(12),  # Number4
            match.group(13) + 'C',  # Price
            match.group(14) + match.group(15),  # Code2
            match.group(16)  # Number5
        ]
    
    # Fallback: try splitting on large spaces and pattern matching
    # Split the line into major sections
    if ' EA ' in line:
        parts = line.split(' EA ', 1)
        before_ea = parts[0]
        after_ea = parts[1]
        
        # Parse before EA: 8888RTV 0 PartNumber Status Number Status2 Date Description
        before_parts = re.split(r'\s{3,}', before_ea.strip())
        if len(before_parts) >= 7:
            record_type = before_parts[0] if before_parts[0].startswith('8888') else '8888RTV'
            field1 = '0'
            part_number = before_parts[1] if len(before_parts) > 1 else ''
            status1 = before_parts[2] if len(before_parts) > 2 else ''
            number1 = before_parts[3] if len(before_parts) > 3 else ''
            status2 = before_parts[4] if len(before_parts) > 4 else ''
            date = before_parts[5] if len(before_parts) > 5 else ''
            description = before_parts[6] if len(before_parts) > 6 else ''
        else:
            # Try fixed width for first part
            record_type = '8888RTV'
            field1 = '0'
            part_number = before_ea[26:44].strip() if len(before_ea) > 44 else ''
            status1 = before_ea[44:62].strip() if len(before_ea) > 62 else ''
            number1 = before_ea[62:80].strip() if len(before_ea) > 80 else ''
            status2 = before_ea[80:98].strip() if len(before_ea) > 98 else ''
            date = before_ea[98:116].strip() if len(before_ea) > 116 else ''
            description = before_ea[116:].strip() if len(before_ea) > 116 else ''
        
        # Parse after EA: PartNumber2 Codes Numbers Date Numbers Price Code Number
        after_parts = re.split(r'\s{2,}', after_ea.strip())
        part_number2 = after_parts[0] if len(after_parts) > 0 else ''
        codes = after_parts[1] if len(after_parts) > 1 else ''
        num2 = after_parts[2] if len(after_parts) > 2 else ''
        date2 = after_parts[3] if len(after_parts) > 3 else ''
        num3 = after_parts[4] if len(after_parts) > 4 else ''
        num4 = after_parts[5] if len(after_parts) > 5 else ''
        price = after_parts[6] if len(after_parts) > 6 else ''
        code2 = after_parts[7] if len(after_parts) > 7 else ''
        num5 = after_parts[8] if len(after_parts) > 8 else ''
        
        return [
            record_type,
            field1,
            part_number,
            status1,
            number1,
            status2,
            date,
            description,
            'EA',
            part_number2,
            codes,
            num2,
            date2,
            num3,
            num4,
            price,
            code2,
            num5
        ]
    
    # Last resort: return empty fields
    return [''] * 18

# Read file
input_file = 'itmaster.txt'
output_file = 'itmaster.csv'

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
        # Clean fields
        row = [field.replace('\\n', '').strip() for field in row]
        rows.append(row)

# Write CSV
with open(output_file, 'w', newline='', encoding='utf-8') as f:
    writer = csv.writer(f)
    writer.writerow([
        'RecordType', 'Field1', 'PartNumber', 'Status1', 'Number1', 'Status2', 
        'Date', 'Description', 'Unit', 'PartNumber2', 'Codes', 'Number2', 
        'Date2', 'Number3', 'Number4', 'Price', 'Code2', 'Number5'
    ])
    writer.writerows(rows)

print(f'Successfully created {output_file} with {len(rows)} data rows')
