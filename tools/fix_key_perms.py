import os
import subprocess
import sys

def fix_perms(filepath):
    filepath = os.path.abspath(filepath)
    username = os.environ.get('USERNAME')
    # reset
    subprocess.run(["icacls", filepath, "/reset"], capture_output=True)
    # inheritance:r
    subprocess.run(["icacls", filepath, "/inheritance:r"], capture_output=True)
    # grant user:R
    res = subprocess.run(["icacls", filepath, "/grant:r", f"{username}:R"], capture_output=True, text=True)
    print("icacls result:", res.stdout.strip())

if __name__ == "__main__":
    target = sys.argv[1] if len(sys.argv) > 1 else "oracle_access.key"
    fix_perms(target)
