#!/usr/bin/env bash
set -e

# NFQ Studio Multi-Platform Launcher & Device Manager
# Automatically uses local overrides from .env.local if present.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXAMPLE_DIR="$(dirname "$SCRIPT_DIR")"

# Load local environment configuration if present (git-ignored)
if [ -f "$EXAMPLE_DIR/.env.local" ]; then
  # shellcheck source=/dev/null
  source "$EXAMPLE_DIR/.env.local"
fi

PHONE_PORT="${PHONE_PORT:-5555}"

# Locate ADB binary portably
if command -v adb >/dev/null 2>&1; then
  ADB_BIN="adb"
elif [ -n "$ANDROID_HOME" ] && [ -x "$ANDROID_HOME/platform-tools/adb" ]; then
  ADB_BIN="$ANDROID_HOME/platform-tools/adb"
elif [ -n "$ANDROID_SDK_ROOT" ] && [ -x "$ANDROID_SDK_ROOT/platform-tools/adb" ]; then
  ADB_BIN="$ANDROID_SDK_ROOT/platform-tools/adb"
elif [ -x "$HOME/Android/Sdk/platform-tools/adb" ]; then
  ADB_BIN="$HOME/Android/Sdk/platform-tools/adb"
else
  ADB_BIN=""
fi

ensure_adb() {
  if [ -z "$ADB_BIN" ]; then
    echo "❌ Error: 'adb' not found in PATH or Android SDK platform-tools."
    echo "   Ensure Android SDK platform-tools is installed or set ANDROID_HOME."
    exit 1
  fi
}

# Resolve network phone target (argument > env/local > auto-detected from ADB)
resolve_phone_target() {
  local target="${1:-}"

  if [ -n "$target" ]; then
    # Add default port if only IP is supplied
    if [[ "$target" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
      echo "${target}:${PHONE_PORT}"
    else
      echo "$target"
    fi
    return
  fi

  if [ -n "${PHONE_TARGET:-}" ]; then
    echo "$PHONE_TARGET"
    return
  fi

  if [ -n "${PHONE_IP:-}" ]; then
    echo "${PHONE_IP}:${PHONE_PORT}"
    return
  fi

  ensure_adb
  # Attempt to auto-detect already connected network device from adb devices
  local detected
  detected="$("$ADB_BIN" devices | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:[0-9]+[[:space:]]+device' | awk '{print $1}' | head -n 1 || true)"
  if [ -n "$detected" ]; then
    echo "$detected"
    return
  fi

  echo ""
}

usage() {
  cat << EOF
🚀 NFQ Studio Multi-Platform Launcher

Usage: $0 [command] [options]

Commands:
  linux                     Run on Linux desktop
  web                       Run in Google Chrome
  web-server                Run on local web server (http://0.0.0.0:8080)
  phone-net [IP[:PORT]]     Run on phone over network (auto-detects or uses .env.local)
  phone-usb                 Run on phone via USB (auto-detects android device)
  phone-connect [IP[:PORT]] Connect ADB to phone over WiFi
  phone-tcpip [PORT]        Switch phone from USB to TCP/IP wireless mode (default: $PHONE_PORT)
  devices                   List connected Flutter & ADB devices
  build-linux               Build Linux release bundle
  build-web                 Build Web release bundle
  build-apk                 Build Android debug APK
  build-apk-release         Build Android release APK

Configuration:
  Create an optional, git-ignored 'example/.env.local' file:
    PHONE_IP=<DEVICE_IP>
    PHONE_PORT=5555

Examples:
  $0 linux
  $0 web
  $0 phone-net
  $0 phone-net <DEVICE_IP>
  $0 phone-usb
EOF
}

cd "$EXAMPLE_DIR"

case "${1:-}" in
  linux)
    echo "🐧 Launching NFQ Studio on Linux Desktop..."
    flutter run -d linux "${@:2}"
    ;;
  web)
    echo "🌐 Launching NFQ Studio in Chrome..."
    flutter run -d chrome "${@:2}"
    ;;
  web-server)
    echo "🌐 Launching NFQ Studio Web Server on http://0.0.0.0:8080..."
    flutter run -d web-server --web-port=8080 --web-hostname=0.0.0.0 "${@:2}"
    ;;
  phone-net)
    target="$(resolve_phone_target "${2:-}")"
    if [ -z "$target" ]; then
      echo "❌ Error: No phone target specified or detected."
      echo "   Usage: $0 phone-net <IP[:PORT]>"
      echo "   Or specify PHONE_IP in example/.env.local"
      exit 1
    fi
    ensure_adb
    echo "📱 Connecting ADB to $target..."
    "$ADB_BIN" connect "$target" || true
    echo "🚀 Running NFQ Studio on $target..."
    flutter run -d "$target" "${@:3}"
    ;;
  phone-usb)
    ensure_adb
    echo "🔌 Running NFQ Studio on USB Android device..."
    flutter run -d android "${@:2}"
    ;;
  phone-connect)
    target="$(resolve_phone_target "${2:-}")"
    if [ -z "$target" ]; then
      echo "❌ Error: No phone target specified."
      echo "   Usage: $0 phone-connect <IP[:PORT]>"
      echo "   Or specify PHONE_IP in example/.env.local"
      exit 1
    fi
    ensure_adb
    echo "📱 Connecting ADB to $target..."
    "$ADB_BIN" connect "$target"
    "$ADB_BIN" devices
    ;;
  phone-tcpip)
    ensure_adb
    port="${2:-$PHONE_PORT}"
    echo "🔌 Switching device from USB to TCP/IP on port $port..."
    "$ADB_BIN" tcpip "$port"
    echo "✅ Switched to TCP/IP on port $port. Disconnect USB and run:"
    echo "   $0 phone-connect <PHONE_IP>"
    ;;
  devices)
    ensure_adb
    echo "=== Flutter Devices ==="
    flutter devices
    echo ""
    echo "=== ADB Devices ==="
    "$ADB_BIN" devices -l
    ;;
  build-linux)
    echo "🔨 Building Linux release..."
    flutter build linux --release "${@:2}"
    ;;
  build-web)
    echo "🔨 Building Web release..."
    flutter build web --release "${@:2}"
    ;;
  build-apk)
    echo "🔨 Building Android debug APK..."
    flutter build apk --debug "${@:2}"
    ;;
  build-apk-release)
    echo "🔨 Building Android release APK..."
    flutter build apk --release "${@:2}"
    ;;
  help|--help|-h)
    usage
    ;;
  *)
    usage
    exit 1
    ;;
esac
