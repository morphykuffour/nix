# 🚀 Quick Start - AI on WSL with Tailscale

## TL;DR

Get a powerful Stable Diffusion AI (ComfyUI) running on your Windows machine with NVIDIA GPU, accessible securely from anywhere via Tailscale.

## ⚡ Fast Track (5 Steps)

### 1. Get Tailscale Auth Key
Visit: https://login.tailscale.com/admin/settings/keys
- Click "Generate auth key"
- Make it **Reusable**
- Copy the key (starts with `tskey-auth-...`)

### 2. Create Encrypted Secret (On Mac)
```bash
cd /Users/morph/nix
nix run github:ryantm/agenix -- -e secrets/ts-win-wsl.age
# Paste your auth key, save, and exit
```

### 3. Update Flake (Optional)
```bash
nix flake lock --update-input nixified-ai
```

### 4. Deploy (In WSL)
```bash
cd ~/nix
sudo nixos-rebuild switch --flake .#win-wsl
# ☕ First build takes 15-30 minutes (with binary cache)
```

### 5. Access ComfyUI
```bash
# Get your hostname
tailscale status | head -n 1

# Open in browser on ANY device on your Tailscale network:
https://YOUR-HOSTNAME.ts.net:8188
```

## 🎨 Quick Test

1. **Download a model**:
```bash
cd /home/morph/comfyui-data/models/checkpoints
wget https://huggingface.co/runwayml/stable-diffusion-v1-5/resolve/main/v1-5-pruned-emaonly.safetensors
```

2. **Restart ComfyUI**:
```bash
sudo systemctl restart comfyui
```

3. **Generate your first image**:
   - Open ComfyUI in browser
   - Load the default workflow
   - Click "Queue Prompt"
   - Watch your GPU work! 🎉

## 📊 What's Running

Check everything with one command:
```bash
# All services status
sudo systemctl status comfyui tailscale tailscale-funnel-comfyui

# GPU usage
nvidia-smi

# ComfyUI logs (live)
journalctl -u comfyui -f
```

## 🆘 Something Wrong?

### ComfyUI not accessible?
```bash
# Check services
sudo systemctl restart comfyui
tailscale funnel status
```

### GPU not working?
```bash
# Should show your RTX 3080
nvidia-smi

# Check ComfyUI sees CUDA
journalctl -u comfyui | grep -i cuda
```

### Tailscale issues?
```bash
sudo systemctl restart tailscale
tailscale status
```

## 📚 Need More Info?

- **Detailed setup**: See `SETUP_GUIDE.md`
- **Full documentation**: See `README.md`
- **Technical details**: See `IMPLEMENTATION_NOTES.md`

## 🎯 What You Get

- ✅ **ComfyUI** - Advanced Stable Diffusion with node-based workflows
- ✅ **NVIDIA GPU acceleration** - Your RTX 3080 at full power
- ✅ **Tailscale Funnel** - Secure access from anywhere
- ✅ **Automated** - Runs as systemd services, starts on boot
- ✅ **Reproducible** - Pure NixOS configuration

## 💡 Pro Tips

1. **Binary cache speeds everything up** - Already configured!
2. **Install ComfyUI Manager** - Makes adding custom nodes easy
3. **Use Civitai for models** - Great model repository
4. **Save your workflows** - They're just JSON files
5. **Monitor GPU with nvidia-smi** - Watch VRAM usage

## 🔗 Quick Links

- Tailscale Admin: https://login.tailscale.com/admin/
- ComfyUI Wiki: https://github.com/comfyanonymous/ComfyUI/wiki
- Model Hub: https://huggingface.co/models?pipeline_tag=text-to-image
- nixified.ai: https://nixified.ai/

---

**Ready to create some AI art? Let's go!** 🚀✨

