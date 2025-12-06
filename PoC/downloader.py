"""
Website scraping and file download utilities.
Handles fetching file lists from raspundelistetel.ro and downloading .bnl files.
"""

import os
import re
import time
from typing import List, Tuple, Set
from urllib.parse import urljoin


BASE_URL = "https://www.raspundelistetel.ro/ro/fisiere-pentru-descarcare"


def fetch_website_file_list(base_url: str = BASE_URL) -> List[Tuple[str, str]]:
    """
    Scrape the website and return list of available .bnl files.
    
    Args:
        base_url: Base URL to start scraping from
        
    Returns:
        List of (filename, url) tuples
    """
    import requests
    from bs4 import BeautifulSoup
    
    session = requests.Session()
    files = []
    url = base_url
    
    try:
        while url:
            print(f"🌐 Fetching: {url}")
            
            try:
                response = session.get(url, timeout=15)
                response.raise_for_status()
            except Exception as e:
                print(f"❌ Failed to fetch page {url}: {e}")
                break
            
            soup = BeautifulSoup(response.text, "html.parser")
            
            # Find all .bnl file options
            for opt in soup.select("select.js_downloads-select option"):
                href = opt.get("value")
                if href and href.endswith(".bnl"):
                    # Ensure absolute URL
                    abs_href = urljoin(url, href)
                    
                    # Extract filename from option text
                    name_match = re.search(r"([^/\\]+\.(?:BNL|bnl))", opt.text)
                    filename = name_match.group(1) if name_match else os.path.basename(abs_href)
                    
                    files.append((filename, abs_href))
            
            # Find next page
            next_link = soup.select_one("ul.pagination li a[rel='next']")
            url = urljoin(base_url, next_link["href"]) if next_link else None
            
            # Be respectful to the server
            time.sleep(1)
    
    finally:
        session.close()
    
    print(f"✅ Found {len(files)} files on website")
    return files


def download_file(url: str, destination: str, filename: str) -> bool:
    """
    Download a single file with progress indication.
    
    Args:
        url: URL to download from
        destination: Directory to save the file
        filename: Name to save the file as
        
    Returns:
        True if successful, False otherwise
    """
    import requests
    
    file_path = os.path.join(destination, filename)
    
    try:
        print(f"⬇️  Downloading: {filename}")
        print(f"   Source: {url}")
        
        response = requests.get(url, stream=True, timeout=60)
        response.raise_for_status()
        
        # Get total size if available
        total_size = int(response.headers.get('content-length', 0))
        
        with open(file_path, 'wb') as f:
            if total_size == 0:
                # No content-length header, just download
                for chunk in response.iter_content(chunk_size=8192):
                    if chunk:
                        f.write(chunk)
            else:
                # Show progress
                downloaded = 0
                for chunk in response.iter_content(chunk_size=8192):
                    if chunk:
                        f.write(chunk)
                        downloaded += len(chunk)
                        progress = (downloaded / total_size) * 100
                        print(f"\r   Progress: {progress:.1f}%", end='', flush=True)
                print()  # New line after progress
        
        response.close()
        print(f"✅ Downloaded: {filename}")
        return True
        
    except Exception as e:
        print(f"❌ Failed to download {filename}: {e}")
        # Clean up partial download
        if os.path.exists(file_path):
            try:
                os.remove(file_path)
            except:
                pass
        return False


def download_missing_files(
    website_files: List[Tuple[str, str]], 
    local_files: Set[str], 
    download_dir: str
) -> int:
    """
    Download only files that are not already in local_files.
    
    Args:
        website_files: List of (filename, url) tuples from website
        local_files: Set of filenames already downloaded
        download_dir: Directory to save downloads to
        
    Returns:
        Number of files successfully downloaded
    """
    # Ensure download directory exists
    os.makedirs(download_dir, exist_ok=True)
    
    # Filter to only missing files
    to_download = [(name, url) for name, url in website_files if name not in local_files]
    
    if not to_download:
        print("✅ All files are already downloaded")
        return 0
    
    print(f"\n📥 Need to download {len(to_download)} files")
    
    success_count = 0
    for filename, url in to_download:
        if download_file(url, download_dir, filename):
            success_count += 1
        # Be nice to the server
        time.sleep(0.5)
    
    print(f"\n✅ Successfully downloaded {success_count}/{len(to_download)} files")
    return success_count
