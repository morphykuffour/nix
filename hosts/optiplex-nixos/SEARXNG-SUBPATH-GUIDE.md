# SearXNG Subpath Configuration Guide

## 🎯 Goal
Make SearXNG accessible on **both** URLs:
- `https://optiplex-nixos.tailc585e.ts.net/search` (subpath, like `/qbittorrent`)
- `https://optiplex-nixos.tailc585e.ts.net:8443` (dedicated port, backup)

## 📝 Changes Made

### File: `hosts/optiplex-nixos/tailscale.nix`

**Added line 71:**
```nix
"${config.services.tailscale.package}/bin/tailscale serve --bg --https=443 /search http://127.0.0.1:8888; " +
```

**Key difference from qBittorrent:**
- qBittorrent uses: `--set-path=/qbittorrent` (strips path prefix)
- SearXNG uses: `/search` (keeps path prefix)

**Why?**
- `--set-path` strips the path → backend sees `/`
- Without `--set-path` → backend sees the full path `/search/`
- SearXNG doesn't support `--set-path` well (causes redirect loops)

### How Tailscale Path Routing Works

| Syntax | Request | Forwarded to Backend | Use Case |
|--------|---------|---------------------|-----------|
| `--set-path=/qbittorrent` | `/qbittorrent/api` | `/api` | App expects to be at root |
| `/search` | `/search/` | `/search/` | App handles subpath routing |

## 🚀 Deployment

### On Your Mac:
```bash
cd ~/nix
git pull  # Get the latest changes

# SSH to server and run the deployment script
tailscale ssh optiplex-nixos 'bash ~/nix/hosts/optiplex-nixos/apply-searxng-subpath.sh'
```

### Manual Deployment:
```bash
tailscale ssh optiplex-nixos

cd ~/nix && git pull
sudo nixos-rebuild switch --flake .#optiplex-nixos

# Verify
tailscale serve status
```

**Expected output:**
```
https://optiplex-nixos.tailc585e.ts.net (tailnet only)
|-- /search      proxy http://127.0.0.1:8888  ✨ NEW
|-- /qbittorrent proxy http://127.0.0.1:8080

https://optiplex-nixos.tailc585e.ts.net:8443 (tailnet only)
|-- / proxy http://127.0.0.1:8888
```

## 🧪 Testing

### Test 1: Direct SearXNG Access (Port 8888)
```bash
# On server
curl -I http://localhost:8888

# Expected: HTTP/1.1 200 OK
```

### Test 2: Subpath Access via Tailscale
```bash
# On Mac or server
curl -I https://optiplex-nixos.tailc585e.ts.net/search

# Expected: HTTP/2 200 (or redirect to /search/)
```

### Test 3: Search Query
```bash
curl -v 'https://optiplex-nixos.tailc585e.ts.net/search/search?q=test'

# Should NOT return ERR_TOO_MANY_REDIRECTS
# Should return search results or redirect to valid URL
```

### Test 4: Browser Testing
**Open in Brave/Safari:**
1. `https://optiplex-nixos.tailc585e.ts.net/search`
2. Perform a search
3. Verify no redirect loops
4. Check CSS/images load correctly

## 🔍 Troubleshooting

### Issue: ERR_TOO_MANY_REDIRECTS

**Cause:** SearXNG is redirecting HTTP to HTTPS, creating a loop.

**Check:**
```bash
# See what SearXNG returns
curl -v http://localhost:8888/search/ 2>&1 | grep -i location
```

**If you see redirect to HTTPS:**
- SearXNG detects HTTP request from Tailscale
- It redirects to HTTPS
- Tailscale receives redirect → forwards again → loop

**Solution:** SearXNG might need configuration to trust `X-Forwarded-Proto` header.

**Check if Tailscale sends proxy headers:**
```bash
# On server, watch SearXNG logs while accessing /search
docker logs searxng -f
```

Look for:
- Request headers (especially `X-Forwarded-Proto`, `X-Forwarded-For`)
- Redirect responses (308, 301, 302)

### Issue: Path Doubling (/search/search)

**Cause:** SearXNG thinks it's at root `/` but Tailscale forwards `/search/`

**Solution:** Configure SearXNG base_url

**Edit `/home/morph/searxng/config/settings.yml` on server:**
```yaml
server:
  # Add or update:
  base_url: /search
```

Then restart:
```bash
docker restart searxng
```

### Issue: Assets Don't Load (CSS/Images)

**Symptoms:** Page loads but no styling, broken images.

**Cause:** Assets loading from `/static/` instead of `/search/static/`

**Check browser console (F12):**
- Look for 404 errors on `/static/themes/...`
- Should be `/search/static/themes/...`

**Solution:** Same as path doubling - set `base_url: /search`

## 📊 Expected Final State

| URL | Status | Notes |
|-----|--------|-------|
| `https://...tailc585e.ts.net/search` | ✅ Working | Subpath access |
| `https://...tailc585e.ts.net:8443` | ✅ Working | Dedicated port (backup) |
| `https://...tailc585e.ts.net/qbittorrent` | ✅ Working | Unchanged |
| `https://...tailc585e.ts.net:444` | ✅ Working | VERT UI |
| `https://...tailc585e.ts.net:8081` | ✅ Working | code-server |

## 🎉 Next Steps

1. **Deploy the configuration** (see above)
2. **Test `/search` in browser**
3. **If redirect loops occur**, configure SearXNG `base_url`
4. **Report back with results!**

---

## 📚 References

- [Tailscale Serve Documentation](https://tailscale.com/kb/1242/tailscale-serve)
- [SearXNG Settings](https://docs.searxng.org/admin/settings/index.html)
- [NixOS Docker Containers](https://nixos.wiki/wiki/Docker)
