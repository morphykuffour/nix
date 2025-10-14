# Win-WSL AI Setup with Tailscale Funnel

This configuration sets up a powerful AI model (ComfyUI) on your Windows WSL machine with NVIDIA 3080 GPU support, accessible through your Tailscale network.

## What's Configured

### 1. ComfyUI - Stable Diffusion WebUI
- **Source**: [nixified.ai](https://nixified.ai/) 
- **Package**: `comfyui-nvidia` from `github:nixified-ai/flake`
- **GPU Support**: NVIDIA CUDA acceleration using your RTX 3080
- **Port**: 8188 (default)
- **Data Directory**: `/home/morph/comfyui-data`

### 2. Tailscale Integration
- Automatic authentication via encrypted auth key
- Firewall configured for Tailscale traffic
- Tailscale nameservers configured

### 3. Tailscale Funnel
- Exposes ComfyUI securely through your Tailscale network
- Accessible via HTTPS at: `https://<your-tailscale-hostname>.ts.net:8188`
- No public internet exposure - only accessible to your Tailscale network

## Prerequisites

### 1. Create Tailscale Auth Key Secret

Before rebuilding your system, you need to create an encrypted auth key for Tailscale:

1. Generate a Tailscale auth key:
   - Go to [Tailscale Admin Console](https://login.tailscale.com/admin/settings/keys)
   - Create a new auth key
   - Make it reusable and set appropriate expiration
   - Copy the key

2. Create the encrypted secret file:
   ```bash
   cd /Users/morph/nix
   
   # Create a temporary file with your auth key
   echo "tskey-auth-xxxxxxxxxxxxx" > /tmp/ts-win-wsl-key
   
   # Encrypt it with agenix (using your SSH key)
   # You'll need to add the public key to .agenix.toml if not already there
   nix run github:ryantm/agenix -- -e secrets/ts-win-wsl.age
   # Paste your auth key when the editor opens, save and exit
   
   # Clean up
   rm /tmp/ts-win-wsl-key
   ```

### 2. NVIDIA Drivers on Windows Host

Ensure you have the latest NVIDIA drivers installed on your Windows host:
- Download from [NVIDIA Driver Downloads](https://www.nvidia.com/Download/index.aspx)
- WSL2 automatically uses the Windows host GPU drivers

## Deployment

### Build and Switch

From your Windows WSL terminal:

```bash
cd ~/nix  # or wherever your nix config is located

# Build the configuration
sudo nixos-rebuild switch --flake .#win-wsl
```

### Verify Services

Check that all services are running:

```bash
# Check Tailscale status
sudo systemctl status tailscale
tailscale status

# Check ComfyUI service
sudo systemctl status comfyui

# Check Tailscale Funnel
sudo systemctl status tailscale-funnel-comfyui

# View ComfyUI logs
journalctl -u comfyui -f
```

## Accessing ComfyUI

### Via Tailscale Network

1. Get your Tailscale hostname:
   ```bash
   tailscale status | grep win-wsl
   ```

2. Access ComfyUI from any device on your Tailscale network:
   ```
   https://<win-wsl-tailscale-hostname>:8188
   ```

### Locally on WSL

```
http://localhost:8188
```

## Managing ComfyUI

### Service Management

```bash
# Stop ComfyUI
sudo systemctl stop comfyui

# Start ComfyUI
sudo systemctl start comfyui

# Restart ComfyUI
sudo systemctl restart comfyui

# Disable auto-start
sudo systemctl disable comfyui

# Enable auto-start
sudo systemctl enable comfyui
```

### Installing Custom Nodes and Models

ComfyUI stores its data in `/home/morph/comfyui-data`. You can:

1. **Add Custom Nodes**:
   ```bash
   cd /home/morph/comfyui-data/custom_nodes
   git clone <custom-node-repo>
   sudo systemctl restart comfyui
   ```

2. **Add Models**:
   - Place models in `/home/morph/comfyui-data/models/<model-type>/`
   - For example, Stable Diffusion checkpoints go in `models/checkpoints/`

3. **View ComfyUI Configuration**:
   ```bash
   ls -la /home/morph/comfyui-data/
   ```

## Tailscale Funnel Management

### Enable/Disable Funnel Manually

```bash
# Enable funnel (if service is not running)
tailscale funnel --bg --https=8188 8188

# Disable funnel
tailscale funnel --https=8188 off

# Check funnel status
tailscale funnel status
```

### Security Notes

- Tailscale Funnel requires funnel to be enabled in your Tailscale admin console
- Access is still controlled by your Tailscale ACLs
- Consider setting up appropriate ACLs to restrict access if needed

## Troubleshooting

### GPU Not Detected

If ComfyUI doesn't detect your GPU:

1. Check NVIDIA drivers in WSL:
   ```bash
   nvidia-smi
   ```

2. Verify CUDA is available:
   ```bash
   ls -la /usr/lib/wsl/lib
   ```

3. Check ComfyUI logs for CUDA errors:
   ```bash
   journalctl -u comfyui -n 100
   ```

### ComfyUI Won't Start

1. Check if the port is already in use:
   ```bash
   sudo netstat -tlnp | grep 8188
   ```

2. Verify the data directory exists and has correct permissions:
   ```bash
   ls -la /home/morph/comfyui-data
   sudo chown -R morph:users /home/morph/comfyui-data
   ```

### Tailscale Connection Issues

1. Check Tailscale status:
   ```bash
   tailscale status
   sudo systemctl status tailscale
   ```

2. Re-authenticate if needed:
   ```bash
   sudo tailscale up --authkey=<your-auth-key>
   ```

### Funnel Not Working

1. Verify funnel is enabled in Tailscale admin console
2. Check funnel service logs:
   ```bash
   journalctl -u tailscale-funnel-comfyui
   ```

3. Manually test funnel:
   ```bash
   tailscale funnel status
   ```

## Additional Services

This machine also runs:

- **Ollama**: LLM service with CUDA acceleration on port 11434
- **Open-WebUI**: Web interface for Ollama on port 8080 (default)

You can expose these via Tailscale Funnel as well by creating similar systemd services.

## References

- [nixified.ai Documentation](https://nixified.ai/)
- [nixified.ai GitHub](https://github.com/nixified-ai/flake)
- [ComfyUI Documentation](https://github.com/comfyanonymous/ComfyUI)
- [Tailscale Funnel Documentation](https://tailscale.com/kb/1223/tailscale-funnel)
- [NixOS WSL Documentation](https://github.com/nix-community/NixOS-WSL)

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Windows Host                          │
│  ┌───────────────────────────────────────────────────┐  │
│  │              WSL2 - NixOS                          │  │
│  │  ┌─────────────────────────────────────────────┐  │  │
│  │  │  ComfyUI Service (Port 8188)                │  │  │
│  │  │  - NVIDIA RTX 3080 GPU                      │  │  │
│  │  │  - CUDA Acceleration                        │  │  │
│  │  │  - Data: /home/morph/comfyui-data           │  │  │
│  │  └─────────────────────────────────────────────┘  │  │
│  │                      ↕                             │  │
│  │  ┌─────────────────────────────────────────────┐  │  │
│  │  │  Tailscale (tailscale0 interface)           │  │  │
│  │  │  - Auto-connect on boot                     │  │  │
│  │  └─────────────────────────────────────────────┘  │  │
│  │                      ↕                             │  │
│  │  ┌─────────────────────────────────────────────┐  │  │
│  │  │  Tailscale Funnel                           │  │  │
│  │  │  - Exposes 8188 via HTTPS                   │  │  │
│  │  │  - https://win-wsl.ts.net:8188              │  │  │
│  │  └─────────────────────────────────────────────┘  │  │
│  └───────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
                          ↕
                  Tailscale Network
                          ↕
        ┌─────────────────────────────────────┐
        │   Your Devices on Tailscale         │
        │   - Access via Tailscale Funnel     │
        │   - HTTPS encrypted                 │
        │   - ACL controlled                  │
        └─────────────────────────────────────┘
```

