import os
import shutil
import subprocess
import sys
import boto3
from botocore.exceptions import NoCredentialsError

# --- Configuration ---
PROJECT_NAME = "purgemac"
SCHEME_NAME = "PurgeMac"  # Case sensitive!
APP_NAME = "purgemac.app" # Output from xcodebuild
DMG_NAME = "purgemac.dmg"
BUILD_DIR = os.path.abspath("build")
# Output DMG to the root of the project
OUTPUT_DMG_PATH = os.path.abspath(DMG_NAME)

# R2 Configuration (Load from Environment Variables for security)
R2_ACCOUNT_ID = os.getenv("R2_ACCOUNT_ID")
R2_ACCESS_KEY_ID = os.getenv("R2_ACCESS_KEY_ID")
R2_SECRET_ACCESS_KEY = os.getenv("R2_SECRET_ACCESS_KEY")
R2_BUCKET_NAME = os.getenv("R2_BUCKET_NAME")

def run_command(command, cwd=None):
    """Runs a shell command and raises an error if it fails."""
    print(f"🚀 Running: {' '.join(command)}")
    result = subprocess.run(command, cwd=cwd, text=True, capture_output=False)
    if result.returncode != 0:
        print(f"❌ Command failed: {' '.join(command)}")
        sys.exit(result.returncode)

def check_dependencies():
    """Checks if necessary tools are installed."""
    if not shutil.which("xcodebuild"):
        print("❌ Error: xcodebuild not found. Install Xcode.")
        sys.exit(1)
    if not shutil.which("create-dmg"):
        print("❌ Error: create-dmg not found. Install it via 'brew install create-dmg'.")
        sys.exit(1)
    try:
        import boto3
    except ImportError:
        print("❌ Error: boto3 not found. Install it via 'pip install boto3'.")
        sys.exit(1)

def build_app():
    """Builds the macOS application."""
    print("\n🔨 Cleaning and Building Project...")
    if os.path.exists(BUILD_DIR):
        shutil.rmtree(BUILD_DIR)
    
    cmd = [
        "xcodebuild", "clean", "build",
        "-project", f"{PROJECT_NAME}.xcodeproj",
        "-scheme", SCHEME_NAME,
        "-configuration", "Release",
        "-derivedDataPath", BUILD_DIR,
        "CODE_SIGN_IDENTITY=-",         # Ad-hoc signing
        "CODE_SIGNING_REQUIRED=NO",
        "CODE_SIGNING_ALLOWED=YES"
    ]
    run_command(cmd)

def create_dmg():
    """Packages the .app into a .dmg using create-dmg."""
    print("\n📦 Creating DMG...")
    
    # Remove existing DMG if it exists
    if os.path.exists(OUTPUT_DMG_PATH):
        os.remove(OUTPUT_DMG_PATH)

    app_path = os.path.join(BUILD_DIR, "Build/Products/Release", APP_NAME)

    if not os.path.exists(app_path):
        print(f"❌ Error: App not found at {app_path}")
        sys.exit(1)

    # Force manual ad-hoc signing again just in case
    print("✍️  Signing Application...")
    run_command(["codesign", "--force", "--deep", "-s", "-", app_path])

    cmd = [
        "create-dmg",
        "--volname", "PurgeMac Installer",
        "--window-pos", "200", "120",
        "--window-size", "600", "400",
        "--icon-size", "100",
        "--icon", APP_NAME, "175", "120",
        "--hide-extension", APP_NAME,
        "--app-drop-link", "425", "120",
        "--no-internet-enable",
        OUTPUT_DMG_PATH,
        app_path
    ]
    run_command(cmd)
    
    if os.path.exists(OUTPUT_DMG_PATH):
        print(f"✅ DMG Created successfully: {OUTPUT_DMG_PATH}")
    else:
        print("❌ Error: DMG creation failed.")
        sys.exit(1)

def upload_to_r2():
    """Uploads the DMG to Cloudflare R2."""
    print("\n☁️  Uploading to Cloudflare R2...")
    
    if not all([R2_ACCOUNT_ID, R2_ACCESS_KEY_ID, R2_SECRET_ACCESS_KEY, R2_BUCKET_NAME]):
        print("❌ Error: Missing R2 environment variables.")
        print("Please export R2_ACCOUNT_ID, R2_ACCESS_KEY_ID, R2_SECRET_ACCESS_KEY, and R2_BUCKET_NAME.")
        sys.exit(1)

    endpoint_url = f"https://{R2_ACCOUNT_ID}.r2.cloudflarestorage.com"
    
    s3 = boto3.client('s3',
        endpoint_url=endpoint_url,
        aws_access_key_id=R2_ACCESS_KEY_ID,
        aws_secret_access_key=R2_SECRET_ACCESS_KEY
    )

    try:
        print(f"Uploading {OUTPUT_DMG_PATH} to bucket {R2_BUCKET_NAME}...")
        s3.upload_file(
            OUTPUT_DMG_PATH, 
            R2_BUCKET_NAME, 
            DMG_NAME,
            ExtraArgs={'ContentType': 'application/x-diskcopy'}
        )
        print(f"✅ Upload successful!")
    except Exception as e:
        print(f"❌ Upload failed: {e}")
        sys.exit(1)

def main():
    check_dependencies()
    build_app()
    create_dmg()
    upload_to_r2()

if __name__ == "__main__":
    main()
