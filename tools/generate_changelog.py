import requests
import os

# GitHub 仓库信息（可修改为任意公开项目）
OWNER = "Robert-Stackflow"   # 仓库拥有者
REPO = "CloudOTP"    # 仓库名

# GitHub API 端点
RELEASES_URL = f"https://api.github.com/repos/{OWNER}/{REPO}/releases"

# CHANGELOG 文件路径
CHANGELOG_FILE = "CHANGELOG.md"

def fetch_releases():
    response = requests.get(RELEASES_URL)
    response.raise_for_status()
    return response.json()

def format_release(release):
    tag = release["tag_name"]
    name = release["name"] or tag
    date = release["published_at"][:10]
    body = release["body"] or ""
    return f"## {name} ({date})\n\n{body.strip()}\n"

def generate_changelog(releases):
    lines = [f"# Changelog for {OWNER}/{REPO}\n"]
    for release in releases:
        lines.append(format_release(release))
    return "\n---\n\n".join(lines)

def write_changelog(content):
    with open(CHANGELOG_FILE, "w", encoding="utf-8") as f:
        f.write(content)
    print(f"CHANGELOG.md 已生成，共包含 {content.count('## ')} 个版本")

if __name__ == "__main__":
    releases = fetch_releases()
    changelog = generate_changelog(releases)
    write_changelog(changelog)
