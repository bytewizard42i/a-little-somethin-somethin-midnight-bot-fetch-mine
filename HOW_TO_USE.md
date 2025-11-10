# 🌙 Midnight Super Miner - How to Use Guide

**For**: super-vibe-user  
**Created by**: AwesomeAi  
**Date**: November 7, 2025  
**Location**: `/home/js/Midnight-Super-Miner`

---

## 🎯 What Is This?

**Midnight Super Miner** (originally "Midnight Fetcher Bot") is a **NextJS mining application** for the Midnight Network. It mines cryptocurrency by solving cryptographic challenges using a Rust-powered hash engine.

**Created by**: Paddy (@PoolShamrock) & Paul (@cwpaulm)

---

## ⚡ Quick Start (Linux/WSL)

### Prerequisites Check

```bash
# Check Node.js (need v20.x)
node --version

# Check if you have Rust
rustc --version

# Check if you have Cargo
cargo --version
```

### Option 1: Automated Setup (Recommended)

```bash
# Navigate to the directory
cd /home/js/Midnight-Super-Miner

# Make setup script executable
chmod +x setup.sh

# Run setup (installs everything automatically)
./setup.sh
```

The script will:
1. ✅ Check/install Node.js 20.x
2. ✅ Check/install Rust toolchain
3. ✅ Build native Rust hash engine
4. ✅ Install all NPM dependencies
5. ✅ Build the NextJS application
6. ✅ Start the app on port 3001

### Option 2: Manual Setup

```bash
cd /home/js/Midnight-Super-Miner

# 1. Install Rust (if not installed)
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source $HOME/.cargo/env

# 2. Build Rust hash engine
cd hashengine
cargo build --release --bin hash-server
cd ..

# 3. Install Node dependencies
npm install

# 4. Build NextJS app
npm run build

# 5. Start the application
npm run start
```

### Access the App

Once running, open your browser to:
**http://localhost:3001**

---

## 🔐 First Time Setup - Create Your Wallet

### Step 1: Create Wallet
1. Click **"Create New Wallet"**
2. Enter a **strong password** (min 8 characters, use 12+!)
3. **CRITICAL**: Write down your **24-word seed phrase**
4. Store it safely offline (paper backup, safe, etc.)

⚠️ **WARNING**: Without your seed phrase, you CANNOT recover your wallet if you forget your password!

### Step 2: Automatic Address Generation
The app will automatically:
- Generate **200 mining addresses** from your seed
- Register all addresses with Midnight API (takes ~10 minutes due to rate limiting)
- This is a **one-time process**

### Step 3: Start Mining
1. Wait for all 200 addresses to register
2. Click **"Start Mining"**
3. Monitor your dashboard for real-time stats

---

## 📊 Dashboard Features

### Real-Time Statistics
- 🎯 **Challenge ID** - Current mining puzzle
- ✅ **Solutions Found** - Your successful submissions
- ⏱️ **Uptime** - How long you've been mining
- 📍 **Registered Addresses** - All 200 addresses ready
- 📈 **Hash Rate** - Mining performance
- 🔢 **Current Address** - Which address is actively mining

### Controls
- ▶️ **Start Mining** - Begin mining
- ⏹️ **Stop Mining** - Stop current session
- 🔄 **Auto-refresh** - Live updates via Server-Sent Events

---

## 🔄 Returning Users - Load Existing Wallet

If you already created a wallet:

1. Click **"Load Existing Wallet"**
2. Enter your password
3. Mining addresses load automatically
4. Click **"Start Mining"**

---

## 🏗️ How It Works (Architecture)

### The Mining Process

```
┌─────────────────────────────────────────────────┐
│  1. NextJS Web UI (Browser at :3001)           │
│     - Dashboard with real-time stats            │
│     - Wallet management interface               │
└────────────────┬────────────────────────────────┘
                 │
┌────────────────▼────────────────────────────────┐
│  2. NextJS API Server (Node.js)                │
│     - Mining orchestrator (11 worker threads)   │
│     - Wallet manager (Lucid Cardano)           │
│     - Address registration                      │
└────────────────┬────────────────────────────────┘
                 │
┌────────────────▼────────────────────────────────┐
│  3. Rust Hash Engine (Port 9001)               │
│     - Ultra-fast hashing (native performance)   │
│     - Parallel processing with Rayon            │
│     - ROM-based algorithm                       │
└────────────────┬────────────────────────────────┘
                 │
┌────────────────▼────────────────────────────────┐
│  4. Midnight Scavenger API                     │
│     - Challenge polling every 2 seconds         │
│     - Solution submission                       │
│     - Address registration                      │
└─────────────────────────────────────────────────┘
```

### Mining Flow
1. **Poll** - Check Midnight API for active challenges (every 2s)
2. **Select** - Pick an address from your 200 addresses
3. **Mine** - 11 parallel workers compute hashes for that address
4. **Find** - When solution found, pause all workers
5. **Verify** - Fetch fresh challenge data and re-verify
6. **Submit** - Submit solution to Midnight API
7. **Repeat** - Move to next address, continue mining

---

## 💰 Development Fee System (DISABLED by Default in super-vibe-user's Fork)

**In super-vibe-user's fork**: Dev fee is **DISABLED by default** - you keep 100% of your mining rewards!

Original app behavior (if you enable it):
- **1 solution per 17 user solutions** = ~5.88% dev fee
- This is **NOT a fee on your rewards** - you keep all your earnings
- The miner finds extra solutions for developer addresses
- Completely logged and transparent
- **Default in super-vibe-user's fork**: DISABLED (0%)
- **To enable**: Set `DEV_FEE_ENABLED=true` in `.env` file

---

## 📁 Project Structure

```
Midnight-Super-Miner/
├── setup.sh                    # Linux setup script
├── setup.cmd                   # Windows setup script
├── run.cmd                     # Windows run script
├── package.json                # Node.js dependencies
├── tsconfig.json              # TypeScript config
│
├── app/                        # NextJS App Router
│   ├── page.tsx               # Home page
│   ├── wallet/
│   │   ├── create/page.tsx   # Wallet creation UI
│   │   └── load/page.tsx     # Load wallet UI
│   ├── mining/page.tsx        # Mining dashboard
│   └── api/                   # API routes
│       ├── wallet/            # Wallet operations
│       ├── hash/              # Hash service proxy
│       └── mining/            # Mining control
│
├── lib/                       # Core business logic
│   ├── wallet/
│   │   └── manager.ts        # Wallet & address management
│   ├── hash/
│   │   └── engine.ts         # Hash engine client
│   ├── mining/
│   │   ├── orchestrator.ts   # Main mining brain (1600+ lines!)
│   │   └── solution-submitter.ts
│   └── devfee/
│       └── manager.ts        # Dev fee system
│
├── hashengine/                # Rust native hash engine
│   ├── Cargo.toml            # Rust dependencies
│   ├── src/
│   │   └── main.rs           # HTTP hash server (port 9001)
│   └── target/
│       └── release/
│           └── hash-server   # Compiled binary
│
├── secure/                    # Auto-created on first run
│   ├── wallet-seed.json.enc  # Encrypted seed phrase (AES-256-GCM)
│   └── addresses.json        # 200 mining addresses
│
├── storage/                   # Auto-created
│   └── receipts.jsonl        # Mining solution receipts
│
└── logs/                      # Auto-created
    ├── app.log                        # Application logs
    └── wallet-registration-progress.log  # Registration status
```

---

## 🔧 Configuration & Tuning

### Performance Tuning

Edit `lib/mining/orchestrator.ts` to adjust:

```typescript
// Batch size for hash computation
const BATCH_SIZE = 350;  // Increase for more throughput

// Number of parallel workers
private workerThreads = 12;  // Increase for more CPU cores
```

**Recommendations**:
- **8 CPU cores**: 12 workers, batch size 350
- **16 CPU cores**: 20 workers, batch size 500
- **32 CPU cores**: 32 workers, batch size 700

### Advanced Configuration

Create `config.json` (optional):

```json
{
  "apiBase": "https://scavenger.prod.gd.midnighttge.io",
  "pollIntervalMs": 30000,
  "cpuThreads": 8,
  "walletAutogen": {
    "count": 200,
    "destinationIndexForDonation": 0
  }
}
```

---

## 🔒 Security Best Practices

### Wallet Security
- ✅ **Strong Password**: Use 12+ characters with mixed case, numbers, symbols
- ✅ **Offline Backup**: Write seed phrase on paper, store in safe
- ✅ **Never Share**: Never share seed phrase with anyone
- ✅ **Backup Directory**: Copy `secure/` folder to external drive
- ❌ **No Screenshots**: Never digitally store your seed phrase

### How Encryption Works
- Seed phrase encrypted with **AES-256-GCM**
- Password hashed with **scrypt** (memory-hard KDF)
- Encrypted file: `secure/wallet-seed.json.enc`
- All signing done **locally** (no network transmission of keys)

---

## 🐛 Troubleshooting

### Setup Issues

**"Node.js not found"**
```bash
# Install Node.js 20.x
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs
```

**"Rust not found"**
```bash
# Install Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source $HOME/.cargo/env
```

**"Native module build failed"**
```bash
# Install build tools
sudo apt-get install build-essential pkg-config libssl-dev

# Retry build
cd hashengine
cargo build --release --bin hash-server
```

### Runtime Issues

**"Failed to decrypt wallet"**
- Double-check your password (case-sensitive!)
- Ensure `secure/wallet-seed.json.enc` exists
- If forgotten: Use your 24-word seed phrase to recreate

**"Address registration failing"**
- Check internet connection
- API has rate limiting (waits 1.5s between addresses)
- Check `logs/wallet-registration-progress.log`
- This is normal - takes ~10 minutes for 200 addresses

**"Mining not starting"**
- Wait for all 200 addresses to register
- Check if challenge is active (mining has time windows)
- Verify ROM initialization completed
- Check `logs/app.log` for errors

**"Port 3001 already in use"**
```bash
# Find process using port
lsof -i :3001

# Kill it
kill -9 <PID>

# Or use different port
npm run start -- -p 3002
```

**"Hash engine not responding"**
```bash
# Check if hash server is running
curl http://localhost:9001/health

# Restart hash engine
cd hashengine
./target/release/hash-server
```

---

## 📝 Common Commands

### Development
```bash
# Start development server (hot reload)
npm run dev

# Access at http://localhost:3001
```

### Production
```bash
# Build for production
npm run build

# Start production server
npm run start
```

### Maintenance
```bash
# Build just the hash engine
npm run build:hash

# View logs
tail -f logs/app.log
tail -f logs/wallet-registration-progress.log

# View receipts
cat storage/receipts.jsonl | jq
```

---

## 📈 Monitoring & Logs

### Log Files
- **`logs/app.log`** - General application logs
- **`logs/wallet-registration-progress.log`** - Address registration status
- **`storage/receipts.jsonl`** - Mining solution receipts (JSONL format)

### Real-Time Monitoring
```bash
# Watch mining receipts in real-time
tail -f storage/receipts.jsonl

# Watch application logs
tail -f logs/app.log

# Count solutions
cat storage/receipts.jsonl | wc -l
```

---

## ❓ FAQ

**Q: Can I use this on multiple computers?**  
A: Yes! Copy your `secure/` directory and use the same password on another machine.

**Q: What if I forget my password?**  
A: You'll need your 24-word seed phrase to recover. Without it, wallet is unrecoverable.

**Q: Can I change the number of addresses?**  
A: Yes, modify `count` parameter when creating wallet (default: 200, max: 500).

**Q: Is my seed phrase sent to servers?**  
A: **NO!** All wallet operations are local. Only public addresses and signatures are sent to Midnight API.

**Q: How much can I earn?**  
A: Depends on:
- Your hardware (CPU speed, cores)
- Number of miners on network
- Challenge difficulty
- Time spent mining

**Q: Does this work on Mac/Linux/WSL?**  
A: **YES!** Use `setup.sh` instead of `setup.cmd`. It's cross-platform.

---

## 🚀 Quick Reference

### Start Mining (After Setup)
```bash
cd /home/js/Midnight-Super-Miner
npm run start
# Open http://localhost:3001
```

### Check Status
```bash
# Check if mining
curl http://localhost:3001/api/mining/status

# Check hash engine
curl http://localhost:9001/health
```

### Backup Your Wallet
```bash
# Copy encrypted wallet
cp -r secure ~/wallet-backup-$(date +%Y%m%d)

# Also write down your 24-word seed phrase!
```

---

## 🎯 Important Notes

1. **First run takes 10+ minutes** - Address registration is rate-limited
2. **Development fee is 4.17%** - Can be disabled in config
3. **Seed phrase is CRITICAL** - Back it up offline immediately
4. **Mining has windows** - Not all challenges are active 24/7
5. **Early beta software** - Expect bugs, use at own risk

---

## 📞 Support & Resources

### Official Links
- **Midnight Network**: https://midnight.network/
- **Lucid Cardano**: https://github.com/spacebudz/lucid
- **Original Creators**: Paddy (@PoolShamrock) & Paul (@cwpaulm) on X/Twitter

### For Help
- Check logs in `logs/` directory
- Review DOCUMENTATION.md (1140 lines of detailed docs)
- Console output in terminal
- GitHub issues: https://github.com/bytewizard42i/a-little-somethin-somethin-midnight-bot-fetch-mine

---

## ⚠️ Disclaimer

**USE AT YOUR OWN RISK!**

- This software is provided as-is
- Authors take **ZERO RESPONSIBILITY** for lost funds or rewards
- Always backup your seed phrase and secure your passwords
- Early beta - bugs are expected
- Not officially endorsed by Midnight Network

---

## 🌟 Summary - TL;DR

1. **Setup**: Run `./setup.sh` (auto-installs everything)
2. **Create Wallet**: Go to http://localhost:3001, create wallet, **SAVE SEED PHRASE**
3. **Wait**: 10 minutes for 200 addresses to register
4. **Mine**: Click "Start Mining"
5. **Monitor**: Watch dashboard for solutions
6. **Profit**: Keep mining to earn Midnight tokens!

---

**Built by**: Paddy & Paul  
**Cloned by**: AwesomeAi for super-vibe-user  
**Location**: `/home/js/Midnight-Super-Miner`  
**Ready to mine**: YES! 🌙⛏️

**Happy Mining, super-vibe-user!** 💰🚀
