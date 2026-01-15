#!/bin/bash
# Monitor a running xcodebuild process to detect hangs
# Usage: Run this in a separate terminal while your build is running
#        ./scripts/monitor-xcodebuild.sh

echo "🔍 xcodebuild Process Monitor"
echo "=============================="
echo ""

# Find xcodebuild processes
while true; do
    clear
    echo "🔍 Monitoring xcodebuild processes..."
    echo "Time: $(date)"
    echo ""
    
    XCODE_PIDS=$(pgrep -f xcodebuild)
    
    if [ -z "$XCODE_PIDS" ]; then
        echo "❌ No xcodebuild processes found"
        echo ""
        echo "Looking for other build-related processes:"
        ps aux | grep -E "(flutter|fastlane|gym|Runner)" | grep -v grep
    else
        echo "✅ Found xcodebuild processes:"
        echo ""
        
        for PID in $XCODE_PIDS; do
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "PID: $PID"
            
            # Get process info
            ps -p $PID -o pid,ppid,state,time,%cpu,%mem,command
            echo ""
            
            # Get open files to see what it's working on
            echo "📂 Currently working on:"
            lsof -p $PID 2>/dev/null | tail -5
            echo ""
            
            # Check if process is hung (0% CPU for a while might indicate hang)
            CPU_USAGE=$(ps -p $PID -o %cpu | tail -1 | xargs)
            if (( $(echo "$CPU_USAGE < 1.0" | bc -l) )); then
                echo "⚠️  WARNING: Low CPU usage ($CPU_USAGE%) - might be hung"
            else
                echo "✅ Active CPU usage: $CPU_USAGE%"
            fi
            echo ""
            
            # Check process state
            STATE=$(ps -p $PID -o state | tail -1 | xargs)
            case $STATE in
                R) echo "✅ State: Running" ;;
                S) echo "⏸️  State: Sleeping (normal)" ;;
                D) echo "⚠️  State: Uninterruptible sleep (might be stuck on I/O)" ;;
                Z) echo "❌ State: Zombie (process is dead)" ;;
                T) echo "⏸️  State: Stopped" ;;
                *) echo "❓ State: $STATE" ;;
            esac
            echo ""
        done
        
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        
        # Check system resources
        echo "💻 System Resources:"
        echo "  CPU Load: $(uptime | awk -F'load averages:' '{print $2}')"
        echo "  Free Memory: $(vm_stat | awk '/Pages free/ {print $3*4096/1024/1024 " MB"}')"
        echo ""
        
        # Check for recent log activity
        echo "📋 Recent System Logs (last 5 Xcode-related):"
        log show --predicate 'subsystem contains "com.apple.dt.Xcode"' --last 30s 2>/dev/null | tail -5
        echo ""
    fi
    
    echo "Press Ctrl+C to stop monitoring"
    echo "Refreshing in 10 seconds..."
    sleep 10
done
