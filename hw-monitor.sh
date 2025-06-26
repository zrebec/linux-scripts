#!/bin/bash
# Hardware Monitor v1.0 - System Health Dashboard 🖥️
# Monitor CPU, GPU, storage temperatures and system performance
# Compatible with Arch Linux and NVIDIA graphics cards
#
# Author: Luna AI Assistant 🤖
# License: MIT 📄

# ═══════════════════════════════════════════════════════════════════════════════
# 🎛️  CONFIGURATION SECTION
# ═══════════════════════════════════════════════════════════════════════════════

# Temperature thresholds (Celsius)
CPU_TEMP_WARNING=70     # 🟡 CPU warning temperature
CPU_TEMP_CRITICAL=85    # 🔴 CPU critical temperature
GPU_TEMP_WARNING=75     # 🟡 GPU warning temperature
GPU_TEMP_CRITICAL=90    # 🔴 GPU critical temperature
NVME_TEMP_WARNING=60    # 🟡 NVMe warning temperature
NVME_TEMP_CRITICAL=80   # 🔴 NVMe critical temperature

# System load thresholds
CPU_LOAD_WARNING=80     # 🟡 CPU usage warning (%)
MEMORY_WARNING=85       # 🟡 Memory usage warning (%)
DISK_WARNING=90         # 🟡 Disk usage warning (%)

# Auto-refresh settings
AUTO_REFRESH=false      # 🔄 Auto-refresh every few seconds
REFRESH_INTERVAL=3      # ⏱️ Refresh interval in seconds

# ═══════════════════════════════════════════════════════════════════════════════
# 🎨 COLOR PALETTE FOR BEAUTIFUL OUTPUT
# ═══════════════════════════════════════════════════════════════════════════════

RED='\033[0;31m'       # 🔴 Critical alerts and errors
GREEN='\033[0;32m'     # 🟢 Normal/good status
YELLOW='\033[1;33m'    # 🟡 Warnings and attention
BLUE='\033[0;34m'      # 🔵 Information and details
MAGENTA='\033[0;35m'   # 🟣 Special highlights
CYAN='\033[0;36m'      # 🔷 Headers and titles
WHITE='\033[1;37m'     # ⚪ Emphasized values
GRAY='\033[0;37m'      # ⚫ Secondary information
BOLD='\033[1m'         # 💪 Bold text
RESET='\033[0m'        # 🏁 Reset formatting

# ═══════════════════════════════════════════════════════════════════════════════
# 🎭 UTILITY FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════════════

# Print colored text with emoji support
print_color() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${RESET}"
}

# Print a fancy header
print_header() {
    local title="$1"
    local emoji="$2"
    echo
    print_color $CYAN "╔═══════════════════════════════════════════════════════════════════════════════╗"
    printf "${CYAN}║${RESET} ${emoji} ${WHITE}%-70s${CYAN} ║${RESET}\n" "$title"
    print_color $CYAN "╚═══════════════════════════════════════════════════════════════════════════════╝"
    echo
}

# Print status with color based on value and thresholds
print_temp_status() {
    local temp=$1
    local warning=$2
    local critical=$3
    local label="$4"

    if (( $(echo "$temp >= $critical" | bc -l) )); then
        printf "${RED}🔥 %-15s ${BOLD}%3.1f°C${RESET} ${RED}(CRITICAL!)${RESET}\n" "$label:" "$temp"
    elif (( $(echo "$temp >= $warning" | bc -l) )); then
        printf "${YELLOW}⚠️  %-15s ${BOLD}%3.1f°C${RESET} ${YELLOW}(Warning)${RESET}\n" "$label:" "$temp"
    else
        printf "${GREEN}✅ %-15s ${BOLD}%3.1f°C${RESET} ${GREEN}(Good)${RESET}\n" "$label:" "$temp"
    fi
}

# Print percentage status with color
print_percent_status() {
    local value=$1
    local warning=$2
    local label="$3"
    local unit="${4:-%}"
    local extra_info="$5"

    # Use echo instead of printf to avoid format character issues
    if (( $(echo "$value >= $warning" | bc -l) )); then
        echo -e "${YELLOW}⚠️  $(printf "%-15s" "$label:")${RESET} ${BOLD}$(printf "%3.1f" "$value")${unit}${RESET} ${YELLOW}(High)${RESET}${extra_info}"
    else
        echo -e "${GREEN}✅ $(printf "%-15s" "$label:")${RESET} ${BOLD}$(printf "%3.1f" "$value")${unit}${RESET} ${GREEN}(Normal)${RESET}${extra_info}"
    fi
}

# Create a progress bar
create_progress_bar() {
    local value=$1
    local max_value=$2
    local width=20

    local percentage=$(echo "scale=0; $value * 100 / $max_value" | bc)
    local filled=$(echo "scale=0; $width * $value / $max_value" | bc)
    filled=${filled%.*}

    local bar=""
    for ((i=1; i<=width; i++)); do
        if [ $i -le $filled ]; then
            if [ $percentage -ge 90 ]; then
                bar="${bar}${RED}█${RESET}"
            elif [ $percentage -ge 70 ]; then
                bar="${bar}${YELLOW}█${RESET}"
            else
                bar="${bar}${GREEN}█${RESET}"
            fi
        else
            bar="${bar}${GRAY}░${RESET}"
        fi
    done

    echo "$bar"
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🌡️ TEMPERATURE MONITORING FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════════════

# Get CPU temperature
get_cpu_temperature() {
    local cpu_temp=0

    # Try different methods to get CPU temperature
    if [ -f /sys/class/thermal/thermal_zone0/temp ]; then
        # Most common method on Linux
        cpu_temp=$(cat /sys/class/thermal/thermal_zone0/temp)
        cpu_temp=$(echo "scale=1; $cpu_temp / 1000" | bc)
    elif command -v sensors >/dev/null 2>&1; then
        # Using lm-sensors
        cpu_temp=$(sensors | grep -i "package id 0\|core 0\|cpu" | head -1 | grep -o "+[0-9]*\.[0-9]*°C" | tr -d "+°C" | head -1)
        if [[ -z "$cpu_temp" ]]; then
            cpu_temp=$(sensors | grep -i temp | head -1 | grep -o "+[0-9]*\.[0-9]*°C" | tr -d "+°C" | head -1)
        fi
    fi

    # Fallback if no temperature found
    if [[ -z "$cpu_temp" || "$cpu_temp" == "0" ]]; then
        cpu_temp="N/A"
    fi

    echo "$cpu_temp"
}

# Get GPU temperature (NVIDIA)
get_gpu_temperature() {
    local gpu_temp="N/A"

    if command -v nvidia-smi >/dev/null 2>&1; then
        gpu_temp=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits | head -1)
        if [[ -z "$gpu_temp" ]]; then
            gpu_temp="N/A"
        fi
    fi

    echo "$gpu_temp"
}

# Get NVMe SSD temperatures
get_nvme_temperatures() {
    local nvme_temps=()
    local nvme_names=()

    # Method 1: Try nvme-cli with smart-log
    if command -v nvme >/dev/null 2>&1; then
        for device in /dev/nvme*n1; do
            if [ -e "$device" ]; then
                local device_name=$(basename "$device")
                local temp=$(sudo nvme smart-log "$device" 2>/dev/null | grep -i "temperature" | head -1 | grep -oE '[0-9]+' | head -1)
                if [[ -n "$temp" && "$temp" != "0" && "$temp" -gt 0 && "$temp" -lt 200 ]]; then
                    nvme_temps+=("$temp")
                    nvme_names+=("$device_name")
                fi
            fi
        done
    fi

    # Method 2: Try smartctl if nvme-cli didn't work
    if [ ${#nvme_temps[@]} -eq 0 ] && command -v smartctl >/dev/null 2>&1; then
        for device in /dev/nvme*n1; do
            if [ -e "$device" ]; then
                local device_name=$(basename "$device")
                local temp=$(sudo smartctl -A "$device" 2>/dev/null | grep -i "temperature" | head -1 | grep -oE '[0-9]+' | head -1)
                if [[ -n "$temp" && "$temp" != "0" && "$temp" -gt 0 && "$temp" -lt 200 ]]; then
                    nvme_temps+=("$temp")
                    nvme_names+=("$device_name")
                fi
            fi
        done
    fi

    # Method 3: Try hwmon (thermal zones)
    if [ ${#nvme_temps[@]} -eq 0 ]; then
        for hwmon in /sys/class/hwmon/hwmon*; do
            if [ -d "$hwmon" ]; then
                local name_file="$hwmon/name"
                if [ -f "$name_file" ]; then
                    local name=$(cat "$name_file" 2>/dev/null)
                    if [[ "$name" == *"nvme"* ]]; then
                        local temp_file="$hwmon/temp1_input"
                        if [ -f "$temp_file" ]; then
                            local temp=$(cat "$temp_file" 2>/dev/null)
                            if [[ -n "$temp" && "$temp" -gt 0 ]]; then
                                temp=$(echo "scale=0; $temp / 1000" | bc)
                                if [[ "$temp" -gt 0 && "$temp" -lt 200 ]]; then
                                    nvme_temps+=("$temp")
                                    nvme_names+=("$name")
                                fi
                            fi
                        fi
                    fi
                fi
            fi
        done
    fi

    # Output results
    for i in "${!nvme_temps[@]}"; do
        echo "${nvme_temps[$i]} ${nvme_names[$i]}"
    done
}

# ═══════════════════════════════════════════════════════════════════════════════
# 📊 SYSTEM PERFORMANCE MONITORING
# ═══════════════════════════════════════════════════════════════════════════════

# Get CPU usage percentage and process count
get_cpu_usage() {
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
    local process_count=$(ps aux | wc -l)
    process_count=$((process_count - 1))  # Remove header line

    # Return: cpu_usage,process_count
    echo "$cpu_usage,$process_count"
}

# Get memory usage with human readable format
get_memory_usage() {
    local mem_info=$(free | grep Mem)
    local total=$(echo "$mem_info" | awk '{print $2}')
    local used=$(echo "$mem_info" | awk '{print $3}')
    local available=$(echo "$mem_info" | awk '{print $7}')
    local usage_percent=$(echo "scale=1; $used * 100 / $total" | bc)

    # Convert to human readable format
    local used_gb=$(echo "scale=1; $used / 1024 / 1024" | bc)
    local total_gb=$(echo "scale=1; $total / 1024 / 1024" | bc)
    local available_gb=$(echo "scale=1; $available / 1024 / 1024" | bc)

    # Return: percentage,used_gb,total_gb,available_gb
    echo "$usage_percent,$used_gb,$total_gb,$available_gb"
}

# Get disk usage for main partitions
get_disk_usage() {
    df -h | grep -E '^/dev/' | while read line; do
        local device=$(echo "$line" | awk '{print $1}')
        local usage=$(echo "$line" | awk '{print $5}' | tr -d '%')
        local mount=$(echo "$line" | awk '{print $6}')

        printf "%-20s %3s%% %s\n" "$(basename "$device")" "$usage" "$mount"
    done
}

# Get system load average
get_load_average() {
    local load=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | tr -d ',')
    echo "$load"
}

# Get GPU usage (NVIDIA)
get_gpu_usage() {
    local gpu_usage="N/A"

    if command -v nvidia-smi >/dev/null 2>&1; then
        gpu_usage=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits | head -1)
        if [[ -z "$gpu_usage" ]]; then
            gpu_usage="N/A"
        fi
    fi

    echo "$gpu_usage"
}

# ═══════════════════════════════════════════════════════════════════════════════
# 📺 DISPLAY FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════════════

# Display temperature monitoring
show_temperatures() {
    print_color $CYAN "🌡️  TEMPERATURE MONITORING:"
    echo

    # CPU Temperature
    local cpu_temp=$(get_cpu_temperature)
    if [[ "$cpu_temp" != "N/A" ]]; then
        print_temp_status "$cpu_temp" "$CPU_TEMP_WARNING" "$CPU_TEMP_CRITICAL" "CPU"
    else
        print_color $GRAY "❓ CPU:             Temperature not available"
    fi

    # GPU Temperature
    local gpu_temp=$(get_gpu_temperature)
    if [[ "$gpu_temp" != "N/A" ]]; then
        print_temp_status "$gpu_temp" "$GPU_TEMP_WARNING" "$GPU_TEMP_CRITICAL" "GPU (NVIDIA)"
    else
        print_color $GRAY "❓ GPU:             No NVIDIA GPU detected or driver missing"
    fi

    # NVMe SSD Temperatures
    local nvme_count=0
    while IFS=' ' read -r nvme_temp nvme_name; do
        if [[ -n "$nvme_temp" && "$nvme_temp" != "0" ]]; then
            nvme_count=$((nvme_count + 1))
            print_temp_status "$nvme_temp" "$NVME_TEMP_WARNING" "$NVME_TEMP_CRITICAL" "NVMe ($nvme_name)"
        fi
    done < <(get_nvme_temperatures)

    if [ $nvme_count -eq 0 ]; then
        print_color $GRAY "❓ NVMe SSD:        No NVMe drives detected or sudo access needed"
        print_color $GRAY "                   Try: sudo hw-monitor temp"
    fi

    echo
}

# Display system performance
show_performance() {
    print_color $CYAN "📊 SYSTEM PERFORMANCE:"
    echo

    # CPU Usage
    local cpu_data=$(get_cpu_usage)
    local cpu_usage=$(echo "$cpu_data" | cut -d',' -f1)
    local process_count=$(echo "$cpu_data" | cut -d',' -f2)

    local cpu_extra_info=""
    if [[ -n "$process_count" ]]; then
        cpu_extra_info=" ${GRAY}(${process_count} processes)${RESET}"
    fi

    print_percent_status "$cpu_usage" "$CPU_LOAD_WARNING" "CPU Usage" "%" "$cpu_extra_info"
    local cpu_bar=$(create_progress_bar "$cpu_usage" 100)
    print_color $GRAY "                   $cpu_bar"

    # Memory Usage
    local mem_data=$(get_memory_usage)
    local mem_usage=$(echo "$mem_data" | cut -d',' -f1)
    local mem_used_gb=$(echo "$mem_data" | cut -d',' -f2)
    local mem_total_gb=$(echo "$mem_data" | cut -d',' -f3)
    local mem_available_gb=$(echo "$mem_data" | cut -d',' -f4)

    local mem_extra_info=""
    if [[ -n "$mem_used_gb" && -n "$mem_total_gb" ]]; then
        mem_extra_info=" ${GRAY}(${mem_used_gb}GB / ${mem_total_gb}GB used)${RESET}"
    fi

    print_percent_status "$mem_usage" "$MEMORY_WARNING" "Memory Usage" "%" "$mem_extra_info"
    local mem_bar=$(create_progress_bar "$mem_usage" 100)
    print_color $GRAY "                   $mem_bar"

    # GPU Usage
    local gpu_usage=$(get_gpu_usage)
    if [[ "$gpu_usage" != "N/A" ]]; then
        print_percent_status "$gpu_usage" "80" "GPU Usage"
        local gpu_bar=$(create_progress_bar "$gpu_usage" 100)
        print_color $GRAY "                   $gpu_bar"
    else
        print_color $GRAY "❓ GPU Usage:       No NVIDIA GPU detected"
    fi

    # Load Average
    local load_avg=$(get_load_average)
    local cpu_cores=$(nproc)
    local load_percent=$(echo "scale=1; $load_avg * 100 / $cpu_cores" | bc)
    print_percent_status "$load_percent" "100" "Load Average" ""
    print_color $GRAY "                   (${load_avg} on ${cpu_cores} cores)"

    echo
}

# Display disk usage
show_disk_usage() {
    print_color $CYAN "💾 STORAGE USAGE:"
    echo

    get_disk_usage | while IFS= read -r line; do
        if [[ -n "$line" ]]; then
            local device=$(echo "$line" | awk '{print $1}')
            local usage=$(echo "$line" | awk '{print $2}' | tr -d '%')
            local mount=$(echo "$line" | awk '{print $3}')

            if [[ -n "$usage" && "$usage" =~ ^[0-9]+$ ]]; then
                if (( usage >= DISK_WARNING )); then
                    printf "${YELLOW}⚠️  %-20s ${BOLD}%3s%%${RESET} ${YELLOW}%s (High usage!)${RESET}\n" "$device" "$usage" "$mount"
                else
                    printf "${GREEN}✅ %-20s ${BOLD}%3s%%${RESET} ${GREEN}%s${RESET}\n" "$device" "$usage" "$mount"
                fi

                local disk_bar=$(create_progress_bar "$usage" 100)
                print_color $GRAY "                   $disk_bar"
            fi
        fi
    done

    echo
}

# Display system information
show_system_info() {
    print_color $CYAN "🖥️  SYSTEM INFORMATION:"
    echo

    local hostname=""
    if [ -f /etc/hostname ]; then
        hostname=$(cat /etc/hostname 2>/dev/null | tr -d '\n')
    elif command -v hostname >/dev/null 2>&1; then
        hostname=$(hostname 2>/dev/null)
    else
        hostname="unknown"
    fi

    local uptime=$(uptime -p 2>/dev/null | sed 's/up //' || echo "unknown")
    local kernel=$(uname -r 2>/dev/null || echo "unknown")
    local arch=$(uname -m 2>/dev/null || echo "unknown")

    print_color $WHITE "   🏷️  Hostname:       $hostname"
    print_color $WHITE "   ⏰ Uptime:         $uptime"
    print_color $WHITE "   🐧 Kernel:         $kernel"
    print_color $WHITE "   🏗️  Architecture:   $arch"

    # CPU info
    local cpu_model=$(grep "model name" /proc/cpuinfo | head -1 | cut -d: -f2 | sed 's/^ *//')
    local cpu_cores=$(nproc)
    print_color $WHITE "   🔧 CPU:            $cpu_model ($cpu_cores cores)"

    # Memory info
    local total_mem=$(free -h | grep Mem | awk '{print $2}')
    print_color $WHITE "   🧠 Total Memory:   $total_mem"

    # GPU info
    if command -v nvidia-smi >/dev/null 2>&1; then
        local gpu_name=$(nvidia-smi --query-gpu=name --format=csv,noheader | head -1)
        print_color $WHITE "   🎮 GPU:            $gpu_name"
    fi

    echo
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🎮 INTERACTIVE FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════════════

# Show full dashboard
show_dashboard() {
    clear
    print_header "Hardware Monitor Dashboard" "🖥️"

    local current_time=$(date "+%Y-%m-%d %H:%M:%S")
    print_color $GRAY "Last updated: $current_time"
    echo

    show_system_info
    show_temperatures
    show_performance  
    show_disk_usage

    # Show warnings if any
    local warnings=0
    local cpu_temp=$(get_cpu_temperature)
    local gpu_temp=$(get_gpu_temperature)
    local cpu_usage=$(get_cpu_usage)
    local mem_usage=$(get_memory_usage)

    if [[ "$cpu_temp" != "N/A" ]] && (( $(echo "$cpu_temp >= $CPU_TEMP_WARNING" | bc -l) )); then
        warnings=$((warnings + 1))
    fi
    if [[ "$gpu_temp" != "N/A" ]] && (( $(echo "$gpu_temp >= $GPU_TEMP_WARNING" | bc -l) )); then
        warnings=$((warnings + 1))
    fi
    if (( $(echo "$cpu_usage >= $CPU_LOAD_WARNING" | bc -l) )); then
        warnings=$((warnings + 1))
    fi
    if (( $(echo "$mem_usage >= $MEMORY_WARNING" | bc -l) )); then
        warnings=$((warnings + 1))
    fi

    if [ $warnings -gt 0 ]; then
        print_color $YELLOW "⚠️  $warnings warning(s) detected - consider checking your system!"
    else
        print_color $GREEN "✅ All systems running normally!"
    fi

    echo
    print_color $GRAY "────────────────────────────────────────────────────────────────────────────────"
}

# Watch mode with auto-refresh
watch_mode() {
    print_header "Hardware Monitor - Watch Mode" "👁️"
    print_color $YELLOW "🔄 Auto-refreshing every $REFRESH_INTERVAL seconds. Press Ctrl+C to exit."
    echo

    while true; do
        show_dashboard
        print_color $CYAN "Next refresh in $REFRESH_INTERVAL seconds... (Ctrl+C to exit)"
        sleep $REFRESH_INTERVAL
    done
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🔧 DIAGNOSTIC AND SETUP FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════════════

# Check for required tools and dependencies
check_dependencies() {
    print_header "Dependency Check" "🔍"

    local missing_tools=0

    # Essential tools
    print_color $CYAN "📋 Checking essential tools:"

    if command -v bc >/dev/null 2>&1; then
        print_color $GREEN "✅ bc (calculator) - Available"
    else
        print_color $RED "❌ bc (calculator) - Missing"
        print_color $YELLOW "   Install with: sudo pacman -S bc"
        missing_tools=$((missing_tools + 1))
    fi

    # Optional but recommended tools
    echo
    print_color $CYAN "🔧 Checking hardware monitoring tools:"

    if command -v sensors >/dev/null 2>&1; then
        print_color $GREEN "✅ lm-sensors - Available"
    else
        print_color $YELLOW "⚠️  lm-sensors - Missing (recommended for better CPU temp detection)"
        print_color $GRAY "   Install with: sudo pacman -S lm-sensors"
        print_color $GRAY "   Then run: sudo sensors-detect"
    fi

    if command -v nvidia-smi >/dev/null 2>&1; then
        print_color $GREEN "✅ NVIDIA drivers - Available"
        local driver_version=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader | head -1)
        print_color $GRAY "   Driver version: $driver_version"
    else
        print_color $GRAY "❓ NVIDIA drivers - Not detected (normal if you don't have NVIDIA GPU)"
    fi

    if command -v nvme >/dev/null 2>&1; then
        print_color $GREEN "✅ nvme-cli - Available"
    else
        print_color $YELLOW "⚠️  nvme-cli - Missing (needed for NVMe SSD temperatures)"
        print_color $GRAY "   Install with: sudo pacman -S nvme-cli"
    fi

    if command -v smartctl >/dev/null 2>&1; then
        print_color $GREEN "✅ smartmontools - Available"
    else
        print_color $YELLOW "⚠️  smartmontools - Missing (alternative for disk health)"
        print_color $GRAY "   Install with: sudo pacman -S smartmontools"
    fi

    echo
    if [ $missing_tools -eq 0 ]; then
        print_color $GREEN "✅ All essential tools available!"
    else
        print_color $RED "❌ $missing_tools essential tool(s) missing"
        print_color $YELLOW "💡 Install missing tools for full functionality"
    fi

    echo
    print_color $CYAN "🔒 Sudo requirements:"
    print_color $GRAY "   • NVMe temperature monitoring requires sudo access"
    print_color $GRAY "   • Consider adding to sudoers for passwordless access:"
    print_color $WHITE "   echo \"$USER ALL=(ALL) NOPASSWD: /usr/bin/nvme, /usr/bin/smartctl\" | sudo tee /etc/sudoers.d/hw-monitor"

    print_color $GRAY "────────────────────────────────────────────────────────────────────────────────"
}

# Show help information
show_help() {
    clear
    print_color $CYAN "╔═══════════════════════════════════════════════════════════════════════════════╗"
    print_color $CYAN "║                                                                               ║"
    printf "${CYAN}║${WHITE}                    🖥️  HARDWARE MONITOR v1.0 📊                            ${CYAN}║${RESET}\n"
    printf "${CYAN}║${GRAY}                    Real-time System Health Dashboard                         ${CYAN}║${RESET}\n"
    print_color $CYAN "║                                                                               ║"
    print_color $CYAN "╚═══════════════════════════════════════════════════════════════════════════════╝"
    echo

    print_color $YELLOW "🎯 WHAT DOES THIS SCRIPT DO?"
    print_color $WHITE "Monitor your system's vital signs including CPU/GPU temperatures, storage health,"
    print_color $WHITE "system performance, and resource usage with beautiful real-time dashboards."
    echo

    print_color $YELLOW "💻 COMMAND USAGE:"
    printf "${WHITE}   %-20s${GRAY} - ${WHITE}%s${RESET}\n" "$(basename $0)" "Show full dashboard (default)"
    printf "${WHITE}   %-20s${GRAY} - ${WHITE}%s${RESET}\n" "$(basename $0) watch" "Auto-refresh dashboard every 3 seconds 👁️"
    printf "${WHITE}   %-20s${GRAY} - ${WHITE}%s${RESET}\n" "$(basename $0) temp" "Show only temperature monitoring 🌡️"
    printf "${WHITE}   %-20s${GRAY} - ${WHITE}%s${RESET}\n" "$(basename $0) perf" "Show only performance metrics 📊"
    printf "${WHITE}   %-20s${GRAY} - ${WHITE}%s${RESET}\n" "$(basename $0) disk" "Show only disk usage 💾"
    printf "${WHITE}   %-20s${GRAY} - ${WHITE}%s${RESET}\n" "$(basename $0) info" "Show only system information 🖥️"
    printf "${WHITE}   %-20s${GRAY} - ${WHITE}%s${RESET}\n" "$(basename $0) check" "Check dependencies and setup 🔍"
    printf "${WHITE}   %-20s${GRAY} - ${WHITE}%s${RESET}\n" "$(basename $0) config" "Edit configuration settings ⚙️"
    printf "${WHITE}   %-20s${GRAY} - ${WHITE}%s${RESET}\n" "$(basename $0) help" "Show this help menu 📚"
    echo

    print_color $YELLOW "🚀 QUICK START:"
    print_color $GREEN "   1. 📥 Save script: cp hw-monitor.sh ~/bin/hw-monitor"
    print_color $GREEN "   2. 🔧 Make executable: chmod +x ~/bin/hw-monitor"
    print_color $GREEN "   3. 🔍 Check setup: hw-monitor check"
    print_color $GREEN "   4. 📊 View dashboard: hw-monitor"
    print_color $GREEN "   5. 👁️  Watch mode: hw-monitor watch"
    echo

    print_color $YELLOW "🔧 MONITORING FEATURES:"
    print_color $GREEN "   🌡️  Temperature Monitoring:"
    print_color $GRAY "     • CPU core temperatures"
    print_color $GRAY "     • NVIDIA GPU temperatures"
    print_color $GRAY "     • NVMe SSD temperatures"
    print_color $GRAY "     • Automatic threshold warnings"
    echo
    print_color $GREEN "   📊 Performance Metrics:"
    print_color $GRAY "     • Real-time CPU usage with progress bars"
    print_color $GRAY "     • Memory usage and availability"
    print_color $GRAY "     • GPU utilization (NVIDIA)"
    print_color $GRAY "     • System load averages"
    echo
    print_color $GREEN "   💾 Storage Health:"
    print_color $GRAY "     • Disk usage for all mounted drives"
    print_color $GRAY "     • Visual progress indicators"
    print_color $GRAY "     • Space warnings and alerts"
    echo

    print_color $YELLOW "⚙️  CUSTOMIZATION:"
    print_color $WHITE "Edit the configuration section to customize warning thresholds:"
    print_color $GRAY "   • CPU_TEMP_WARNING/CRITICAL (default: 70°C/85°C)"
    print_color $GRAY "   • GPU_TEMP_WARNING/CRITICAL (default: 75°C/90°C)"
    print_color $GRAY "   • NVME_TEMP_WARNING/CRITICAL (default: 60°C/80°C)"
    print_color $GRAY "   • CPU_LOAD_WARNING (default: 80%)"
    print_color $GRAY "   • MEMORY_WARNING (default: 85%)"
    echo

    print_color $YELLOW "🔧 REQUIREMENTS:"
    print_color $WHITE "   • 🐧 Arch Linux (or compatible distribution)"
    print_color $WHITE "   • 🧮 bc calculator: sudo pacman -S bc"
    print_color $WHITE "   • 🌡️  lm-sensors (recommended): sudo pacman -S lm-sensors"
    print_color $WHITE "   • 🎮 NVIDIA drivers (if you have NVIDIA GPU)"
    print_color $WHITE "   • 💾 nvme-cli (for NVMe monitoring): sudo pacman -S nvme-cli"
    echo

    print_color $YELLOW "💡 PRO TIPS:"
    print_color $MAGENTA "   🔄 Use watch mode for continuous monitoring during stress tests"
    print_color $MAGENTA "   🌡️  Check temps before and after cleaning your PC"
    print_color $MAGENTA "   📊 Monitor performance while gaming or rendering"
    print_color $MAGENTA "   💾 Keep an eye on disk usage to prevent system slowdowns"
    print_color $MAGENTA "   ⚙️  Customize thresholds based on your hardware specifications"
    echo

    print_color $CYAN "📜 Created with ❤️  by Luna AI Assistant"
    print_color $GRAY "Keep your hardware happy and healthy! 🖥️✨"
    print_color $GRAY "────────────────────────────────────────────────────────────────────────────────"
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🎮 MAIN PROGRAM LOGIC
# ═══════════════════════════════════════════════════════════════════════════════

# Main function dispatcher
main() {
    local command="${1:-dashboard}"

    case "$command" in
        dashboard|"")
            show_dashboard
            ;;
        watch|w)
            watch_mode
            ;;
        temp|temperature|t)
            print_header "Temperature Monitor" "🌡️"
            show_temperatures
            ;;
        perf|performance|p)
            print_header "Performance Monitor" "📊"
            show_performance
            ;;
        disk|storage|d)
            print_header "Storage Monitor" "💾"
            show_disk_usage
            ;;
        info|system|i)
            print_header "System Information" "🖥️"
            show_system_info
            ;;
        check|dependencies|deps)
            check_dependencies
            ;;
        config|configure|edit)
            print_header "Configuration Editor" "⚙️"
            print_color $BLUE "🔧 Opening script for editing..."
            print_color $YELLOW "💡 Edit the configuration section at the top of the file"
            print_color $WHITE "   Variables you can customize:"
            print_color $GRAY "   • CPU_TEMP_WARNING (currently: ${CPU_TEMP_WARNING}°C)"
            print_color $GRAY "   • CPU_TEMP_CRITICAL (currently: ${CPU_TEMP_CRITICAL}°C)"
            print_color $GRAY "   • GPU_TEMP_WARNING (currently: ${GPU_TEMP_WARNING}°C)"
            print_color $GRAY "   • GPU_TEMP_CRITICAL (currently: ${GPU_TEMP_CRITICAL}°C)"
            print_color $GRAY "   • AUTO_REFRESH (currently: $AUTO_REFRESH)"
            echo

            if command -v nano >/dev/null 2>&1; then
                nano "$0"
            elif command -v vim >/dev/null 2>&1; then
                vim "$0"
            elif command -v code >/dev/null 2>&1; then
                code "$0"
            else
                print_color $YELLOW "⚠️  No text editor found. Edit manually: $0"
            fi
            ;;
        help|--help|-h|h)
            show_help
            ;;
        version|--version|-v)
            print_header "Hardware Monitor v1.0" "🖥️"
            print_color $WHITE "Real-time System Health Dashboard"
            print_color $GRAY "Created by Luna AI Assistant with ❤️"
            print_color $CYAN "Features: Temperature monitoring, Performance metrics, Storage health"
            print_color $GRAY "────────────────────────────────────────────────────────────────────────────────"
            ;;
        stress-test|stress)
            print_header "Stress Test Monitor" "🔥"
            print_color $YELLOW "🚨 Starting stress test monitoring mode..."
            print_color $WHITE "This will show continuous monitoring optimized for stress testing."
            print_color $GRAY "Start your stress test (like stress, prime95, furmark) and watch temps!"
            echo
            print_color $RED "⚠️  WARNING: Monitor temperatures carefully during stress testing!"
            print_color $RED "   Stop stress test immediately if temperatures exceed safe limits."
            echo
            print_color $BLUE "Press Enter to start monitoring, Ctrl+C to exit..."
            read -r

            while true; do
                clear
                print_color $RED "🔥 STRESS TEST MONITORING - $(date '+%H:%M:%S')"
                print_color $YELLOW "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                echo

                # Show critical temps prominently
                local cpu_temp=$(get_cpu_temperature)
                local gpu_temp=$(get_gpu_temperature)
                local cpu_data=$(get_cpu_usage)
            local cpu_usage=$(echo "$cpu_data" | cut -d',' -f1)
                local gpu_usage=$(get_gpu_usage)

                if [[ "$cpu_temp" != "N/A" ]]; then
                    if (( $(echo "$cpu_temp >= $CPU_TEMP_CRITICAL" | bc -l) )); then
                        print_color $RED "🚨 CPU: ${cpu_temp}°C - CRITICAL! STOP TEST NOW!"
                    elif (( $(echo "$cpu_temp >= $CPU_TEMP_WARNING" | bc -l) )); then
                        print_color $YELLOW "⚠️  CPU: ${cpu_temp}°C - High temperature!"
                    else
                        print_color $GREEN "✅ CPU: ${cpu_temp}°C - Safe"
                    fi
                fi

                if [[ "$gpu_temp" != "N/A" ]]; then
                    if (( $(echo "$gpu_temp >= $GPU_TEMP_CRITICAL" | bc -l) )); then
                        print_color $RED "🚨 GPU: ${gpu_temp}°C - CRITICAL! STOP TEST NOW!"
                    elif (( $(echo "$gpu_temp >= $GPU_TEMP_WARNING" | bc -l) )); then
                        print_color $YELLOW "⚠️  GPU: ${gpu_temp}°C - High temperature!"
                    else
                        print_color $GREEN "✅ GPU: ${gpu_temp}°C - Safe"
                    fi
                fi

                echo
                print_color $CYAN "📊 Current Load:"
                if [[ "$cpu_usage" != "N/A" ]]; then
                    print_color $WHITE "   CPU Usage: ${cpu_usage}%"
                fi
                if [[ "$gpu_usage" != "N/A" ]]; then
                    print_color $WHITE "   GPU Usage: ${gpu_usage}%"
                fi

                echo
                print_color $GRAY "Press Ctrl+C to exit stress test monitoring..."
                sleep 2
            done
            ;;
        quick|q)
            # Quick one-liner status
            local cpu_temp=$(get_cpu_temperature)
            local gpu_temp=$(get_gpu_temperature)
            local cpu_data=$(get_cpu_usage)
            local cpu_usage=$(echo "$cpu_data" | cut -d',' -f1)
            local mem_data=$(get_memory_usage)
            local mem_usage=$(echo "$mem_data" | cut -d',' -f1)

            printf "🖥️  "
            if [[ "$cpu_temp" != "N/A" ]]; then
                printf "CPU: ${cpu_temp}°C "
            fi
            if [[ "$gpu_temp" != "N/A" ]]; then
                printf "GPU: ${gpu_temp}°C "
            fi
            printf "CPU: ${cpu_usage}%% MEM: ${mem_usage}%%\n"
            ;;
        log|history)
            print_header "System Monitoring Log" "📝"
            print_color $BLUE "🔍 Creating monitoring log entry..."

            local log_file="$HOME/.hw-monitor.log"
            local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
            local cpu_temp=$(get_cpu_temperature)
            local gpu_temp=$(get_gpu_temperature)
            local cpu_usage=$(get_cpu_usage)
            local mem_data=$(get_memory_usage)
            local mem_usage=$(echo "$mem_data" | cut -d',' -f1)

            # Create log entry
            echo "$timestamp,CPU_TEMP:$cpu_temp,GPU_TEMP:$gpu_temp,CPU_USAGE:$cpu_usage,MEM_USAGE:$mem_usage" >> "$log_file"

            print_color $GREEN "✅ Log entry added to: $log_file"
            print_color $WHITE "   Timestamp: $timestamp"
            if [[ "$cpu_temp" != "N/A" ]]; then
                print_color $WHITE "   CPU Temp: ${cpu_temp}°C"
            fi
            if [[ "$gpu_temp" != "N/A" ]]; then
                print_color $WHITE "   GPU Temp: ${gpu_temp}°C"
            fi
            print_color $WHITE "   CPU Usage: ${cpu_usage}%"
            print_color $WHITE "   Memory: ${mem_usage}%"

            echo
            print_color $CYAN "📊 Recent log entries (last 10):"
            if [[ -f "$log_file" ]]; then
                tail -10 "$log_file" | while IFS=',' read -r time cpu_temp gpu_temp cpu_usage mem_usage; do
                    print_color $GRAY "   $time | $cpu_temp | $gpu_temp | $cpu_usage | $mem_usage"
                done
            else
                print_color $GRAY "   No previous log entries found"
            fi

            print_color $GRAY "────────────────────────────────────────────────────────────────────────────────"
            ;;
        *)
            print_color $RED "❌ Unknown command: $command"
            echo
            print_color $YELLOW "🤔 Not sure what you wanted to do?"
            print_color $WHITE "Here are the most common commands:"
            echo
            print_color $CYAN "   • $(basename $0)           ${GRAY}→ Full dashboard"
            print_color $CYAN "   • $(basename $0) watch     ${GRAY}→ Auto-refresh monitoring"
            print_color $CYAN "   • $(basename $0) temp      ${GRAY}→ Temperature only"
            print_color $CYAN "   • $(basename $0) quick     ${GRAY}→ One-line status"
            print_color $CYAN "   • $(basename $0) help      ${GRAY}→ Full documentation"
            echo
            print_color $YELLOW "💡 Use '$(basename $0) help' for complete command list"
            print_color $GRAY "────────────────────────────────────────────────────────────────────────────────"
            exit 1
            ;;
    esac
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🚀 SCRIPT EXECUTION
# ═══════════════════════════════════════════════════════════════════════════════

# Check for required dependencies on startup
check_essential_deps() {
    if ! command -v bc >/dev/null 2>&1; then
        echo "❌ Error: 'bc' calculator not found!"
        echo "💡 Install with: sudo pacman -S bc"
        exit 1
    fi
}

# Signal handlers for graceful exit
cleanup() {
    print_color $CYAN "\n👋 Hardware Monitor exiting gracefully..."
    print_color $GRAY "Stay cool! 🧊"
    exit 0
}

# Set up signal traps
trap cleanup SIGINT SIGTERM

# ═══════════════════════════════════════════════════════════════════════════════
# 🎬 MAIN EXECUTION
# ═══════════════════════════════════════════════════════════════════════════════

# Run essential dependency check and main function
check_essential_deps
main "$@"

# End of Hardware Monitor v1.0 🖥️📊
# Keep your silicon happy! 🔥➡️❄️
