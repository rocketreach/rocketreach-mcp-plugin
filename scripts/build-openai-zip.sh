#!/usr/bin/env bash
#
# Build the ZIP to upload to OpenAI: platform.openai.com → Plugins → RocketReach →
# Upload plugin to make changes. Writes dist/rocketreach-openai-<version>.zip.
#
#   ./scripts/build-openai-zip.sh
#   VERSION=3.1.0 ./scripts/build-openai-zip.sh   # use a different version in the ZIP
#
# OpenAI only needs the version to differ from the published one. VERSION changes
# the ZIP's copy of the manifest, not the file in the repo.
#
# The ZIP uses OpenAI's Codex package format: .codex-plugin/plugin.json, .mcp.json,
# skills/ and the icon in assets/. It leaves out the root mcp.json, which runs
# mcp-remote locally for Cursor. OpenAI rejects local MCP configuration
# (mcp_configuration_excluded), and it reads a root mcp.json automatically in some
# package layouts. The Claude and Cursor manifests are left out too.
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
cd "$repo_root"

stage="$(mktemp -d)"
trap 'rm -rf "$stage"' EXIT

mkdir -p "$stage/.codex-plugin" dist
cp .mcp.json LICENSE README.md "$stage/"
cp -R skills assets "$stage/"

# Validate against OpenAI's submission limits and write the staged manifest.
version="$(python3 -I - "$stage/.codex-plugin/plugin.json" "${VERSION:-}" <<'PY'
import json, os, re, sys, unicodedata

out_path, version_override = sys.argv[1], sys.argv[2]
errors = []

# interface.category values OpenAI accepts (plugin_category_unknown).
CATEGORIES = [
    "Productivity", "Creativity", "Developer Tools", "Business & Operations", "Data & Analytics",
    "Communication", "Education & Research", "Security", "Finance", "Healthcare", "Travel",
    "Entertainment", "Other",
]


def luminance(hex_color):
    channels = [int(hex_color[i:i + 2], 16) / 255 for i in (1, 3, 5)]
    channels = [c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4 for c in channels]
    return 0.2126 * channels[0] + 0.7152 * channels[1] + 0.0722 * channels[2]

manifest = json.load(open(".codex-plugin/plugin.json"))
if version_override:
    manifest["version"] = version_override
version = manifest.get("version", "")
if not re.fullmatch(r"\d+\.\d+\.\d+(?:[-+][0-9A-Za-z.-]+)?", version):
    errors.append(f"version {version!r} is not a semantic version")

name = manifest.get("name", "")
if not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9_-]{0,63}", name):
    errors.append(f"name {name!r} must be up to 64 ASCII letters, digits, _ or -")
if not manifest.get("description") or len(manifest["description"]) > 1024:
    errors.append("description is required and must be 1,024 characters or fewer")
for field, url in (("homepage", manifest.get("homepage")), ("author.url", manifest.get("author", {}).get("url"))):
    if url is not None and not str(url).startswith("https://"):
        errors.append(f"{field} must be an HTTPS URL")

if manifest.get("skills") != "./skills/":
    errors.append('"skills" must be "./skills/" or OpenAI ignores the skills')
if manifest.get("mcpServers") != "./.mcp.json":
    errors.append('"mcpServers" must be "./.mcp.json"')
if "apps" in manifest:
    errors.append('"apps" is not allowed in a ZIP upload')

ui = manifest.get("interface", {})
limits = {"displayName": 30, "shortDescription": 30, "longDescription": 4000, "developerName": 80}
for field, limit in limits.items():
    value = ui.get(field, "")
    if not value:
        errors.append(f"interface.{field} is required")
    elif len(value) > limit:
        errors.append(f"interface.{field} is {len(value)} characters (limit {limit})")
for field in ("websiteURL", "supportURL", "privacyPolicyURL", "termsOfServiceURL"):
    if not str(ui.get(field, "")).startswith("https://"):
        errors.append(f"interface.{field} must be an HTTPS URL")
prompts = ui.get("defaultPrompt", [])
if len(prompts) > 3:
    errors.append(f"interface.defaultPrompt has {len(prompts)} prompts (limit 3)")
for prompt in prompts:
    if len(prompt) > 128:
        errors.append(f"default prompt is {len(prompt)} characters (limit 128): {prompt[:40]}...")
    if re.search(r"(^|\s)@\w", prompt):
        errors.append(f"default prompt must not @mention a server: {prompt[:40]}...")
normalized = [" ".join(unicodedata.normalize("NFKC", p).split()) for p in prompts]
if len(set(normalized)) != len(normalized):
    errors.append("interface.defaultPrompt entries must be unique")
if "category" in ui and ui["category"] not in CATEGORIES:
    errors.append(f"interface.category {ui['category']!r} must be one of: {', '.join(CATEGORIES)}")
color = ui.get("brandColor")
if color is not None:
    if not re.fullmatch(r"#[0-9A-Fa-f]{6}", str(color)):
        errors.append("interface.brandColor must be a six-digit hex color such as #1ABCFE")
    elif 1.05 / (luminance(color) + 0.05) < 2:
        errors.append("interface.brandColor needs at least 2:1 contrast against white")
stage_root = os.path.realpath(os.path.dirname(os.path.dirname(out_path)))
for field in ("logo", "composerIcon"):
    path = ui.get(field, "")
    staged = os.path.realpath(os.path.join(stage_root, path)) if path else ""
    if not staged.startswith(stage_root + os.sep) or not os.path.isfile(staged):
        errors.append(f"interface.{field} must point to a file in the package")

servers = json.load(open(".mcp.json")).get("mcpServers", {})
for name, server in servers.items():
    if "command" in server or not str(server.get("url", "")).startswith("https://"):
        errors.append(f".mcp.json server {name!r} must be a remote HTTPS server")

plugin_name = manifest.get("name", "")
for skill in sorted(os.listdir("skills")):
    if skill == ".DS_Store":
        continue
    path = os.path.join("skills", skill, "SKILL.md")
    if not os.path.isfile(path):
        errors.append(f"{path} is missing")
        continue
    front = re.match(r"---\n(.*?)\n---\n", open(path).read(), re.S)
    if not front:
        errors.append(f"{path} has no YAML front matter")
        continue
    lines = front.group(1).splitlines()
    fields = {}
    for i, line in enumerate(lines):
        match = re.match(r"(name|description):[ \t]*(.*)$", line)
        if not match:
            continue
        value = match.group(2).strip()
        wraps = i + 1 < len(lines) and lines[i + 1][:1] in (" ", "\t")
        if value[:1] in ("|", ">") or wraps:
            errors.append(f"{path} {match.group(1)} must fit on one line")
        fields[match.group(1)] = value
    if not fields.get("name") or not fields.get("description"):
        errors.append(f"{path} needs a name and a description")
    elif len(fields["description"]) > 1024:
        errors.append(f"{path} description is over 1,024 characters")
    elif len(f"{plugin_name}:{fields['name']}") > 64:
        errors.append(f"{path} plugin:skill name is over 64 characters")

if errors:
    print("Package checks failed:", *errors, sep="\n  ", file=sys.stderr)
    sys.exit(1)

with open(out_path, "w") as f:
    json.dump(manifest, f, indent=2, ensure_ascii=False)
    f.write("\n")
print(version)
PY
)"

zip_path="$repo_root/dist/rocketreach-openai-$version.zip"
rm -f "$zip_path"
(cd "$stage" && zip -q -r -X "$zip_path" . -x '*.DS_Store')

echo "Built dist/rocketreach-openai-$version.zip:"
unzip -Z1 "$zip_path" | sed 's/^/  /'
