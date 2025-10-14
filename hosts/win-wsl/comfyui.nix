{
  config,
  pkgs,
  lib,
  nixified-ai,
  ...
}: let
  # Get ComfyUI from nixified.ai flake input
  comfyui-nvidia = nixified-ai.packages.${pkgs.system}.comfyui-nvidia or null;
  
  # Port for ComfyUI web interface
  comfyuiPort = 8188;
in {
  # Add firewall rule for ComfyUI
  networking.firewall.allowedTCPPorts = [comfyuiPort];

  # SystemD service to run ComfyUI persistently
  systemd.services.comfyui = lib.mkIf (comfyui-nvidia != null) {
    description = "ComfyUI - Stable Diffusion WebUI with NVIDIA GPU support";
    after = ["network.target"];
    wantedBy = ["multi-user.target"];

    serviceConfig = {
      Type = "simple";
      User = "morph";
      Group = "users";
      Restart = "on-failure";
      RestartSec = "10s";
      
      # Set working directory for ComfyUI data
      WorkingDirectory = "/home/morph/comfyui-data";
      
      # Ensure the directory exists
      ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p /home/morph/comfyui-data";
      
      # Run ComfyUI
      ExecStart = "${comfyui-nvidia}/bin/comfyui --listen 0.0.0.0 --port ${toString comfyuiPort}";
      
      # Environment variables for NVIDIA GPU
      Environment = [
        "CUDA_VISIBLE_DEVICES=0"
        "LD_LIBRARY_PATH=/usr/lib/wsl/lib"
      ];
    };
  };

  # SystemD service to expose ComfyUI via Tailscale Funnel
  systemd.services.tailscale-funnel-comfyui = {
    description = "Expose ComfyUI via Tailscale Funnel";
    after = ["tailscale.service" "comfyui.service"];
    wants = ["tailscale.service" "comfyui.service"];
    wantedBy = ["multi-user.target"];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      User = "root";
      
      # Enable funnel for ComfyUI
      ExecStart = "${pkgs.tailscale}/bin/tailscale funnel --bg --https=${toString comfyuiPort} ${toString comfyuiPort}";
      
      # Disable funnel on service stop
      ExecStop = "${pkgs.tailscale}/bin/tailscale funnel --https=${toString comfyuiPort} off";
    };
  };

  # Add informational environment variable
  environment.variables = {
    COMFYUI_PORT = toString comfyuiPort;
  };
}

