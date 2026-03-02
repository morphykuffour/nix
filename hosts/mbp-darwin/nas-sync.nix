# NAS auto-mount and opencode session sync to TrueNAS
# Ensures SMB share is always mounted and sessions are continuously synced
{
  config,
  lib,
  pkgs,
  ...
}: let
  nasMount = "/Volumes/truenas-data";
  smbShare = "//morph:root@truenas/data";
  sessionSrc = "/Users/morph/.opencode/exports/sessions";
  sessionDst = "${nasMount}/opencode-sessions";

  # Python script to convert opencode session JSON to readable text
  sessionConverter = pkgs.writeScript "convert-opencode-sessions.py" ''
    #!${pkgs.python3}/bin/python3
    """Convert opencode session JSON exports to readable text files."""
    import json
    import os
    import sys
    from datetime import datetime
    from pathlib import Path

    SRC = Path("${sessionSrc}")
    DST = Path("${sessionDst}")

    if not SRC.exists():
        print(f"Source directory does not exist: {SRC}", file=sys.stderr)
        sys.exit(0)

    DST.mkdir(parents=True, exist_ok=True)

    # Read last export timestamp to only process new/changed files
    marker = DST / ".last_sync"
    last_sync = 0
    if marker.exists():
        try:
            last_sync = float(marker.read_text().strip())
        except Exception:
            last_sync = 0

    count = 0
    errors = 0
    now = 0

    for f in sorted(SRC.glob("*.json")):
        if f.name in ("current-session.json", "last_export.txt"):
            continue
        mtime = f.stat().st_mtime
        if mtime > now:
            now = mtime
        if mtime <= last_sync:
            continue
        try:
            data = json.loads(f.read_text())
            info = data.get("info", {})

            title = info.get("title", "untitled")
            slug = info.get("slug", "unknown")
            sid = info.get("id", f.stem)
            directory = info.get("directory", "")
            time_info = info.get("time", {})
            created = time_info.get("created", 0)
            updated = time_info.get("updated", 0)

            created_str = datetime.fromtimestamp(created / 1000).strftime("%Y-%m-%d %H:%M:%S") if created else "unknown"
            updated_str = datetime.fromtimestamp(updated / 1000).strftime("%Y-%m-%d %H:%M:%S") if updated else "unknown"

            lines = []
            lines.append(f"{'='*80}")
            lines.append(f"Session: {sid}")
            lines.append(f"Title:   {title}")
            lines.append(f"Slug:    {slug}")
            lines.append(f"Dir:     {directory}")
            lines.append(f"Created: {created_str}")
            lines.append(f"Updated: {updated_str}")
            lines.append(f"{'='*80}")
            lines.append("")

            messages = data.get("messages", [])
            for msg in messages:
                msg_info = msg.get("info", {})
                role = msg_info.get("role", "unknown")

                parts = msg.get("content", [])
                text_parts = []
                for part in parts:
                    if isinstance(part, dict):
                        if part.get("type") == "text":
                            text_parts.append(part.get("text", ""))
                        elif part.get("type") == "tool_use":
                            tool_name = part.get("name", "unknown_tool")
                            tool_input = part.get("input", {})
                            text_parts.append(f"[Tool: {tool_name}]")
                            if isinstance(tool_input, dict):
                                for k, v in tool_input.items():
                                    val_str = str(v)
                                    if len(val_str) > 200:
                                        val_str = val_str[:200] + "..."
                                    text_parts.append(f"  {k}: {val_str}")
                        elif part.get("type") == "tool_result":
                            content = part.get("content", "")
                            if isinstance(content, list):
                                for c in content:
                                    if isinstance(c, dict) and c.get("type") == "text":
                                        result_text = c.get("text", "")
                                        if len(result_text) > 500:
                                            result_text = result_text[:500] + "...(truncated)"
                                        text_parts.append(f"[Result]: {result_text}")
                            elif isinstance(content, str):
                                if len(content) > 500:
                                    content = content[:500] + "...(truncated)"
                                text_parts.append(f"[Result]: {content}")

                if text_parts:
                    role_label = "USER" if role == "user" else "ASSISTANT" if role == "assistant" else role.upper()
                    lines.append(f"--- {role_label} ---")
                    lines.append("\n".join(text_parts))
                    lines.append("")

            date_prefix = datetime.fromtimestamp(created / 1000).strftime("%Y%m%d") if created else "00000000"
            safe_slug = "".join(c if c.isalnum() or c in "-_" else "-" for c in slug)[:50]
            out_name = f"{date_prefix}_{safe_slug}.txt"

            (DST / out_name).write_text("\n".join(lines))
            count += 1

        except Exception as e:
            errors += 1
            print(f"Error processing {f.name}: {e}", file=sys.stderr)

    # Also copy raw JSON exports for full fidelity backup
    raw_dst = DST / "raw-json"
    raw_dst.mkdir(parents=True, exist_ok=True)
    for f in sorted(SRC.glob("*.json")):
        dest = raw_dst / f.name
        if not dest.exists() or f.stat().st_mtime > dest.stat().st_mtime:
            import shutil
            shutil.copy2(f, dest)

    # Update marker
    if now > 0:
        marker.write_text(str(now))

    if count > 0 or errors > 0:
        print(f"Synced {count} new/updated sessions ({errors} errors)")
  '';
in {
  environment.systemPackages = [pkgs.python3];

  # Create NAS mount point using a system-level daemon (runs as root)
  launchd.daemons.nas-mount-setup = {
    serviceConfig = {
      Label = "com.morph.nas-mount-setup";
      ProgramArguments = [
        "/bin/bash"
        "-c"
        "mkdir -p ${nasMount} && chown morph:staff ${nasMount}"
      ];
      RunAtLoad = true;
      LaunchOnlyOnce = true;
    };
  };

  # ── 1. NAS auto-mount ────────────────────────────────────────────────
  launchd.user.agents.nas-automount = {
    serviceConfig = {
      Label = "com.morph.nas-automount";
      ProgramArguments = [
        "/bin/bash"
        "-c"
        ''
          MOUNT="${nasMount}"
          SHARE="${smbShare}"

          # Already mounted? Nothing to do.
          /sbin/mount | /usr/bin/grep -q "$MOUNT" && exit 0

          # Create mount point if needed
          [ -d "$MOUNT" ] || /bin/mkdir -p "$MOUNT"

          # Ensure NAS is reachable (Tailscale)
          /sbin/ping -c1 -t3 truenas > /dev/null 2>&1 || exit 0

          /sbin/mount_smbfs "$SHARE" "$MOUNT" >> /tmp/nas-automount.log 2>&1
          echo "$(date): mounted $SHARE → $MOUNT" >> /tmp/nas-automount.log
        ''
      ];
      RunAtLoad = true;
      StartCalendarInterval = [
        {Minute = 0;}
        {Minute = 5;}
        {Minute = 10;}
        {Minute = 15;}
        {Minute = 20;}
        {Minute = 25;}
        {Minute = 30;}
        {Minute = 35;}
        {Minute = 40;}
        {Minute = 45;}
        {Minute = 50;}
        {Minute = 55;}
      ];
      StandardOutPath = "/tmp/nas-automount.stdout.log";
      StandardErrorPath = "/tmp/nas-automount.stderr.log";
      Nice = 10;
      ProcessType = "Background";
      EnvironmentVariables = {
        HOME = "/Users/morph";
      };
    };
  };

  # ── 2. Opencode session sync ──────────────────────────────────────────
  launchd.user.agents.opencode-session-sync = {
    serviceConfig = {
      Label = "com.morph.opencode-session-sync";
      ProgramArguments = [
        "/bin/bash"
        "-c"
        ''
          export PATH="${lib.makeBinPath [pkgs.python3 pkgs.coreutils]}:/usr/bin:/bin"
          export HOME="/Users/morph"

          NAS="${nasMount}"

          # Wait for NAS to be mounted (up to 60s)
          for i in $(seq 1 12); do
            /sbin/mount | /usr/bin/grep -q "$NAS" && break
            sleep 5
          done

          if ! /sbin/mount | /usr/bin/grep -q "$NAS"; then
            echo "$(date): NAS not mounted, skipping sync" >> /tmp/opencode-sync.log
            exit 0
          fi

          ${sessionConverter} >> /tmp/opencode-sync.log 2>&1
          echo "$(date): sync complete" >> /tmp/opencode-sync.log
        ''
      ];
      RunAtLoad = true;

      WatchPaths = [
        sessionSrc
      ];

      StartCalendarInterval = [
        {Minute = 0;}
        {Minute = 10;}
        {Minute = 20;}
        {Minute = 30;}
        {Minute = 40;}
        {Minute = 50;}
      ];

      ThrottleInterval = 30;

      StandardOutPath = "/tmp/opencode-sync.stdout.log";
      StandardErrorPath = "/tmp/opencode-sync.stderr.log";
      Nice = 10;
      ProcessType = "Background";
      EnvironmentVariables = {
        HOME = "/Users/morph";
      };
    };
  };
}
