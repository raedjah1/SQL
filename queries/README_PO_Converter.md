# PO File Converter - Fixed Width to CSV

This tool converts fixed-width PO files (format: `8888RTV`) to CSV format.

## Files

- **`convert_po_to_csv.py`** - The Python script that performs the conversion

## Usage

### Option 1: Convert Specific Files

```bash
python convert_po_to_csv.py <input_file.txt> <output_file.csv>
```

**Example:**
```bash
python convert_po_to_csv.py ADT_RXT_PO_202601091600.txt ADT_RXT_PO_202601091600.csv
```

### Option 2: Convert Default Files

If you run the script without arguments, it will automatically convert the default ADT_RXT_PO files in the current directory:

```bash
python convert_po_to_csv.py
```

This will convert:
- `ADT_RXT_PO_202601091600.txt` → `ADT_RXT_PO_202601091600.csv`
- `ADT_RXT_PO_202601161600.txt` → `ADT_RXT_PO_202601161600.csv`

## Input File Format

The script expects fixed-width PO files with the following structure:

- **Header line**: Starts with `8888HDR` (automatically skipped)
- **Data lines**: Start with `8888RTV` followed by fixed-width fields
- **Footer line**: Starts with `8888FTR` (automatically skipped)

Example input line:
```
8888RTV         0                 5773456                       392                           2741                          1                             CB130T              12          612                 20251222  8.68                11260642                                8996            ADI
```

## Output Format

The CSV file will have the following columns:

1. `RecordType` - Always "8888RTV"
2. `Field1` - First field (usually "0")
3. `Field2` - Second field
4. `Field3` - Third field
5. `Field4` - Fourth field
6. `Field5` - Fifth field
7. `PartNumber` - Part number (may contain spaces)
8. `Quantity` - Quantity
9. `Field8` - Eighth field
10. `Date` - Date in YYYYMMDD format
11. `Price` - Price
12. `Field11` - Eleventh field
13. `Field12` - Twelfth field
14. `VendorName` - Vendor name (may contain spaces)

## Example Output

```csv
RecordType,Field1,Field2,Field3,Field4,Field5,PartNumber,Quantity,Field8,Date,Price,Field11,Field12,VendorName
8888RTV,0,5773456,392,2741,1,CB130T,12,612,20251222,8.68,11260642,8996,ADI
8888RTV,0,5770345,10,4188,2,ADC-AC-X1100,1,837,20251222,330,11311494,220865,ALARM.COM INC
```

## Requirements

- Python 3.x
- No external dependencies (uses only standard library: `csv`, `re`, `sys`, `os`)

## Notes

- The script automatically handles part numbers that contain spaces
- Header and footer lines are automatically skipped
- Empty data rows are automatically filtered out
- The script uses UTF-8 encoding for both input and output files

## Troubleshooting

If you encounter errors:

1. **File not found**: Make sure the input file exists in the current directory or provide the full path
2. **Encoding issues**: The script uses UTF-8 encoding. If your file uses a different encoding, you may need to modify the script
3. **Empty output**: Check that your input file contains `8888RTV` data lines

## Example Workflow

```bash
# Navigate to the queries directory
cd queries

# Convert a specific file
python convert_po_to_csv.py my_po_file.txt my_po_file.csv

# Or convert default files
python convert_po_to_csv.py
```

