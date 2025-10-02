import os, sys, subprocess, venv, platform, re, time
from urllib.parse import urljoin

BASE_URL = "https://www.raspundelistetel.ro/ro/fisiere-pentru-descarcare"
DOWNLOAD_DIR = "downloads_raspundel_istetel"
REQUIRED = ["requests", "bs4"]
VENV_DIR = ".venv"
VENV_PYTHON = os.path.join(VENV_DIR, "Scripts", "python.exe")
FLAG = "--inside-venv"

def setup_venv():
    """Create and activate venv if not already running inside it."""
    # Detect if already restarted
    if FLAG in sys.argv:
        return  # already in venv, proceed normally

    if not os.path.exists(VENV_DIR):
        print("⚙️  Creating venv...")
        subprocess.run([sys.executable, "-m", "venv", VENV_DIR], check=True)

    print("📦 Installing dependencies...")
    subprocess.run([VENV_PYTHON, "-m", "pip", "install", "-U", "pip", "requests", "bs4"], check=True)

    print("🚀 Restarting inside venv...\n")
    os.execv(VENV_PYTHON, [VENV_PYTHON] + sys.argv + [FLAG])  # restart once

def download_all():
    # Imports after ensuring venv is set up
    import requests
    from bs4 import BeautifulSoup

    session = requests.Session()
    session.timeout = 60
    
    try:
        os.makedirs(DOWNLOAD_DIR, exist_ok=True)
        url = BASE_URL
        links = []

        while url:
            print(f"\n🌐 {url}")
            response = session.get(url, timeout=15)
            soup = BeautifulSoup(response.text, "html.parser")
            for opt in soup.select("select.js_downloads-select option"):
                href = opt.get("value")
                if href and href.endswith(".bnl"):
                    name = re.search(r"([^/\\]+\.(?:BNL|bnl))", opt.text)
                    links.append((name.group(1) if name else os.path.basename(href), href))
            nxt = soup.select_one("ul.pagination li a[rel='next']")
            url = urljoin(BASE_URL, nxt["href"]) if nxt else None
            time.sleep(1)

        print(f"\n📦 Total files: {len(links)}")
        for name, link in links:
            path = os.path.join(DOWNLOAD_DIR, name)
            if os.path.exists(path):
                print(f"✅ {name} exists")
                continue
            print(f"⬇️ {name}")
            try:
                response = session.get(link, stream=True, timeout=60)
                with open(path, "wb") as f:
                    for chunk in response.iter_content(8192):
                        f.write(chunk)
                response.close()
                print(f"✅ Done {name}")
            except Exception as e:
                print(f"❌ {name}: {e}")
    finally:
        session.close()
        print("Session closed")

if __name__ == "__main__":
    try:
        print("Starting script")
        setup_venv()
        print("Venv setup complete")
        download_all()
        print("Download all complete")
    finally:
        print("Exiting...")
        sys.exit(0)