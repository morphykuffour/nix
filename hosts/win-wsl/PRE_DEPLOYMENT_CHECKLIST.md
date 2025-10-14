# Pre-Deployment Checklist - AI on WSL

## 📋 Complete This Before Running `nixos-rebuild`

### ✅ Step 1: Prerequisites Check

Run these checks on your WSL machine:

- [ ] **SSH Key Exists**
  ```bash
  ls -la /home/morph/.ssh/id_ed25519
  # Should show your SSH private key
  ```

- [ ] **Windows NVIDIA Drivers**
  ```bash
  nvidia-smi
  # Should show your RTX 3080
  ```

- [ ] **Disk Space**
  ```bash
  df -h ~
  # Should have at least 20 GB free
  ```

- [ ] **Git Repository Clean**
  ```bash
  cd ~/nix
  git status
  # No critical uncommitted changes (or commit them first)
  ```

### ✅ Step 2: Tailscale Account Setup

- [ ] **Tailscale Account Active**
  - Visit: https://login.tailscale.com/
  - Verify you can log in

- [ ] **Funnel Enabled** (if available on your plan)
  - Go to: https://login.tailscale.com/admin/settings/funnel
  - Enable Funnel if not already enabled
  - Note: May require specific Tailscale plan

### ✅ Step 3: Create Tailscale Auth Key Secret

This is **CRITICAL** - without this, the build will fail!

- [ ] **Generate Tailscale Auth Key**
  1. Go to: https://login.tailscale.com/admin/settings/keys
  2. Click "Generate auth key..."
  3. Settings:
     - ✅ **Reusable** (important for rebuilds)
     - Optional: Ephemeral (for testing)
     - Expiration: 90 days or longer recommended
  4. Click "Generate key"
  5. **Copy the key** (starts with `tskey-auth-...`)
  
  ⚠️ **Save this key temporarily** - you'll need it in the next step

- [ ] **Create Encrypted Secret**
  
  **On your Mac** (in the nix repo directory):
  ```bash
  cd /Users/morph/nix
  
  # Run agenix to create the secret
  nix run github:ryantm/agenix -- -e secrets/ts-win-wsl.age
  
  # This will open an editor (likely nano or vim)
  # 1. Paste your Tailscale auth key (the entire tskey-auth-... string)
  # 2. Make sure there are NO extra spaces or newlines
  # 3. Save and exit
  #    - Nano: Ctrl+X, then Y, then Enter
  #    - Vim: Press Esc, type :wq, press Enter
  ```

- [ ] **Verify Secret Created**
  ```bash
  ls -la secrets/ts-win-wsl.age
  # Should show a file of ~300-500 bytes
  
  file secrets/ts-win-wsl.age
  # Should show "data" or similar (it's encrypted)
  ```

- [ ] **Commit the Secret** (optional but recommended)
  ```bash
  git add secrets/ts-win-wsl.age
  git commit -m "Add Tailscale auth key for win-wsl"
  ```

### ✅ Step 4: Update Flake Lock (Optional)

- [ ] **Update nixified-ai Input**
  ```bash
  cd /Users/morph/nix
  nix flake lock --update-input nixified-ai
  
  # Optionally commit the updated lock
  git add flake.lock
  git commit -m "Update nixified-ai flake input"
  ```

### ✅ Step 5: Sync to WSL

If you're making these changes on your Mac, sync them to WSL:

- [ ] **Commit All Changes**
  ```bash
  cd /Users/morph/nix
  git status
  git add -A
  git commit -m "Add AI on WSL with Tailscale Funnel configuration"
  ```

- [ ] **Push to Remote** (if using Git remote)
  ```bash
  git push origin main
  ```

- [ ] **Pull in WSL**
  ```bash
  # In WSL
  cd ~/nix
  git pull
  ```

  **OR** if you're not using Git:
  - Copy files manually via `/mnt/c/...` path
  - Or use rsync/scp to transfer

### ✅ Step 6: Pre-Build Verification

Run these checks in WSL before building:

- [ ] **Verify Secret is Accessible**
  ```bash
  cd ~/nix
  ls -la secrets/ts-win-wsl.age
  # File should exist
  ```

- [ ] **Check Flake Syntax**
  ```bash
  nix flake show .
  # Should show your configurations without errors
  ```

- [ ] **Verify nixified-ai Input**
  ```bash
  nix flake metadata | grep nixified-ai
  # Should show github:nixified-ai/flake
  ```

- [ ] **Dry-Run Build** (optional, checks for major issues)
  ```bash
  sudo nixos-rebuild build --flake .#win-wsl
  # This builds but doesn't activate the configuration
  # Good for catching errors without changing your system
  ```

### ✅ Step 7: Final Checks

- [ ] **Read the Documentation**
  - At minimum, skim: `hosts/win-wsl/QUICK_START.md`
  - Know where to find help: `hosts/win-wsl/SETUP_GUIDE.md`

- [ ] **Understand the Build Time**
  - First build: 10-15 minutes (with binary cache)
  - Possibly 30-60 minutes (without cache or slow connection)
  - Be patient! ☕

- [ ] **Have Backup Access to WSL**
  - Know how to access WSL console from Windows
  - In case network services have issues

- [ ] **Optional: Create Snapshot/Backup**
  ```bash
  # WSL2 supports snapshots (run from PowerShell as admin)
  wsl --export NixOS backup-before-ai-setup.tar
  
  # This allows you to restore if anything goes wrong
  # To restore: wsl --import NixOS ./NixOS backup-before-ai-setup.tar
  ```

## 🚀 Ready to Deploy!

If all checkboxes above are ✅, you're ready to deploy:

```bash
# In WSL, in your nix directory
cd ~/nix
sudo nixos-rebuild switch --flake .#win-wsl
```

### What to Expect During Build

1. **Download Phase** (2-5 minutes)
   - Downloads packages from binary caches
   - Shows progress bars
   - May download 2-5 GB

2. **Build Phase** (5-10 minutes)
   - Builds any packages not in cache
   - Shows compiler output
   - May appear to hang - be patient!

3. **Activation Phase** (1-2 minutes)
   - Starts/restarts services
   - Applies configuration
   - May show systemd service messages

4. **Completion**
   - Should show "activation finished successfully" or similar
   - May show warnings (often safe to ignore)
   - Should return to shell prompt

### Immediate Post-Deployment Checks

Run these immediately after `nixos-rebuild` succeeds:

```bash
# 1. Check Tailscale
tailscale status
# Should show "Running" and your hostname

# 2. Check ComfyUI
sudo systemctl status comfyui
# Should show "active (running)"

# 3. Check Funnel
tailscale funnel status
# Should show port 8188 exposed (if Funnel is enabled in admin)

# 4. Test Local Access
curl http://localhost:8188
# Should return HTML (ComfyUI web interface)

# 5. Check Logs (optional)
journalctl -u comfyui -n 20
# Should show ComfyUI startup messages, no critical errors
```

## ❌ If Something Goes Wrong

### Build Fails

1. **Check the error message** - it usually tells you what's wrong
2. **Common issues**:
   - Secret not found → Create `secrets/ts-win-wsl.age`
   - Permission denied → Check secret file permissions
   - Network timeout → Check internet connection
   - Flake error → Run `nix flake update` and try again

3. **Get help**:
   ```bash
   # Verbose output shows more details
   sudo nixos-rebuild switch --flake .#win-wsl --show-trace
   ```

### Build Succeeds But Services Fail

```bash
# Check which service failed
sudo systemctl --failed

# Check specific service logs
journalctl -u comfyui -n 50
journalctl -u tailscale -n 50

# Try restarting services
sudo systemctl restart tailscale
sudo systemctl restart comfyui
```

### Need to Rollback

NixOS makes rollback easy:

```bash
# List generations
sudo nix-env --list-generations --profile /nix/var/nix/profiles/system

# Rollback to previous generation
sudo nixos-rebuild switch --rollback

# Or boot into previous generation from GRUB menu
```

## 📞 Getting Help

If you're stuck:

1. **Check the logs**: `journalctl -xe`
2. **Review documentation**: `hosts/win-wsl/SETUP_GUIDE.md`
3. **Check GitHub issues**: https://github.com/nixified-ai/flake/issues
4. **NixOS Discourse**: https://discourse.nixos.org/
5. **Tailscale Support**: https://tailscale.com/contact/support/

## 📝 Deployment Notes

Use this space to track your deployment:

```
Date: _____________
Time Started: _____________
Build Duration: _____________
Issues Encountered: _____________
Resolution: _____________
Final Status: [ ] Success  [ ] Failed  [ ] Partial
```

---

## ✨ Once Everything is Working

After successful deployment and verification:

1. **Download a model**: See `QUICK_START.md` for examples
2. **Generate your first image**: Test the full pipeline
3. **Access remotely**: Try accessing from another device
4. **Read advanced docs**: Explore `README.md` and `IMPLEMENTATION_NOTES.md`
5. **Customize**: Add custom nodes, models, and workflows

**Happy AI image generation!** 🎨✨

---

**Last Updated**: 2024-10-13
**Status**: Ready for deployment
**Prerequisites**: All ✅ (if you completed the checklist above)

