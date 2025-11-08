# Windows Setup and Troubleshooting Guide
## Midnight Super Miner - Complete Installation & Optimization

**Last Updated**: November 8, 2025  
**Platform**: Windows 10/11  
**Test System**: AMD Ryzen AI 9 HX 370 (24 cores)

---

## Table of Contents
1. [Initial Setup](#initial-setup)
2. [Dev Fee Configuration](#dev-fee-configuration)
3. [First Run](#first-run)
4. [Common Issues & Solutions](#common-issues--solutions)
5. [Performance Optimization](#performance-optimization)
6. [Verification Steps](#verification-steps)
7. [Service Management](#service-management)

---

## Initial Setup

### Step 1: Clone the Repository

Since Git may not be installed on Windows by default, use PowerShell to download via ZIP:

```powershell
# Navigate to Documents folder
cd $env:USERPROFILE\Documents

# Download repository as ZIP
Invoke-WebRequest -Uri "https://github.com/bytewizard42i/a-little-somethin-somethin-midnight-bot-fetch-mine/archive/refs/heads/main.zip" -OutFile "Midnight-Super-Miner.zip"

# Extract
Expand-Archive -Path "Midnight-Super-Miner.zip" -DestinationPath "." -Force

# Rename to clean folder name
Rename-Item -Path "a-little-somethin-somethin-midnight-bot-fetch-mine-main" -NewName "Midnight-Super-Miner"

# Clean up ZIP
Remove-Item -Path "Midnight-Super-Miner.zip"
```

### Step 2: Navigate to Project Directory

```powershell
cd $env:USERPROFILE\Documents\Midnight-Super-Miner
```

---

## Dev Fee Configuration

### Verify Dev Fee is Disabled (Default)

The dev fee is **disabled by default** in the code. To verify:

**Location**: `lib\devfee\manager.ts` (Line 60)

```typescript
// Initialize config - use cached enabled state if available, otherwise default to FALSE (disabled)
this.config = {
  enabled: config.enabled ?? this.cache.enabled ?? false,
```

**Key Points**:
- Default: `enabled: false`
- No `.env` file needed for disabled state
- No `secure\.devfee_cache.json` created until first run
- Dev fee only activates if explicitly enabled by user

### To Disable Dev Fee (if somehow enabled):

1. Delete cache file (if exists):
   ```powershell
   Remove-Item "secure\.devfee_cache.json" -ErrorAction SilentlyContinue
   ```

2. Verify `enabled: false` in code at `lib\devfee\manager.ts:60`

---

## First Run

### Step 1: Run Setup Script

```cmd
.\setup.cmd
```

**What it does**:
- Checks/installs Node.js 20.x
- Checks/installs Rust toolchain  
- Builds native hash engine (Rust)
- Installs npm dependencies
- Builds Next.js application
- Starts hash server (port 9001)
- Starts Next.js server (port 3000/3001)

**Expected Output**:
```
[1/6] Checking Node.js installation...
Node.js found: v20.19.3

[2/6] Verifying hash server executable...
Pre-built hash server found

[3/5] Installing project dependencies...
Dependencies installed

[4/5] Creating required directories...

[5/5] Starting services...
Hash Service: http://127.0.0.1:9001/health
Web Interface: http://localhost:3000
```

### Step 2: Access Web Interface

Open browser to: **http://localhost:3001**

---

## Common Issues & Solutions

### Issue 1: Hash Server Not Running

**Symptoms**:
- Error: `connect ECONNREFUSED 127.0.0.1:9001`
- Mining fails to start
- ROM initialization fails

**Diagnosis**:
```powershell
# Check if hash server is running
Get-Process | Where-Object {$_.ProcessName -like "*hash*"}

# Test health endpoint
Invoke-WebRequest -Uri "http://127.0.0.1:9001/health" -UseBasicParsing
```

**Solution**:
```powershell
# Start hash server manually
Start-Process -FilePath ".\hashengine\target\release\hash-server.exe" -WorkingDirectory "$PWD" -WindowStyle Normal

# Wait 3 seconds
Start-Sleep -Seconds 3

# Verify it's running
Get-Process | Where-Object {$_.ProcessName -eq "hash-server"}

# Test connection
Test-NetConnection -ComputerName 127.0.0.1 -Port 9001 -InformationLevel Quiet
# Should return: True
```

**Expected Hash Server Output**:
```
[INFO] HashEngine Native Hash Service (Rust)
[INFO] Listening: 127.0.0.1:9001
[INFO] Workers: 24 (multi-threaded)
[INFO] Parallel processing: rayon thread pool
[INFO] actix_server::server: Actix runtime found; starting in Actix runtime
[INFO] actix_server::server: starting service: "actix-web-service-127.0.0.1:9001", workers: 24
```

---

### Issue 2: Port 3001 Already in Use

**Symptoms**:
- Error: `listen EADDRINUSE: address already in use :::3001`
- Cannot start Next.js server

**Diagnosis**:
```powershell
# Check what's using port 3001
Get-NetTCPConnection -LocalPort 3001 -State Listen | Select-Object LocalAddress, LocalPort, OwningProcess

# Find the process
Get-Process -Id <OwningProcess>
```

**Solution**:
```powershell
# Stop all Node.js processes
Get-Process | Where-Object {$_.ProcessName -eq "node"} | Stop-Process -Force

# Restart Next.js server
npx next dev -p 3001
```

---

### Issue 3: Browser Won't Open Automatically

**Symptoms**:
- Setup completes but browser doesn't launch
- `Start-Process` commands have no effect

**Solution - Multiple Browser Detection**:
```powershell
# Try multiple browsers
$browsers = @(
    "$env:ProgramFiles\Google\Chrome\Application\chrome.exe",
    "$env:ProgramFiles(x86)\Google\Chrome\Application\chrome.exe",
    "$env:LOCALAPPDATA\Google\Chrome\Application\chrome.exe",
    "$env:ProgramFiles\Mozilla Firefox\firefox.exe",
    "$env:ProgramFiles(x86)\Mozilla Firefox\firefox.exe",
    "$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe"
)

foreach ($browser in $browsers) {
    if (Test-Path $browser) {
        Start-Process $browser "http://localhost:3001"
        Write-Host "Opened with: $browser"
        break
    }
}
```

**Manual Alternative**:
Just open any browser and navigate to: `http://localhost:3001`

---

### Issue 4: Stale Connections / Server Not Responding

**Symptoms**:
- Web page won't load
- Many CLOSE_WAIT connections
- Server appears running but unresponsive

**Diagnosis**:
```powershell
# Check for stale connections
netstat -ano | findstr ":3001"
# Look for many CLOSE_WAIT or FIN_WAIT_2 states
```

**Solution - Clean Restart**:
```powershell
# 1. Stop Next.js (get PID first)
Get-NetTCPConnection -LocalPort 3001 -State Listen | Select-Object OwningProcess
Stop-Process -Id <PID> -Force

# 2. Wait for cleanup
Start-Sleep -Seconds 2

# 3. Start fresh server
npx next dev -p 3001

# 4. Verify clean start
# Expected output:
#    ▲ Next.js 16.0.1 (Turbopack)
#    - Local:        http://localhost:3001
#    ✓ Ready in 563ms
```

---

## Performance Optimization

### CPU Core Utilization (CRITICAL)

**Problem**: Default configuration only uses 11 worker threads, leaving most CPU cores idle on multi-core systems.

**Check Current CPU Usage**:
```powershell
Get-Counter '\Processor(*)\% Processor Time' | Select-Object -ExpandProperty CounterSamples | Select-Object Path, CookedValue | Format-Table -AutoSize
```

**Optimal Configuration**:

1. **Determine Your CPU Core Count**:
   ```powershell
   (Get-WmiObject -Class Win32_Processor).NumberOfLogicalProcessors
   ```

2. **Calculate Optimal Worker Threads**:
   - Formula: `Total Cores - 2` (reserve 2 for system)
   - Example: 24 cores → 22 worker threads
   - Minimum: 8 worker threads
   - Maximum: Total cores - 1

3. **Edit Configuration**:
   
   **File**: `lib\mining\orchestrator.ts`  
   **Line**: 42

   ```typescript
   // BEFORE (inefficient - only 11 threads):
   private workerThreads = 11; // Number of parallel mining threads

   // AFTER (optimized for 24-core CPU):
   private workerThreads = 22; // Number of parallel mining threads (leaving 2 cores for system)
   ```

4. **Apply Changes**:
   ```powershell
   # Stop Next.js server
   Get-Process -Name node | Stop-Process -Force
   
   # Restart server (will rebuild with new config)
   npx next dev -p 3001
   ```

5. **Restart Mining in Web UI**:
   - Go to http://localhost:3001/mining
   - Click "Stop Mining"
   - Click "Start Mining"
   - New worker thread count will activate

**Expected Performance Improvement**:
- 11 threads: ~10,000 hashes/sec, ~40 solutions/day
- 22 threads: ~20,000+ hashes/sec, ~80+ solutions/day
- **2x performance increase**

**Verify Optimization**:
```powershell
# Check mining stats
Invoke-WebRequest -Uri "http://localhost:3001/api/mining/status" -UseBasicParsing | Select-Object -ExpandProperty Content

# Look for:
# "workerThreads": 22
# "hashRate": 20000+ (should be ~2x higher)
# "cpuUsage": 90-100 (much higher utilization)
```

---

## Verification Steps

### Verify All Services Running

```powershell
# 1. Check hash server
Get-Process | Where-Object {$_.ProcessName -eq "hash-server"}
# Should show: hash-server with high CPU and ~1GB memory

# 2. Check hash server health
Invoke-WebRequest -Uri "http://127.0.0.1:9001/health" -UseBasicParsing | Select-Object -ExpandProperty Content
# Should return: {"status":"ok","romInitialized":true,"nativeAvailable":true}

# 3. Check Next.js server
Get-Process | Where-Object {$_.ProcessName -eq "node"}
# Should show multiple node processes

# 4. Check wallet status
Invoke-WebRequest -Uri "http://localhost:3001/api/wallet/status" -UseBasicParsing | Select-Object -ExpandProperty Content
# Should return: {"exists":true}

# 5. Check mining status
Invoke-WebRequest -Uri "http://localhost:3001/api/mining/status" -UseBasicParsing | Select-Object -ExpandProperty Content
# Should return full mining stats including:
# - "active": true
# - "challengeId": "**D10C07"
# - "solutionsFound": <number>
# - "registeredAddresses": 200
# - "hashRate": <number>
# - "workerThreads": 22
```

### Verify Mining is Working

**Method 1: API Check**
```powershell
$status = Invoke-WebRequest -Uri "http://localhost:3001/api/mining/status" -UseBasicParsing | ConvertFrom-Json
Write-Host "Mining Active: $($status.stats.active)"
Write-Host "Hash Rate: $($status.stats.hashRate) h/s"
Write-Host "Solutions Today: $($status.stats.solutionsToday)"
Write-Host "Worker Threads: $($status.stats.workerThreads)"
Write-Host "CPU Usage: $($status.stats.cpuUsage)%"
```

**Method 2: Check Logs**
```powershell
# View today's mining log
Get-Content "logs\mining-$(Get-Date -Format 'yyyy-MM-dd').log" -Tail 20
```

**Method 3: Web Dashboard**
- Navigate to: http://localhost:3001/mining
- Look for:
  - ✅ Green "Mining Active" status
  - ✅ Incrementing hash rate
  - ✅ Solutions counter increasing
  - ✅ Challenge ID displayed
  - ✅ 200 addresses registered

**Signs of Successful Mining**:
- CPU usage: 90-100%
- Hash rate: 10,000+ hashes/sec (20,000+ with optimization)
- Solutions found: Several per hour
- Uptime: Continuously increasing
- Worker threads: Matching your configuration (22 recommended)

---

## Service Management

### Start All Services (After Reboot)

```powershell
# Navigate to project
cd $env:USERPROFILE\Documents\Midnight-Super-Miner

# Start hash server
Start-Process -FilePath ".\hashengine\target\release\hash-server.exe" -WorkingDirectory "$PWD" -WindowStyle Minimized

# Wait for hash server
Start-Sleep -Seconds 3

# Start Next.js
npx next dev -p 3001

# Open browser
Start-Process "http://localhost:3001"
```

### Stop All Services

```powershell
# Stop Next.js
Get-Process -Name node | Stop-Process -Force

# Stop hash server
Stop-Process -Name hash-server -Force

# Or use taskkill
taskkill /F /IM hash-server.exe
taskkill /F /IM node.exe
```

### Restart Services (Clean)

```powershell
# Stop everything
Get-Process -Name node | Stop-Process -Force
Stop-Process -Name hash-server -Force

# Wait for cleanup
Start-Sleep -Seconds 3

# Start hash server
Start-Process -FilePath ".\hashengine\target\release\hash-server.exe" -WorkingDirectory "$PWD" -WindowStyle Normal

# Wait for initialization
Start-Sleep -Seconds 3

# Start Next.js
npx next dev -p 3001
```

### Quick Run Script (Save as `quick-start.cmd`)

```batch
@echo off
echo Starting Midnight Super Miner...

echo [1/2] Starting hash server...
start "Hash Server" /MIN hashengine\target\release\hash-server.exe
timeout /t 3 /nobreak >nul

echo [2/2] Starting Next.js server...
npx next dev -p 3001
```

---

## Troubleshooting Checklist

Before asking for help, verify:

- [ ] Hash server process running: `Get-Process -Name hash-server`
- [ ] Hash server health OK: `curl http://127.0.0.1:9001/health`
- [ ] Next.js server running: `Get-Process -Name node`
- [ ] Port 3001 accessible: `Test-NetConnection -ComputerName localhost -Port 3001`
- [ ] Wallet exists: `Test-Path secure\wallet-seed.json.enc`
- [ ] Worker threads optimized: Check `lib\mining\orchestrator.ts:42`
- [ ] Mining active: Check http://localhost:3001/mining dashboard

---

## Performance Benchmarks

**Test System**: AMD Ryzen AI 9 HX 370 (24 cores)

| Configuration | Worker Threads | Hash Rate | Solutions/Day | CPU Usage |
|--------------|----------------|-----------|---------------|-----------|
| Default      | 11             | ~10,500   | ~40           | ~50%      |
| Optimized    | 22             | ~21,000   | ~80           | ~95%      |

**Your Results May Vary** based on:
- CPU model and core count
- RAM speed
- System background processes
- Challenge difficulty

---

## Advanced Configuration

### Batch Size Tuning

**File**: `lib\mining\orchestrator.ts`  
**Line**: 83

```typescript
private getBatchSize(): number {
  return this.customBatchSize || 300; // Default BATCH_SIZE
}
```

**Adjustment Guidelines**:
- **Lower RAM systems**: 200-250
- **Standard systems**: 300 (default)
- **High-end systems**: 350-400

### Environment Variables (Optional)

Create `.env` file in project root:

```env
# Dev fee control (false = disabled, true = enabled)
DEV_FEE_ENABLED=false

# API endpoint (usually don't change)
API_BASE=https://scavenger.prod.gd.midnighttge.io

# Polling interval (milliseconds)
POLL_INTERVAL_MS=2000
```

---

## Support & Logs

### Log Locations

- **Mining logs**: `logs\mining-YYYY-MM-DD.log`
- **Application logs**: Console output
- **Registration logs**: `logs\wallet-registration-progress.log`
- **Receipts**: `storage\receipts.jsonl`

### Useful Commands

```powershell
# View mining stats
Invoke-WebRequest -Uri "http://localhost:3001/api/mining/status" -UseBasicParsing

# View recent solutions
Get-Content "storage\receipts.jsonl" -Tail 10

# Monitor real-time logs
Get-Content "logs\mining-$(Get-Date -Format 'yyyy-MM-dd').log" -Wait

# Check system resources
Get-Process hash-server | Select-Object CPU, WorkingSet, Threads
Get-Process node | Select-Object CPU, WorkingSet, Threads | Sort-Object CPU -Descending | Select-Object -First 1
```

---

## Summary - Complete Setup Workflow

```powershell
# 1. Clone repository
cd $env:USERPROFILE\Documents
# ... download and extract ...

# 2. Navigate to project
cd Midnight-Super-Miner

# 3. Verify dev fee is disabled (default)
# Check: lib\devfee\manager.ts line 60

# 4. Optimize worker threads
# Edit: lib\mining\orchestrator.ts line 42
# Set to: (Your CPU cores - 2)

# 5. Run setup
.\setup.cmd

# 6. If hash server isn't running:
Start-Process -FilePath ".\hashengine\target\release\hash-server.exe" -WorkingDirectory "$PWD"

# 7. If Next.js has issues:
Get-Process -Name node | Stop-Process -Force
npx next dev -p 3001

# 8. Open browser
Start-Process "http://localhost:3001"

# 9. Create wallet or load existing

# 10. Start mining and enjoy!
```

---

**Troubleshooting Support**: Check logs directory and API endpoints  
**Performance Issues**: Verify worker thread optimization  
**Connection Issues**: Restart services in correct order (hash server first, then Next.js)

**Happy Mining! ⛏️🌙**
