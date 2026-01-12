# Try different ways to read the file
try:
    with open('PO2.txt', 'rb') as f:
        content_bytes = f.read()
    print(f'File size (bytes): {len(content_bytes)}')
    print(f'First 200 bytes: {content_bytes[:200]}')
    
    # Try UTF-8
    try:
        content = content_bytes.decode('utf-8')
        lines = content.split('\n')
        print(f'UTF-8: {len(lines)} lines')
        if len(lines) > 1:
            print(f'Line 1 (first 100 chars): {lines[1][:100]}')
    except:
        print('UTF-8 decode failed')
        
except Exception as e:
    print(f'Error: {e}')
