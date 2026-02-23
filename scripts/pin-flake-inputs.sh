#!/usr/bin/env bash
# Script to pin flake inputs for important projects to prevent garbage collection

set -euo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to pin a flake's inputs
pin_flake() {
    local flake_path=$1
    
    if [[ ! -f "$flake_path/flake.nix" ]]; then
        print_warn "No flake.nix found in $flake_path, skipping..."
        return 0
    fi
    
    print_info "Pinning flake inputs for: $flake_path"
    
    # Enter the directory
    pushd "$flake_path" > /dev/null
    
    # Build the flake to ensure inputs are in the store
    if nix flake metadata &>/dev/null; then
        # Create a GC root for the flake inputs
        local gc_root_dir="$HOME/.cache/nix-gc-roots/flakes"
        mkdir -p "$gc_root_dir"
        
        # Get a clean project name, handling both absolute and relative paths
        local project_name
        if [[ "$flake_path" == "." ]]; then
            project_name=$(basename "$(pwd)")
        else
            project_name=$(basename "$flake_path")
        fi
        local gc_root="$gc_root_dir/$project_name"
        
        # Build and create GC root
        print_info "Creating GC root for $project_name..."
        
        # Create a GC root by building the flake's outputs
        # This ensures all dependencies are downloaded and kept
        if nix build --no-link '.#' 2>/dev/null; then
            # If there's a default package, create a GC root for it
            nix build --out-link "$gc_root-default" '.#' 2>/dev/null || true
        fi
        
        # Also create GC roots for the flake inputs themselves
        # This ensures the flake sources are kept
        nix flake archive --to "$gc_root-archive" 2>/dev/null || true
        
        print_info "✓ Flake inputs pinned for $project_name"
    else
        print_warn "Could not read flake metadata for $flake_path"
    fi
    
    popd > /dev/null
}

# Function to find all flake.nix files in common project directories
find_project_flakes() {
    local search_dirs=(
        "$HOME/Downloads/videos"
        "$HOME/projects"
        "$HOME/dev"
        "$HOME/code"
        "$HOME/Documents/code"
    )
    
    local found_flakes=()
    
    for dir in "${search_dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            print_info "Searching for flakes in: $dir"
            while IFS= read -r -d '' flake_dir; do
                found_flakes+=("$(dirname "$flake_dir")")
            done < <(find "$dir" -maxdepth 3 -name "flake.nix" -print0 2>/dev/null)
        fi
    done
    
    echo "${found_flakes[@]}"
}

# Main script
main() {
    print_info "Nix Flake Input Pinning Tool"
    print_info "=============================="
    echo
    
    # Check if specific directories were provided
    if [[ $# -gt 0 ]]; then
        # Pin specific directories
        for dir in "$@"; do
            if [[ -d "$dir" ]]; then
                pin_flake "$dir"
            else
                print_error "Directory not found: $dir"
            fi
        done
    else
        # Find and pin all project flakes
        print_info "No specific directories provided, searching for project flakes..."
        
        local flake_dirs=($(find_project_flakes))
        
        if [[ ${#flake_dirs[@]} -eq 0 ]]; then
            print_warn "No flakes found in common project directories"
            exit 0
        fi
        
        print_info "Found ${#flake_dirs[@]} flake(s) to pin"
        echo
        
        for flake_dir in "${flake_dirs[@]}"; do
            pin_flake "$flake_dir"
            echo
        done
    fi
    
    print_info "Done! Pinned flakes will be preserved during garbage collection."
    print_info "GC roots stored in: $HOME/.cache/nix-gc-roots/flakes"
}

main "$@"