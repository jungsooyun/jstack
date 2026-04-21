# Installing JStack for Codex

Enable JStack skills in Codex via native skill discovery. Clone once, then symlink.

## Prerequisites

- Git

## Installation

1. **Clone the JStack repository:**
   ```bash
   git clone https://github.com/jungsooyun/jstack.git ~/.codex/jstack
   ```

2. **Create the skills symlink:**
   ```bash
   mkdir -p ~/.codex/skills ~/.agents/skills
   ln -s ~/.codex/jstack/skills ~/.codex/skills/jstack
   ln -s ~/.codex/jstack/skills ~/.agents/skills/jstack
   ```

   **Windows (PowerShell):**
   ```powershell
   New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.codex\skills"
   New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.agents\skills"
   cmd /c mklink /J "$env:USERPROFILE\.codex\skills\jstack" "$env:USERPROFILE\.codex\jstack\skills"
   cmd /c mklink /J "$env:USERPROFILE\.agents\skills\jstack" "$env:USERPROFILE\.codex\jstack\skills"
   ```

3. **Restart Codex** (quit and relaunch the CLI) to discover the skills.

## Migrating from Superpowers

If you installed Superpowers before JStack, keep the compatibility alias until all
project guidance has been updated:

1. **Rename or clone the repo:**
   ```bash
   mv ~/.codex/superpowers ~/.codex/jstack
   ln -s ~/.codex/jstack ~/.codex/superpowers
   ```

2. **Create the new skills symlinks** (step 2 above).

3. **Optional compatibility alias:**
   ```bash
   ln -s ~/.codex/jstack/skills ~/.codex/skills/superpowers
   ```

4. **Restart Codex.**

## Verify

```bash
ls -la ~/.codex/skills/jstack ~/.agents/skills/jstack
```

You should see symlinks (or junctions on Windows) pointing to your JStack skills directory.

## Updating

```bash
cd ~/.codex/jstack && git pull
```

Skills update instantly through the symlink.

## Uninstalling

```bash
rm ~/.codex/skills/jstack ~/.agents/skills/jstack
```

Optionally delete the clone: `rm -rf ~/.codex/jstack`.
