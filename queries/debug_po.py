with open('PO.TXT', 'r', encoding='utf-8') as f:
    lines = f.readlines()

print(f'Total lines: {len(lines)}')
if len(lines) > 1:
    print(f'Line 1 length: {len(lines[1])}')
    print(f'Line 1 starts with: {repr(lines[1][:20])}')
    print(f'Line 1 contains 8888RTV: {"8888RTV" in lines[1]}')



