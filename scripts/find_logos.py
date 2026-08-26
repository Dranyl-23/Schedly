import urllib.request
import re

headers = {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'}

sites = [
    'https://umindanao.edu.ph',
    'https://www.cjc.edu.ph',
    'https://dssc.edu.ph',
    'https://www.addu.edu.ph',
    'https://www.usep.edu.ph'
]

for url in sites:
    try:
        req = urllib.request.Request(url, headers=headers)
        with urllib.request.urlopen(req, timeout=10) as resp:
            html = resp.read().decode('utf-8', errors='ignore')
            logos = re.findall(r'(https?://[^\s"\'<>]+(?:logo|seal|brand)[^\s"\'<>]*\.(?:png|jpg|svg|webp))', html, re.IGNORECASE)
            print(f'=== {url} ===')
            for l in set(logos[:5]):
                print(l)
    except Exception as e:
        print(f'Error {url}: {e}')
