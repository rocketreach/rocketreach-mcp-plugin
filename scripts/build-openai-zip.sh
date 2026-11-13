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
import json, os, re, sys

out_path, version_override = sys.argv[1], sys.argv[2]
errors = []

manifest = json.load(open(".codex-plugin/plugin.json"))
if version_override:
    manifest["version"] = version_override
version = manifest.get("version", "")
if not re.fullmatch(r"\d+\.\d+\.\d+(?:[-+][0-9A-Za-z.-]+)?", version):
    errors.append(f"version {version!r} is not a semantic version")

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
for field in ("logo", "composerIcon"):
    path = ui.get(field, "")
    if not path or not os.path.isfile(path):
        errors.append(f"interface.{field} must point to a file in the package")

servers = json.load(open(".mcp.json")).get("mcpServers", {})
for name, server in servers.items():
    if "command" in server or not str(server.get("url", "")).startswith("https://"):
        errors.append(f".mcp.json server {name!r} must be a remote HTTPS server")

plugin_name = manifest.get("name", "")
for skill in sorted(os.listdir("skills")):
    path = os.path.join("skills", skill, "SKILL.md")
    if not os.path.isfile(path):
        errors.append(f"{path} is missing")
        continue
    front = re.match(r"---\n(.*?)\n---\n", open(path).read(), re.S)
    if not front:
        errors.append(f"{path} has no YAML front matter")
        continue
    fields = dict(re.findall(r"^(name|description):\s*(.+)$", front.group(1), re.M))
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
