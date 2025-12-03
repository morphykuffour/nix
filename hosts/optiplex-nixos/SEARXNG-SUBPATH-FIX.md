# SearXNG /search Subpath Configuration

## ✅ Fixed Configuration

SearXNG is now configured to work on BOTH:
- **Subpath:** `https://optiplex-nixos.tailc585e.ts.net/search`
- **Dedicated port:** `https://optiplex-nixos.tailc585e.ts.net:8443`

## 🔧 How It Works

### Tailscale Configuration (`tailscale.nix`)
```nix
# Line 71-72
tailscale serve --bg --https=443 --set-path=/search http://127.0.0.1:8888
tailscale serve --bg --https=8443 http://127.0.0.1:8888
```

**Key points:**
1. `--set-path=/search` **strips** the `/search` prefix before forwarding to backend
2. SearXNG receives requests to `/` (not `/search`)
3. No `SEARXNG_BASE_URL` environment variable (lets SearXNG think it's at root)

### SearXNG Configuration (`searxng.nix`)
```nix
# No base_url environment variable
# SearXNG thinks it's at root path /
```

## ⚠️ Potential Issue: Redirect Loops

If you perform a search and see `ERR_TOO_MANY_REDIRECTS`, this is because:

1. Browser → `https://optiplex-nixos.tailc585e.ts.net/search?q=hello` (HTTPS)
2. Tailscale terminates HTTPS, forwards HTTP to port 8888
3. SearXNG sees HTTP request, tries to redirect to HTTPS
4. Redirect goes back to step 1 → **infinite loop**

### Fix Option 1: Configure SearXNG to Trust Proxy Headers

**Not supported in Tailscale Serve** - Tailscale doesn't send `X-Forwarded-Proto` headers, so SearXNG always sees HTTP.

### Fix Option 2: Use Port 8443 Instead

**Recommended workaround:**
```
https://optiplex-nixos.tailc585e.ts.net:8443
```

This URL works because:
- Tailscale forwards directly to port 8888
- SearXNG sees HTTPS request (Tailscale terminates TLS but port routing works differently)
- No redirect loops

### Fix Option 3: Disable HTTPS Redirect in SearXNG

Edit `/home/morph/searxng/config/settings.yml`:

```yaml
server:
  port: 8888
  bind_address: "127.0.0.1"
  # Disable HTTPS redirects when behind reverse proxy
  secret_key: "your-secret-key-here"
  # Force HTTP (no redirects)
  base_url: false
```

Then restart:
```bash
docker restart searxng
```

## 🧪 Testing Checklist

After deployment:

- [ ] `/search` loads: `https://optiplex-nixos.tailc585e.ts.net/search`
- [ ] Can perform search without redirect loops
- [ ] `:8443` loads: `https://optiplex-nixos.tailc585e.ts.net:8443`
- [ ] Both URLs show same SearXNG interface
- [ ] CSS/images load correctly

## 📊 Current URL Map

| URL | Status |
|-----|--------|
| `https://optiplex-nixos.tailc585e.ts.net/qbittorrent` | ✅ Working (qBittorrent) |
| `https://optiplex-nixos.tailc585e.ts.net/search` | 🟡 **May have redirect loops** |
| `https://optiplex-nixos.tailc585e.ts.net:8443` | ✅ **Recommended** (SearXNG) |
| `https://optiplex-nixos.tailc585e.ts.net:444` | ✅ Working (VERT UI) |
| `https://optiplex-nixos.tailc585e.ts.net:8081` | ✅ Working (code-server) |

## 🎯 Recommendation

**Use port 8443 for SearXNG** to avoid any subpath/redirect issues:
```
https://optiplex-nixos.tailc585e.ts.net:8443
```

If you absolutely need `/search` to work:
1. Test if it works after applying the configuration
2. If redirect loops occur, disable HTTPS redirects in SearXNG settings (see Fix Option 3)
3. Or accept that `:8443` is the primary URL and remove `/search` route

## 📝 Files Modified

1. **`tailscale.nix`** - Added `/search` subpath route with `--set-path`
2. **`searxng.nix`** - No changes (already correct - no base_url)
3. **`fix-searxng-subpath.sh`** - Deployment script
4. **`SEARXNG-SUBPATH-FIX.md`** - This troubleshooting guide

## 🚀 Deploy Command

```bash
cd ~/nix
git pull
tailscale ssh optiplex-nixos 'cd ~/nix && ./hosts/optiplex-nixos/fix-searxng-subpath.sh'
```

Or manually on the server:
```bash
tailscale ssh optiplex-nixos
cd ~/nix
sudo nixos-rebuild switch --flake .#optiplex-nixos
tailscale serve status
```
