# DNS Troubleshooting Guide for Midnight Super Miner

## Problem Overview

The Midnight Super Miner experienced intermittent stalling and hash rate drops due to DNS resolution failures when connecting to `scavenger.prod.gd.midnighttge.io`.

### Symptoms
- Hash rate drops from 18-19K H/s to 6-7K H/s
- Mining appears to "stall" periodically
- Logs show repeated errors: `getaddrinfo ENOTFOUND scavenger.prod.gd.midnighttge.io`
- CPU usage fluctuates between 30-100% instead of steady 100%
- Solutions found decrease significantly

## Root Cause

**Unreliable router DNS** (typically `192.168.1.1`) fails intermittently, causing:
- Failed API calls to fetch challenges
- Workers sitting idle waiting for DNS resolution
- Reduced mining efficiency
- Lost mining time and potential solutions

## Solution: Switch to Google DNS

### Windows DNS Configuration

#### Method 1: PowerShell (Requires Admin)
```powershell
Set-DnsClientServerAddress -InterfaceAlias 'Wi-Fi' -ServerAddresses ('8.8.8.8','8.8.4.4')
```

#### Method 2: Manual Settings (Recommended)
1. Press `Win + I` → Open Settings
2. **Network & Internet** → **Wi-Fi**
3. Click on your connected network
4. Scroll to **DNS server assignment** → Click **Edit**
5. Change to **Manual**
6. Enable **IPv4**
7. Set DNS servers:
   - **Preferred DNS**: `8.8.8.8` (Google Primary)
   - **Alternate DNS**: `8.8.4.4` (Google Secondary)
8. Click **Save**

### Verification Commands

**Check current DNS servers:**
```powershell
Get-DnsClientServerAddress -InterfaceAlias "Wi-Fi"
```

**Test DNS resolution:**
```powershell
nslookup scavenger.prod.gd.midnighttge.io 8.8.8.8
```

**Test API connectivity:**
```powershell
Test-NetConnection -ComputerName scavenger.prod.gd.midnighttge.io -Port 443
```

**Quick API test:**
```powershell
curl -s https://scavenger.prod.gd.midnighttge.io/challenge
```

## Post-Fix Steps

After changing DNS, **restart the Next.js service** to clear DNS cache:

1. Stop Next.js:
   ```powershell
   # Find the main Next.js process (usually highest memory)
   Get-Process node | Where-Object {$_.WorkingSet -gt 500MB}
   
   # Kill it (replace PID with actual process ID)
   taskkill /F /PID <PID>
   ```

2. Restart Next.js:
   ```powershell
   cd C:\Users\js\Documents\Midnight-Super-Miner
   npx next dev -p 3001
   ```

3. **Reload wallet** in the web interface (http://localhost:3001)

4. Verify hash rate returns to **16-19K H/s**

## Monitoring & Diagnostics

### Check Mining Status
```powershell
curl -s http://localhost:3001/api/mining/status | ConvertFrom-Json | Select-Object -ExpandProperty stats
```

### Monitor Hash Rate Over Time
```powershell
for($i=0; $i -lt 10; $i++) {
    $s = curl -s http://localhost:3001/api/mining/status | ConvertFrom-Json
    Write-Output "$(Get-Date -Format 'HH:mm:ss') | HashRate: $([math]::Round($s.stats.hashRate,0)) H/s | CPU: $([math]::Round($s.stats.cpuUsage,0))%"
    Start-Sleep -Seconds 3
}
```

### Check Recent Logs for DNS Errors
```powershell
Get-Content "logs\mining-$(Get-Date -Format 'yyyy-MM-dd').log" -Tail 50 | Select-String "ENOTFOUND"
```

## Expected Results After Fix

- ✅ **Hash Rate**: Stable 16-19K H/s (with 23 workers, 1000 batch size)
- ✅ **CPU Usage**: Consistent 90-100%
- ✅ **No DNS Errors**: Logs show no `ENOTFOUND` errors
- ✅ **Reliable Mining**: No stalling or dropped connections
- ✅ **Solutions**: Consistent discovery rate (12-15+ per hour depending on difficulty)

## Alternative DNS Providers

If Google DNS has issues in your region, alternatives include:

| Provider | Primary | Secondary |
|----------|---------|-----------|
| Google | 8.8.8.8 | 8.8.4.4 |
| Cloudflare | 1.1.1.1 | 1.0.0.1 |
| OpenDNS | 208.67.222.222 | 208.67.220.220 |
| Quad9 | 9.9.9.9 | 149.112.112.112 |

## Troubleshooting Tips

### If DNS change doesn't help:
1. **Flush DNS cache:**
   ```powershell
   ipconfig /flushdns
   ```

2. **Check firewall/antivirus** isn't blocking DNS
3. **Try different DNS provider** from table above
4. **Restart router** if all else fails

### If hash rate still low after DNS fix:
1. Verify worker threads = 23
2. Verify batch size = 1000
3. Check CPU isn't thermal throttling (laptop cooling)
4. Verify hash server is running: `curl http://127.0.0.1:9001/health`
5. Check for other heavy processes competing for CPU

## Prevention

- **Monitor logs regularly** for DNS errors
- **Set up DNS monitoring** with scripts
- **Consider running on wired Ethernet** instead of Wi-Fi for more stability
- **Keep DNS set to reliable provider** (Google, Cloudflare, etc.)

## Related Issues

This DNS fix resolves:
- Issue #1: Mining stalls every few minutes
- Issue #2: Hash rate inconsistent (8K-16K fluctuation)
- Issue #3: "Failed to fetch challenge" errors
- Issue #4: Workers sitting idle unexpectedly

## For Other Windsurf Agents

When encountering mining performance issues:

1. **Always check DNS first** - It's the most common cause of stalling
2. **Check logs** in `logs/mining-YYYY-MM-DD.log` for error patterns
3. **Verify network connectivity** before assuming code issues
4. **Monitor hash rate over time** to distinguish between intermittent and persistent problems
5. **Remember to restart Next.js** after DNS changes to clear cache

---

**Last Updated**: November 11, 2025  
**Tested On**: Windows 11, ProArt P16 H7606WV  
**Miner Version**: Midnight Super Miner v1.0  
**Status**: ✅ Verified Working
