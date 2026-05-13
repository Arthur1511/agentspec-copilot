"""Convert inline skill descriptions to YAML block scalar format (description: |)."""
import re
import textwrap
from pathlib import Path

skills_dir = Path(".github/skills")
changed = []

for skill_file in sorted(skills_dir.glob("*/SKILL.md")):
    content = skill_file.read_text(encoding="utf-8")
    # Only match inline descriptions (not already block scalar with |)
    m = re.match(r'^(---\nname: .+\n)description: (?!\|)(.+?)(\n---)', content, re.DOTALL)
    if not m:
        continue
    prefix = m.group(1)
    desc = m.group(2).strip()
    suffix = m.group(3)
    rest = content[m.end():]

    # Word-wrap to 78 chars (80 - 2 indent), indent each line with 2 spaces for YAML block scalar
    wrapped = textwrap.fill(desc, width=78)
    indented = "\n".join("  " + line for line in wrapped.split("\n"))

    new_content = f"{prefix}description: |\n{indented}{suffix}{rest}"
    skill_file.write_text(new_content, encoding="utf-8")
    changed.append(skill_file.name)

print(f"Updated {len(changed)} files:")
for f in changed:
    print(f"  {f}")
