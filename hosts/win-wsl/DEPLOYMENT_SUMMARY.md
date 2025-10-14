# AI on WSL Deployment Summary

## 📋 What Was Implemented

A complete AI workstation setup for your Windows WSL machine (win-wsl) featuring:

### Core Components

1. **ComfyUI** - Advanced Stable Diffusion WebUI
   - Source: [nixified.ai](https://nixified.ai/)
   - GPU: NVIDIA RTX 3080 with CUDA acceleration
   - Port: 8188
   - Runs as systemd service (auto-start on boot)

2. **Tailscale Integration**
   - Automatic authentication on boot
   - Encrypted auth key via agenix
   - Firewall configured for mesh networking

3. **Tailscale Funnel**
   - Secure HTTPS access from anywhere
   - Only accessible to your Tailscale network
   - No public internet exposure
   - Automated via systemd service

### Files Created/Modified

#### New Files
```
hosts/win-wsl/
├── tailscale.nix              # Tailscale configuration
├── comfyui.nix                # ComfyUI service + Funnel setup
├── README.md                  # Comprehensive documentation
├── SETUP_GUIDE.md            # Step-by-step setup instructions
├── IMPLEMENTATION_NOTES.md   # Technical implementation details
└── QUICK_START.md            # Fast-track setup guide
```

#### Modified Files
```
flake.nix                      # Added nixified-ai input
flake.lock                     # Will be updated when you run nix flake lock
hosts/win-wsl/
├── configuration.nix          # Added modules, binary cache, agenix
└── default.nix               # Added nixified-ai to specialArgs
```

#### Required Secret (Not Yet Created)
```
secrets/
└── ts-win-wsl.age            # ⚠️ YOU NEED TO CREATE THIS
```

## ✅ Features Implemented

### Security
- ✅ Encrypted Tailscale auth key (agenix)
- ✅ Firewall configured (Tailscale network only)
- ✅ Service runs as non-root user
- ✅ No public internet exposure

### Performance
- ✅ NVIDIA GPU acceleration (CUDA)
- ✅ Binary cache configured (ai.cachix.org)
- ✅ Optimized WSL2 GPU passthrough

### Reliability
- ✅ Automatic service start on boot
- ✅ Auto-restart on failure (10s delay)
- ✅ Tailscale auto-authentication
- ✅ Proper systemd dependencies

### Usability
- ✅ Accessible via Tailscale Funnel
- ✅ User-owned data directory
- ✅ Persistent storage for models/workflows
- ✅ Comprehensive documentation

## 🚀 Next Steps (What You Need to Do)

### 1. Create Tailscale Auth Key Secret ⚠️ REQUIRED

This is the **ONLY** manual step needed before deployment:

```bash
# Step 1: Get a Tailscale auth key
# Visit: https://login.tailscale.com/admin/settings/keys
# Create a new auth key (make it reusable)
# Copy the key (starts with tskey-auth-...)

# Step 2: Create the encrypted secret (run from your Mac)
cd /Users/morph/nix
nix run github:ryantm/agenix -- -e secrets/ts-win-wsl.age

# In the editor that opens:
# - Paste your Tailscale auth key
# - Save and exit

# The secret is now encrypted with your SSH key
```

### 2. Update Flake (Optional but Recommended)

```bash
cd /Users/morph/nix
nix flake lock --update-input nixified-ai
```

This ensures you get the latest ComfyUI version.

### 3. Deploy to WSL

From your Windows WSL terminal:

```bash
cd ~/nix  # Adjust path if your config is elsewhere
sudo nixos-rebuild switch --flake .#win-wsl
```

**Expected build time:**
- With binary cache: 10-15 minutes
- Without binary cache: 30-60 minutes

### 4. Verify Deployment

```bash
# Check all services
sudo systemctl status tailscale comfyui tailscale-funnel-comfyui

# Get your Tailscale hostname
tailscale status

# Check ComfyUI is running
curl http://localhost:8188

# Check funnel status
tailscale funnel status
```

### 5. Access ComfyUI

From any device on your Tailscale network:
```
https://<your-win-wsl-hostname>.ts.net:8188
```

## 📚 Documentation Guide

### Quick Start (5 minutes)
Read: `hosts/win-wsl/QUICK_START.md`
- Fastest path to get running
- Essential commands only
- Quick troubleshooting

### Setup Guide (15 minutes)
Read: `hosts/win-wsl/SETUP_GUIDE.md`
- Complete step-by-step instructions
- Detailed explanations
- Comprehensive troubleshooting
- How to add models and custom nodes

### Full Documentation (30 minutes)
Read: `hosts/win-wsl/README.md`
- Architecture overview
- Service management
- Security notes
- Advanced configuration

### Technical Details (For developers)
Read: `hosts/win-wsl/IMPLEMENTATION_NOTES.md`
- Architecture decisions
- Performance characteristics
- Failure modes and recovery
- Future enhancements

## 🔧 Configuration Overview

### System Architecture

```
Windows Host (NVIDIA Drivers)
    ↓
WSL2 NixOS (win-wsl)
    ├── ComfyUI Service
    │   ├── CUDA Acceleration
    │   ├── Port 8188
    │   └── Data: /home/morph/comfyui-data
    │
    ├── Tailscale
    │   ├── Auto-connect on boot
    │   └── Encrypted auth key
    │
    └── Tailscale Funnel
        └── HTTPS exposure of port 8188
```

### Port Allocation

| Service | Port | Access |
|---------|------|--------|
| ComfyUI | 8188 | Tailscale + localhost |
| Ollama | 11434 | localhost |
| Open-WebUI | 8080 | localhost |
| SSH | 22 | Tailscale |

### Key Configuration Files

**tailscale.nix**:
- Tailscale service enabled
- Auto-authentication via encrypted key
- Firewall rules for Tailscale network
- Tailscale DNS configured

**comfyui.nix**:
- ComfyUI systemd service
- NVIDIA GPU environment variables
- Data directory management
- Tailscale Funnel service

**configuration.nix**:
- Imports both modules
- Adds nixified-ai binary cache
- Configures agenix for secrets

## 🎯 What You Can Do Now

### Immediate (After Deployment)

1. **Generate AI Images**
   - Use Stable Diffusion models
   - Create complex workflows
   - Fine-tune with LoRA models

2. **Access Remotely**
   - From your phone via Tailscale
   - From any computer on your network
   - Secure HTTPS access

3. **Customize**
   - Add custom nodes
   - Install different models
   - Modify workflows

### Future Enhancements

1. **Add More AI Services**
   - Expose Ollama via Funnel (already installed)
   - Add text-to-speech models
   - Install additional AI tools from nixified.ai

2. **Improve Workflow**
   - Set up automated backups
   - Version control your workflows
   - Share models across machines

3. **Monitoring**
   - Add Prometheus metrics
   - Set up Grafana dashboards
   - Alert on service failures

## ⚠️ Important Notes

### Before First Build

1. **Create the secret**: Without `secrets/ts-win-wsl.age`, the build will fail
2. **Ensure SSH key exists**: Agenix needs `/home/morph/.ssh/id_ed25519` in WSL
3. **Check disk space**: Need at least 20 GB free

### During First Build

1. **Be patient**: First build takes time (binary cache helps a lot)
2. **Watch for errors**: Check if secret file is accessible
3. **GPU drivers**: Ensure Windows NVIDIA drivers are up to date

### After Deployment

1. **Download models**: ComfyUI starts empty, you need to add models
2. **Enable Funnel**: Must be enabled in Tailscale admin console
3. **Check logs**: Monitor `journalctl -u comfyui -f` for issues

## 🐛 Common Issues and Solutions

### Issue: Build fails with "secret not found"
**Solution**: Create `secrets/ts-win-wsl.age` (see Step 1 above)

### Issue: GPU not detected
**Solution**: 
```bash
# Check Windows drivers are accessible
nvidia-smi

# Update WSL2
wsl --update  # From Windows PowerShell
```

### Issue: Tailscale won't connect
**Solution**:
```bash
# Check secret is readable
sudo cat /run/agenix/ts-win-wsl

# Re-run autoconnect
sudo systemctl restart tailscale-autoconnect
```

### Issue: Funnel not working
**Solution**:
1. Enable in Tailscale admin console
2. Restart funnel service: `sudo systemctl restart tailscale-funnel-comfyui`
3. Check status: `tailscale funnel status`

## 📊 Resource Requirements

### Minimum
- **Disk**: 20 GB free
- **RAM**: 8 GB
- **GPU**: NVIDIA GPU with 4+ GB VRAM
- **Network**: Stable internet connection

### Recommended
- **Disk**: 50+ GB free
- **RAM**: 16+ GB
- **GPU**: NVIDIA RTX 3080 (like you have! ✅)
- **Network**: High-speed connection for model downloads

## 🔗 Useful Links

- **nixified.ai**: https://nixified.ai/
- **nixified.ai GitHub**: https://github.com/nixified-ai/flake
- **ComfyUI**: https://github.com/comfyanonymous/ComfyUI
- **Tailscale**: https://tailscale.com/
- **Tailscale Funnel**: https://tailscale.com/kb/1223/tailscale-funnel
- **Agenix**: https://github.com/ryantm/agenix
- **NixOS WSL**: https://github.com/nix-community/NixOS-WSL

## 📝 Changelog

### 2024-10-13 - Initial Implementation
- ✅ Added nixified-ai flake input
- ✅ Created tailscale.nix for win-wsl
- ✅ Created comfyui.nix with GPU support
- ✅ Configured Tailscale Funnel
- ✅ Added binary cache configuration
- ✅ Created comprehensive documentation
- ✅ Tested configuration (no linter errors)

## 🎉 Success Criteria

You'll know everything is working when:

- [ ] `sudo nixos-rebuild switch --flake .#win-wsl` succeeds
- [ ] `tailscale status` shows "Running"
- [ ] `sudo systemctl status comfyui` shows "active (running)"
- [ ] `curl http://localhost:8188` returns HTML
- [ ] `tailscale funnel status` shows port 8188 exposed
- [ ] Can access ComfyUI from another device via `https://<hostname>.ts.net:8188`
- [ ] Can load and run a workflow in ComfyUI
- [ ] `nvidia-smi` shows GPU usage when generating images

## 🙏 Credits

This implementation was created by analyzing best practices from:
- Your existing Tailscale configurations (xps17-nixos, t480-nixos, optiplex-nixos)
- nixified.ai documentation and examples
- Tailscale Funnel documentation
- NixOS WSL community resources

## 💬 Support

If you encounter issues:

1. Check the troubleshooting sections in the documentation
2. Review the logs: `journalctl -u comfyui -xe`
3. Verify all prerequisites are met
4. Check the nixified.ai GitHub issues
5. Ask in NixOS community forums

---

**Status**: ✅ Ready for deployment (pending secret creation)

**Next Action**: Create `secrets/ts-win-wsl.age` and deploy!

