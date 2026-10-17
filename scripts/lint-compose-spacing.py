import re
import sys
from pathlib import Path

ROOT: Path = Path(__file__).resolve().parents[1]
ROOT_SECTIONS: set[str] = {"configs", "networks", "secrets", "services", "volumes"}
CHILD_SECTIONS: set[str] = {"configs", "networks", "secrets", "services", "volumes"}
KEY_PATTERN: re.Pattern[str] = re.compile(pattern=r"^([A-Za-z0-9_.-]+):(?:\s|$)")


def blank_separator_count(lines: list[str], line_index: int) -> int:
    previous_index: int = line_index - 1
    while previous_index >= 0 and lines[previous_index].lstrip().startswith("#"):
        previous_index -= 1
    blank_count: int = 0
    while previous_index >= 0 and not lines[previous_index].strip():
        blank_count += 1
        previous_index -= 1
    return blank_count


def lint_file(path: Path) -> list[str]:
    lines: list[str] = path.read_text(encoding="utf-8").splitlines()
    errors: list = []
    current_section: str | None = None
    seen_child_section: set[str] = set()
    seen_root_mapping: bool = False

    for line_index, line in enumerate(lines):
        if not line.strip() or line.lstrip().startswith("#"):
            continue

        if not line.startswith((" ", "\t")):
            match = KEY_PATTERN.match(line)
            if not match:
                current_section = None
                continue
            current_section = match.group(1)
            seen_child_section.discard(current_section)
            if current_section in ROOT_SECTIONS and seen_root_mapping:
                blank_count = blank_separator_count(lines=lines, line_index=line_index)
                if blank_count == 0:
                    errors.append(f"{path}:{line_index + 1}: add a blank line before the {current_section} section")
                elif blank_count > 1:
                    errors.append(f"{path}:{line_index + 1}: keep only one blank line before the {current_section} section")
            seen_root_mapping = True
            continue

        if current_section not in CHILD_SECTIONS or not line.startswith("  ") or line.startswith("   "):
            continue

        match = KEY_PATTERN.match(line[2:])
        if not match:
            continue
        if current_section in seen_child_section:
            label: str = "service" if current_section == "services" else f"{current_section[:-1]}"
            blank_count = blank_separator_count(lines=lines, line_index=line_index)
            if blank_count == 0:
                errors.append(f"{path}:{line_index + 1}: add a blank line before this {label} block")
            elif blank_count > 1:
                errors.append(f"{path}:{line_index + 1}: keep only one blank line before this {label} block")
        seen_child_section.add(current_section)

    return errors


def main() -> int:
    compose_files: list[Path] = sorted(ROOT.rglob(pattern="compose.yaml"))
    errors: list[str] = [error for path in compose_files for error in lint_file(path=path)]
    if errors:
        print(*errors, sep="\n")
        return 1
    print(f"Compose spacing is valid in {len(compose_files)} files.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
