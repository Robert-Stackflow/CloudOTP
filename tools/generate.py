import os
import shutil
import re
import zipfile

repo_path = "D:\\Repositories\\CloudOTP"
apks_path = "D:\\Repositories\\CloudOTP\\build\\app\\outputs\\flutter-apk"
windows_release_path = (
    "D:\\Repositories\\CloudOTP\\build\\windows\\x64\\runner\\Release"
)
downloads_path = "D:\\Ruida\\Downloads"
dll_path = "D:\\Repositories\\CloudOTP\\dll\\sqlite3.dll"
iss_path = "D:\\Repositories\\CloudOTP\\tools\\CloudOTP.iss"
iscc_path = "D:\\Program Files\\Inno Setup 6\\ISCC.exe"


# get the downloads path
def get_downloads_path(version):
    path = os.path.join(downloads_path, version)
    if not os.path.exists(path):
        os.mkdir(path)
    return path


# rename the apk file
def rename_apk(version):
    print("start rename apk...")
    for root, dirs, files in os.walk(apks_path):
        for file in files:
            match = re.match(r"^app-(.*)release.apk$", file)
            if match:
                abi = match.group(1).rstrip("-")
                if abi == "":
                    new_file = f"CloudOTP-{version}.apk"
                else:
                    new_file = f"CloudOTP-{version}-{abi}.apk"
                old_path = os.path.join(root, file)
                new_path = os.path.join(get_downloads_path(version), new_file)
                shutil.copy(old_path, new_path)
                print(f"rename {file} to {new_file}")
    print("rename apk done.")


# zip the windows runner
def zip_windows(version):
    print("start zip windows runner...")
    print("copy sqlite3.dll to windows runner...")
    shutil.copy(dll_path, windows_release_path)
    print("copy sqlite3.dll done.")
    print("zip windows runner...")
    zip_path = os.path.join(get_downloads_path(version), "CloudOTP-" + version + ".zip")
    with zipfile.ZipFile(
        zip_path,
        "w",
        zipfile.ZIP_DEFLATED,
    ) as zipf:
        for root, dirs, files in os.walk(windows_release_path):
            for file in files:
                abs_path = os.path.join(root, file)
                zipf.write(abs_path, os.path.relpath(abs_path, windows_release_path))
    print("zip windows runner done.")


# generate the installer
def generate_installer(version):
    print("start generate installer...")
    # 打开iss文件，修改版本号，即替换#define MyAppVersion "2.1.0"中的2.1.0为指定的版本号
    with open(iss_path, "r") as f:
        lines = f.readlines()
    with open(iss_path, "w") as f:
        for line in lines:
            f.write(
                re.sub(
                    r'#define MyAppVersion "(.*)"',
                    f'#define MyAppVersion "{version}"',
                    line,
                )
            )
    os.system(f'"{iscc_path}" {iss_path}')
    print("generate installer done.")


def release_apk(version):
    print("start generate release apk...")
    os.system("flutter build apk")
    print("release apk done.")


def release_apk_abi(version):
    print("start generate release apk with abi...")
    os.system("flutter build apk --split-per-abi")
    print("release apk with abi done.")


def release_windows(version):
    print("start generate release windows runner...")
    os.system("flutter build windows")
    print("release windows runner done.")


# 使用argparse处理命令行参数，
# -v或--version参数指定版本号，
# -a或--android参数指定是否生成apk，
# -w或--windows参数指定是否生成windows，
# -s或--split参数指定是否生成abi分包apk
if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser()
    parser.add_argument("-v", "--version", help="version number")
    parser.add_argument("-d", "--default", help="run all config", action="store_true")
    parser.add_argument(
        "-a", "--android", help="release android apk", action="store_true"
    )
    parser.add_argument(
        "-w", "--windows", help="release windows runner", action="store_true"
    )
    parser.add_argument(
        "-s", "--split", help="release android apk with abi", action="store_true"
    )
    args = parser.parse_args()

    if args.version:
        version = args.version
        print(f"version: {version}")
        if args.default:
            release_apk(version)
            release_apk_abi(version)
            release_windows(version)
        else:
            if args.android:
                release_apk(version)
            if args.split:
                release_apk_abi(version)
            if args.windows:
                release_windows(version)
        rename_apk(version)
        zip_windows(version)
        generate_installer(version)
    else:
        parser.print_help()
