#!/bin/bash
# ============================================================================
# Midnight Fetcher Bot - Ubuntu Setup Script
# ============================================================================
# This script performs complete setup:
# 1. Checks/installs Node.js 20.x
# 2. Verifies pre-built hash server executable exists
# 3. Installs all dependencies
# 4. Builds NextJS application
# 5. Starts the app
#
# NOTE: Rust toolchain is NOT required - using pre-built hash-server
# ============================================================================

set -e  # Exit on error

echo ""
echo "================================================================================"
echo "                    Midnight Fetcher Bot - Setup"
echo "================================================================================"
echo ""

# ============================================================================
# Check for sudo privileges
# ============================================================================
if [ "$EUID" -eq 0 ]; then
    echo "WARNING: Running as root is not recommended."
    echo "Please run as a regular user. The script will prompt for sudo when needed."
    echo ""
    read -p "Press Enter to continue anyway or Ctrl+C to exit..."
fi

# ============================================================================
# Check Node.js
# ============================================================================
echo "[1/6] Checking Node.js installation..."
if ! command -v node &> /dev/null; then
    echo "Node.js not found. Installing Node.js 20.x..."
    echo ""

    # Add NodeSource repository
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
    sudo apt-get install -y nodejs

    echo "Node.js installed!"
    node --version
    echo ""
else
    echo "Node.js found!"
    node --version

    # Check version
    NODE_VERSION=$(node --version | cut -d'v' -f2 | cut -d'.' -f1)
    if [ "$NODE_VERSION" -lt 18 ]; then
        echo "WARNING: Node.js version is below 18. Version 20.x is recommended."
        echo "To upgrade, run:"
        echo "  curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -"
        echo "  sudo apt-get install -y nodejs"
        echo ""
        read -p "Continue anyway? (y/N) " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
    echo ""
fi

# ============================================================================
# NOTE: Rust build steps are commented out - using pre-built hash-server
# ============================================================================
# echo "[2/6] Checking Rust installation..."
# if ! command -v cargo &> /dev/null; then
#     echo "Rust not found. Installing Rust..."
#     echo ""
#     curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
#     source "$HOME/.cargo/env"
#     echo "Rust installed!"
#     cargo --version
#     echo ""
# else
#     echo "Rust found!"
#     cargo --version
#     echo ""
# fi

# ============================================================================
# Verify Hash Server Executable
# ============================================================================
echo "[2/6] Verifying hash server executable..."
if [ ! -f "hashengine/target/release/hash-server" ]; then
    echo ""
    echo "============================================================================"
    echo "ERROR: Pre-built hash server executable not found!"
    echo "Expected location: hashengine/target/release/hash-server"
    echo ""
    echo "This file should be included in the repository."
    echo "If you cloned the repo, ensure Git LFS is configured or re-clone."
    echo ""
    echo "If you want to build from source instead, you need to:"
    echo "  1. Install Rust from https://rustup.rs/"
    echo "  2. Run: cd hashengine && cargo build --release --bin hash-server"
    echo "============================================================================"
    echo ""
    exit 1
fi

# Make executable
chmod +x hashengine/target/release/hash-server
echo "Pre-built hash server found!"
echo ""

# ============================================================================
# Install dependencies
# ============================================================================
echo "[3/5] Installing project dependencies..."
npm install
echo "Dependencies installed!"
echo ""

# ============================================================================
# Create required directories
# ============================================================================
echo "[4/5] Creating required directories..."
mkdir -p secure
mkdir -p storage
mkdir -p logs
echo ""

# ============================================================================
# Setup complete, start services
# ============================================================================
echo "================================================================================"
echo "                         Setup Complete!"
echo "================================================================================"
echo ""
echo "[5/5] Starting services..."
echo ""

# Stop any existing instances
pkill -f hash-server || true
pkill -f "next" || true

# Start hash server in background
echo "Starting hash server on port 9001..."
export RUST_LOG=hash_server=info,actix_web=warn
export HOST=127.0.0.1
export PORT=9001
export WORKERS=12

nohup ./hashengine/target/release/hash-server > logs/hash-server.log 2>&1 &
HASH_SERVER_PID=$!
echo "  - Hash server started (PID: $HASH_SERVER_PID)"
echo ""

# Wait for hash server to be ready
echo "Waiting for hash server to initialize..."
sleep 3

# Check if hash server is responding
MAX_RETRIES=10
RETRY_COUNT=0
while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if curl -s http://127.0.0.1:9001/health > /dev/null 2>&1; then
        echo "  - Hash server is ready!"
        break
    fi
    echo "  - Waiting for hash server..."
    sleep 2
    RETRY_COUNT=$((RETRY_COUNT + 1))
done

if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
    echo "ERROR: Hash server failed to start. Check logs/hash-server.log"
    exit 1
fi
echo ""

echo "================================================================================"
echo "                    Midnight Fetcher Bot - Ready!"
echo "================================================================================"
echo ""
echo "Hash Service: http://127.0.0.1:9001/health"
echo "Web Interface: http://localhost:3000"
echo ""
echo "Press Ctrl+C to stop the Next.js server (hash server will continue running)"
echo ""
echo "To stop hash server: pkill -f hash-server"
echo "================================================================================"
echo ""

# Build production version
echo "Building production version..."
npm run build
echo "  - Production build complete!"
echo ""

# Start NextJS production server
echo "Starting Next.js production server..."
npm start &
NEXTJS_PID=$!
echo "  - Next.js server starting (PID: $NEXTJS_PID)..."
echo ""

# Wait for Next.js to be ready
echo "Waiting for Next.js to initialize..."
sleep 5
echo "  - Next.js server is ready!"
echo ""

# Try to open browser (if running in graphical environment)
if command -v xdg-open &> /dev/null; then
    echo "Opening web interface..."
    xdg-open http://localhost:3001 2>/dev/null || true
fi

echo ""
echo "================================================================================"
echo "Both services are running!"
echo "Hash Server PID: $HASH_SERVER_PID"
echo "Next.js PID: $NEXTJS_PID"
echo ""
echo "Press Ctrl+C to stop..."
echo "================================================================================"

# Trap Ctrl+C to cleanup
cleanup() {
    echo ""
    echo "Stopping services..."
    kill $NEXTJS_PID 2>/dev/null || true
    pkill -f hash-server 2>/dev/null || true
    echo "Services stopped."
    exit 0
}

trap cleanup SIGINT SIGTERM

# Wait for Next.js process
wait $NEXTJS_PID
