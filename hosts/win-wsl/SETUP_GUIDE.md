# Quick Setup Guide for AI on WSL with Tailscale

## 🚀 What You're Getting

A complete AI workstation with:
- **ComfyUI** - Advanced Stable Diffusion WebUI with node-based workflow
- **NVIDIA RTX 3080 GPU acceleration** via CUDA
- **Tailscale Funnel** - Secure remote access to your AI from anywhere
- **Automated deployment** - Everything runs as systemd services

## 📋 Prerequisites Checklist

- [ ] Windows with WSL2 installed
- [ ] NVIDIA RTX 3080 with latest drivers on Windows host
- [ ] Tailscale account ([sign up free](https://login.tailscale.com/start))
- [ ] SSH key at `/home/morph/.ssh/id_ed25519` in WSL

## 🔧 Step-by-Step Setup

### Step 1: Create Tailscale Auth Key

1. **Generate an auth key**:
   - Go to: https://login.tailscale.com/admin/settings/keys
   - Click "Generate auth key..."
   - Settings:
     - ✅ Reusable
     - ✅ Ephemeral (optional, recommended for testing)
     - Expiration: Choose based on your needs (90 days recommended)
   - Click "Generate key" and copy it

2. **Create encrypted secret** (run from your Mac, in the nix repo):
   ```bash
   cd /Users/morph/nix
   
   # Use agenix to create the encrypted secret
   # This will open an editor
   nix run github:ryantm/agenix -- -e secrets/ts-win-wsl.age
   
   # In the editor that opens:
   # 1. Paste your Tailscale auth key (starts with tskey-auth-...)
   # 2. Save and exit (Ctrl+X, then Y, then Enter if using nano)
   ```

   **Note**: If you get an error about recipients, you may need to add your SSH public key to `.agenix.toml`. Check other secrets files for the format.

### Step 2: Update Flake Lock (Optional but Recommended)

This ensures you get the latest nixified.ai packages:

```bash
cd /Users/morph/nix
nix flake lock --update-input nixified-ai
```

### Step 3: Deploy to WSL

**From your Windows WSL terminal** (as morph user):

```bash
# Navigate to your nix configuration
cd ~/nix  # Adjust path if different

# Build and activate the new configuration
sudo nixos-rebuild switch --flake .#win-wsl

# This will:
# - Download AI models and dependencies (might take a while first time)
# - Configure Tailscale
# - Set up ComfyUI service
# - Enable Tailscale Funnel
```

**First build**: This may take 30-60 minutes as it downloads and builds packages. 
The nixified.ai binary cache will speed this up significantly.

### Step 4: Verify Everything is Running

```bash
# Check Tailscale is connected
tailscale status

# Check ComfyUI is running
sudo systemctl status comfyui

# Check Tailscale Funnel is active
tailscale funnel status

# View ComfyUI logs (Ctrl+C to exit)
journalctl -u comfyui -f
```

### Step 5: Access ComfyUI

1. **Get your Tailscale hostname**:
   ```bash
   tailscale status | head -n 1
   ```
   
   Look for something like: `win-wsl.tail<random>.ts.net`

2. **Access ComfyUI**:
   - From any device on your Tailscale network:
     ```
     https://<your-hostname>.ts.net:8188
     ```
   
   - Locally in WSL:
     ```
     http://localhost:8188
     ```

## 🎨 Using ComfyUI

### First Time Setup

1. **Download a model** (example with Stable Diffusion 1.5):
   ```bash
   cd /home/morph/comfyui-data/models/checkpoints
   wget https://huggingface.co/runwayml/stable-diffusion-v1-5/resolve/main/v1-5-pruned-emaonly.safetensors
   ```

2. **Restart ComfyUI** to load the model:
   ```bash
   sudo systemctl restart comfyui
   ```

3. **Open ComfyUI** in your browser and start creating!

### Adding Custom Nodes

```bash
# Navigate to custom nodes directory
cd /home/morph/comfyui-data/custom_nodes

# Clone a custom node repository (example)
git clone https://github.com/ltdrdata/ComfyUI-Manager.git

# Restart ComfyUI
sudo systemctl restart comfyui
```

### Managing Models

ComfyUI stores models in `/home/morph/comfyui-data/models/`:

- `checkpoints/` - Stable Diffusion base models
- `loras/` - LoRA models
- `vae/` - VAE models
- `controlnet/` - ControlNet models
- `upscale_models/` - Upscaling models
- And more...

## 🔒 Tailscale Funnel Configuration

### Enable Funnel in Tailscale Admin

1. Go to: https://login.tailscale.com/admin/machines
2. Find your `win-wsl` machine
3. Click the "..." menu → "Edit route settings"
4. Under "Funnel", enable it for your machine

### Funnel Commands

```bash
# Check funnel status
tailscale funnel status

# Manually enable funnel (if service fails)
tailscale funnel --bg --https=8188 8188

# Disable funnel
tailscale funnel --https=8188 off

# Restart funnel service
sudo systemctl restart tailscale-funnel-comfyui
```

## 🛠️ Troubleshooting

### GPU Not Working

```bash
# Check if NVIDIA drivers are accessible
nvidia-smi

# If command not found, check WSL can see Windows GPU
ls -la /usr/lib/wsl/lib

# Check ComfyUI is using GPU (look for CUDA in logs)
journalctl -u comfyui | grep -i cuda
```

### ComfyUI Service Won't Start

```bash
# Check detailed logs
journalctl -u comfyui -n 100 --no-pager

# Check if port is already in use
sudo netstat -tlnp | grep 8188

# Try starting manually to see errors
sudo -u morph /nix/store/*/bin/comfyui --listen 0.0.0.0 --port 8188
```

### Tailscale Issues

```bash
# Check Tailscale service
sudo systemctl status tailscale

# View Tailscale logs
journalctl -u tailscale -f

# Re-authenticate (if connection fails)
sudo tailscale up --authkey=<your-key>

# Check firewall
sudo iptables -L | grep tailscale
```

### Can't Access via Funnel

1. **Verify Funnel is enabled** in Tailscale admin console
2. **Check your Tailscale ACLs** - ensure they allow funnel access
3. **Verify the service is running**:
   ```bash
   sudo systemctl status tailscale-funnel-comfyui
   tailscale funnel status
   ```

### Build Errors

If you get errors during `nixos-rebuild`:

```bash
# Update flake inputs
nix flake update

# Try with more verbose output
sudo nixos-rebuild switch --flake .#win-wsl --show-trace

# If nixified-ai packages fail, check their status
nix flake show github:nixified-ai/flake
```

## 📊 Resource Usage

Expected resource usage:
- **Disk Space**: ~10-20 GB (base install) + models (2-8 GB each)
- **RAM**: 8-16 GB for Stable Diffusion models
- **GPU VRAM**: 4-10 GB depending on model and resolution
- **CPU**: Minimal when GPU is used

## 🔄 Maintenance

### Updating ComfyUI

```bash
cd /Users/morph/nix  # On your Mac

# Update nixified-ai flake
nix flake lock --update-input nixified-ai

# Commit the updated flake.lock
git add flake.lock
git commit -m "Update nixified-ai"

# Rebuild on WSL
sudo nixos-rebuild switch --flake .#win-wsl
```

### Viewing Logs

```bash
# ComfyUI logs (real-time)
journalctl -u comfyui -f

# Tailscale logs
journalctl -u tailscale -f

# Funnel logs
journalctl -u tailscale-funnel-comfyui

# All system logs
journalctl -xe
```

### Managing Services

```bash
# Stop all AI services
sudo systemctl stop comfyui tailscale-funnel-comfyui

# Start all AI services
sudo systemctl start comfyui tailscale-funnel-comfyui

# Disable auto-start (to save resources)
sudo systemctl disable comfyui

# Re-enable auto-start
sudo systemctl enable comfyui
```

## 📚 Additional Resources

- **ComfyUI Wiki**: https://github.com/comfyanonymous/ComfyUI/wiki
- **ComfyUI Examples**: https://comfyanonymous.github.io/ComfyUI_examples/
- **nixified.ai**: https://nixified.ai/
- **Tailscale Docs**: https://tailscale.com/kb/
- **NixOS WSL**: https://github.com/nix-community/NixOS-WSL

## 🎯 Next Steps

After setup, consider:

1. **Install ComfyUI Manager** - Makes installing custom nodes easier
2. **Download popular models** from Hugging Face or Civitai
3. **Set up ACLs** in Tailscale to control access
4. **Explore workflows** - ComfyUI is incredibly powerful
5. **Consider exposing Ollama** via Funnel too (it's already running!)

## 💡 Tips

- **Save your workflows** - ComfyUI workflows are JSON files you can version control
- **Use the binary cache** - The nixified.ai cachix speeds up rebuilds significantly
- **Monitor GPU usage** - Use `nvidia-smi` to watch VRAM usage
- **Keep models organized** - Use subdirectories in the models folder
- **Backup your data** - `/home/morph/comfyui-data` contains all your custom work

## ❓ Getting Help

If you run into issues:

1. Check the logs (`journalctl -u comfyui`)
2. Review the troubleshooting section above
3. Check nixified.ai issues: https://github.com/nixified-ai/flake/issues
4. Ask in NixOS community: https://discourse.nixos.org/

---

**Congratulations!** 🎉 You now have a powerful AI workstation accessible from anywhere via Tailscale!

