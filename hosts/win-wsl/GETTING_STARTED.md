# 🚀 Getting Started with AI on WSL

## What You Have Now

Your win-wsl machine is now configured with:

✨ **ComfyUI** - Advanced Stable Diffusion AI with your RTX 3080  
🔒 **Tailscale Funnel** - Secure remote access from anywhere  
⚡ **Auto-starting services** - Everything runs on boot  
📦 **Binary cache** - Fast updates and rebuilds  

## Before You Can Use It

### ⚠️ REQUIRED: Create Secret File

**This is the ONE thing you must do before deploying:**

```bash
# 1. Get a Tailscale auth key
# Visit: https://login.tailscale.com/admin/settings/keys
# Click "Generate auth key" → Make it "Reusable" → Copy it

# 2. Create encrypted secret (on your Mac, in the nix repo)
cd /Users/morph/nix
nix run github:ryantm/agenix -- -e secrets/ts-win-wsl.age

# 3. Paste your auth key, save, and exit
#    Nano: Ctrl+X → Y → Enter
#    Vim: Esc → :wq → Enter
```

That's it! Now you can deploy.

## Deploy to WSL

```bash
# In WSL (on Windows)
cd ~/nix

# Pull latest changes if you made them on Mac
git pull  # or copy files manually

# Deploy! (takes 10-30 minutes first time)
sudo nixos-rebuild switch --flake .#win-wsl
```

## Verify It's Working

```bash
# Check everything is running
tailscale status                    # Should show "Running"
sudo systemctl status comfyui       # Should show "active"
curl http://localhost:8188          # Should return HTML

# Get your Tailscale URL
tailscale status | head -n 1
# Look for: win-wsl.tail<xxx>.ts.net
```

## Access ComfyUI

**From any device on your Tailscale network:**
```
https://win-wsl.tail<xxx>.ts.net:8188
```

**Locally in WSL:**
```
http://localhost:8188
```

## First Time: Add a Model

ComfyUI starts empty. Download a model to get started:

```bash
# Create directory and download SD 1.5
mkdir -p /home/morph/comfyui-data/models/checkpoints
cd /home/morph/comfyui-data/models/checkpoints
wget https://huggingface.co/runwayml/stable-diffusion-v1-5/resolve/main/v1-5-pruned-emaonly.safetensors

# Restart ComfyUI to load the model
sudo systemctl restart comfyui
```

Now open ComfyUI in your browser and start creating! 🎨

## Quick Commands

```bash
# Service management
sudo systemctl status comfyui       # Check status
sudo systemctl restart comfyui      # Restart
sudo systemctl stop comfyui         # Stop
sudo systemctl start comfyui        # Start

# Logs
journalctl -u comfyui -f            # Live logs
journalctl -u comfyui -n 50         # Last 50 lines

# GPU usage
nvidia-smi                          # See GPU usage

# Tailscale
tailscale status                    # Connection status
tailscale funnel status             # Funnel status
```

## Need More Help?

- **Quick reference**: `QUICK_START.md` (this directory)
- **Full setup guide**: `SETUP_GUIDE.md` (this directory)
- **Complete docs**: `README.md` (this directory)
- **Technical details**: `IMPLEMENTATION_NOTES.md` (this directory)

## Troubleshooting

### Can't connect to ComfyUI?
```bash
sudo systemctl restart comfyui
curl http://localhost:8188  # Test local access
```

### GPU not working?
```bash
nvidia-smi  # Should show your RTX 3080
journalctl -u comfyui | grep -i cuda
```

### Tailscale issues?
```bash
sudo systemctl restart tailscale
tailscale status
```

## What's Next?

1. ✅ Create the secret (if not done)
2. ✅ Deploy to WSL
3. ✅ Download a model
4. ✅ Generate your first image
5. 🎨 Explore ComfyUI workflows
6. 🔧 Add custom nodes
7. 📱 Try accessing from your phone via Tailscale

---

**You're all set! Enjoy your AI workstation!** 🚀✨

