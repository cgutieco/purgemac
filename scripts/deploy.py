import os
import shutil
import subprocess
import sys

# --- Configuration ---
PROJECT_NAME = "purgemac"
SCHEME_NAME = "PurgeMac"  # Case sensitive!
APP_NAME = "purgemac.app" # Output from xcodebuild
DMG_NAME = "purgemac.dmg"
BUILD_DIR = os.path.abspath("build")
# Output DMG to the root of the project
OUTPUT_DMG_PATH = os.path.abspath(DMG_NAME)

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

def main():
    check_dependencies()
    build_app()
    create_dmg()

if __name__ == "__main__":
    main()
