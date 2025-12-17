{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.services.latex-ocr;

  # Path to the LaTeX OCR workflow
  workflowPath = "/Users/morph/Sync/automations/raycast/latex-ocr-workflow";

  # Use Poetry to manage the environment
  # We'll use the existing poetry installation in the workflow directory

  # Wrapper script to start the server using Poetry
  startScript = pkgs.writeShellScript "latex-ocr-server" ''
    set -e

    cd "${workflowPath}"

    # Set environment variables
    export API_HOST="${cfg.host}"
    export API_PORT="${toString cfg.port}"
    export MODEL_DEVICE="${cfg.device}"
    export AUTO_COPY_TO_CLIPBOARD="${if cfg.autoCopyToClipboard then "true" else "false"}"
    export OUTPUT_FORMAT="${cfg.outputFormat}"
    export VERBOSE_LOGGING="${if cfg.verbose then "true" else "false"}"
    export CLEANSHOT_TEMP_DIR="${cfg.cleanshotTempDir}"

    # Ensure poetry is in PATH
    export PATH="${pkgs.poetry}/bin:$PATH"

    # Start the server using poetry
    exec ${pkgs.poetry}/bin/poetry run ocr-server
  '';
in {
  options.services.latex-ocr = {
    enable = mkEnableOption "LaTeX OCR service";

    host = mkOption {
      type = types.str;
      default = "127.0.0.1";
      description = "Host to bind the API server to";
    };

    port = mkOption {
      type = types.port;
      default = 8765;
      description = "Port to bind the API server to";
    };

    device = mkOption {
      type = types.enum ["cpu" "mps" "cuda"];
      default = "mps";
      description = "Device to run the OCR model on (cpu, mps for Apple Silicon, or cuda for NVIDIA)";
    };

    autoCopyToClipboard = mkOption {
      type = types.bool;
      default = true;
      description = "Automatically copy LaTeX output to clipboard";
    };

    outputFormat = mkOption {
      type = types.enum ["latex" "typst"];
      default = "latex";
      description = "Output format (latex or typst)";
    };

    verbose = mkOption {
      type = types.bool;
      default = false;
      description = "Enable verbose logging";
    };

    cleanshotTempDir = mkOption {
      type = types.str;
      default = "/Users/morph/Sync/screenshots";
      description = "Screenshot directory where CleanShot X saves images";
    };
  };

  config = mkIf cfg.enable {
    # Install Poetry globally
    environment.systemPackages = [
      pkgs.poetry
    ];

    # Create launchd agent to run the service
    launchd.user.agents.latex-ocr = {
      serviceConfig = {
        Label = "com.latex-ocr.server";
        ProgramArguments = ["${startScript}"];
        RunAtLoad = true;
        KeepAlive = {
          SuccessfulExit = false;
          Crashed = true;
        };
        StandardOutPath = "/tmp/latex-ocr.log";
        StandardErrorPath = "/tmp/latex-ocr.error.log";
        EnvironmentVariables = {
          PATH = "${pkgs.poetry}/bin:${pkgs.coreutils}/bin:/usr/bin:/bin";
          HOME = "/Users/morph";
        };
      };
    };
  };
}
