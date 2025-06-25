#!/bin/bash
# Blue Light Filter v6.0 - Advanced Eye Care Protection System 👁️‍🗨️
# Gradually reduces harmful blue light from evening to night
# Compatible with GNOME, Redshift, and Gammastep
# 
# Author: Luna AI Assistant 🤖
# License: MIT 📄
# Repository: Your amazing bash collection 🗂️

# ═══════════════════════════════════════════════════════════════════════════════
# 🎛️  CONFIGURATION SECTION
# ═══════════════════════════════════════════════════════════════════════════════

START_HOUR=22          # 🌅 Start reducing blue light at 22:00 (10:00 PM)
END_HOUR=1             # 🌙 Finish reduction at 01:00 (1:00 AM next day)
MORNING_HOUR=6         # 🌅 Return to normal colors at 06:00 (6:00 AM)
START_TEMP=6500        # ☀️ Normal daylight temperature in Kelvin (cool white)
END_TEMP=1800          # 🔥 Warm night temperature in Kelvin (very warm)
NORMAL_TEMP=6500       # 🌞 Default temperature during day hours
ADAPTIVE_START=true    # 🎯 Start from current temperature instead of START_TEMP

# ═══════════════════════════════════════════════════════════════════════════════
# 🎨 COLOR PALETTE FOR BEAUTIFUL OUTPUT
# ═══════════════════════════════════════════════════════════════════════════════

RED='\033[0;31m'       # 🔴 Error messages and warnings
GREEN='\033[0;32m'     # 🟢 Success messages and confirmations
YELLOW='\033[1;33m'    # 🟡 Important information and tips
BLUE='\033[0;34m'      # 🔵 General information and details
MAGENTA='\033[0;35m'   # 🟣 Special highlights and features
CYAN='\033[0;36m'      # 🔷 Headers and section titles
WHITE='\033[1;37m'     # ⚪ Emphasized text and values
GRAY='\033[0;37m'      # ⚫ Secondary information
RESET='\033[0m'        # 🏁 Reset to default color

# ═══════════════════════════════════════════════════════════════════════════════
# 🎭 UTILITY FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════════════

# Print colored text with emoji support
print_color() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${RESET}"
}

# Print a fancy header with borders
print_header() {
    local title="$1"
    local emoji="$2"
    echo
    print_color $CYAN "╔═══════════════════════════════════════════════════════════════════════════════╗"
    printf "${CYAN}║${RESET} ${emoji} ${WHITE}%-70s${CYAN} ║${RESET}\n" "$title"
    print_color $CYAN "╚═══════════════════════════════════════════════════════════════════════════════╝"
    echo
}

# Print a fancy separator
print_separator() {
    print_color $GRAY "────────────────────────────────────────────────────────────────────────────────"
}

# Get current color temperature from system
get_current_temperature() {
    local current_temp=$NORMAL_TEMP  # Default fallback
    
    # Try to get current temperature from GNOME
    if command -v gsettings >/dev/null 2>&1; then
        if [[ "$XDG_CURRENT_DESKTOP" == *"GNOME"* ]]; then
            local gnome_temp=$(gsettings get org.gnome.settings-daemon.plugins.color night-light-temperature 2>/dev/null)
            if [[ "$gnome_temp" =~ ^[0-9]+$ ]]; then
                current_temp=$gnome_temp
            fi
        elif [[ "$XDG_CURRENT_DESKTOP" == *"Cinnamon"* ]] || [[ "$XDG_CURRENT_DESKTOP" == *"X-Cinnamon"* ]]; then
            if command -v dconf >/dev/null 2>&1; then
                local cinnamon_temp=$(dconf read /org/cinnamon/settings-daemon/plugins/color/night-light-temperature 2>/dev/null)
                if [[ "$cinnamon_temp" =~ ^uint32[[:space:]]+([0-9]+)$ ]]; then
                    current_temp=${BASH_REMATCH[1]}
                fi
            fi
        fi
    fi
    
    # Ensure temperature is within reasonable bounds
    if (( $(echo "$current_temp < 1000" | bc -l) )) || (( $(echo "$current_temp > 10000" | bc -l) )); then
        current_temp=$NORMAL_TEMP
    fi
    
    echo $current_temp
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🔧 CORE TEMPERATURE CONTROL FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════════════

# Set color temperature using available system tools
set_color_temp() {
    local temp=$1
    local method_used=""
    
    print_color $BLUE "🎯 Setting color temperature to ${temp}K..."
    
    # Calculate RGB values from color temperature (simplified conversion)
    local red=1.0
    local green=1.0
    local blue=1.0
    
    if (( $(echo "$temp < 6600" | bc -l) )); then
        # Calculate blue reduction for warmer appearance
        blue=$(echo "scale=3; $temp / 6500" | bc)
        if (( $(echo "$blue < 0.4" | bc -l) )); then
            blue=0.4  # Prevent too much blue reduction
        fi
        
        # Slight green reduction for more natural warm look
        if (( $(echo "$temp < 5000" | bc -l) )); then
            green=$(echo "scale=3; 0.8 + ($temp - 2700) * 0.2 / (5000 - 2700)" | bc)
        fi
    fi
    
    # Try GNOME settings first (most common on modern Linux)
    if command -v gsettings >/dev/null 2>&1; then
        # Check if we're in GNOME
        if [[ "$XDG_CURRENT_DESKTOP" == *"GNOME"* ]]; then
            gsettings set org.gnome.settings-daemon.plugins.color night-light-enabled true 2>/dev/null
            gsettings set org.gnome.settings-daemon.plugins.color night-light-temperature $temp 2>/dev/null
            method_used="GNOME Night Light"
        # Check if we're in Cinnamon
        elif [[ "$XDG_CURRENT_DESKTOP" == *"Cinnamon"* ]] || [[ "$XDG_CURRENT_DESKTOP" == *"X-Cinnamon"* ]]; then
            # Cinnamon uses different dconf paths
            if command -v dconf >/dev/null 2>&1; then
                dconf write /org/cinnamon/settings-daemon/plugins/color/night-light-enabled true 2>/dev/null
                dconf write /org/cinnamon/settings-daemon/plugins/color/night-light-temperature "uint32 $temp" 2>/dev/null
                method_used="Cinnamon Night Light"
            fi
        else
            # Try GNOME anyway (might work on some setups)
            gsettings set org.gnome.settings-daemon.plugins.color night-light-enabled true 2>/dev/null
            gsettings set org.gnome.settings-daemon.plugins.color night-light-temperature $temp 2>/dev/null
            method_used="GNOME Night Light"
        fi
    fi
    
    # Try Redshift (popular independent tool)
    if command -v redshift >/dev/null 2>&1; then
        redshift -O $temp >/dev/null 2>&1
        method_used="${method_used:+$method_used + }Redshift"
    fi
    
    # Try Gammastep (Wayland-compatible Redshift fork)
    if command -v gammastep >/dev/null 2>&1; then
        gammastep -O $temp >/dev/null 2>&1
        method_used="${method_used:+$method_used + }Gammastep"
    fi
    
    if [[ -n "$method_used" ]]; then
        print_status "success" "Applied ${temp}K using: $method_used"
    else
        print_status "error" "No supported color temperature tool found!"
        print_status "tip" "Install one of: gnome-settings-daemon, redshift, or gammastep"
    fi
}

# Print status indicator
print_status() {
    local status=$1
    local message=$2
    case $status in
        "success") print_color $GREEN "✅ $message" ;;
        "error")   print_color $RED "❌ $message" ;;
        "warning") print_color $YELLOW "⚠️  $message" ;;
        "info")    print_color $BLUE "ℹ️  $message" ;;
        "tip")     print_color $MAGENTA "💡 $message" ;;
    esac
}

# Calculate appropriate temperature based on current time
calculate_temperature() {
    local current_decimal=$1
    local start_decimal=$START_HOUR
    local end_decimal=$END_HOUR
    local morning_decimal=$MORNING_HOUR
    
    # Determine the starting temperature
    local effective_start_temp=$START_TEMP
    if [[ "$ADAPTIVE_START" == "true" ]]; then
        # Get current temperature from system when filter period begins
        local current_time_hour=$(echo "$current_decimal" | cut -d. -f1)
        
        # If we're at the start of filter period, use current system temperature
        if (( $(echo "$current_decimal >= $start_decimal - 0.1 && $current_decimal <= $start_decimal + 0.1" | bc -l) )); then
            effective_start_temp=$(get_current_temperature)
            print_color $BLUE "🎯 Adaptive start: Beginning from current ${effective_start_temp}K"
        else
            # During filter period, calculate what the start temp should have been
            # This maintains smooth progression even if script starts mid-period
            effective_start_temp=$START_TEMP
        fi
    fi
    
    # Enhanced logic for night period with three phases:
    # Phase 1: START_HOUR to END_HOUR (filtering down)
    # Phase 2: END_HOUR to MORNING_HOUR (stay at minimum)
    # Phase 3: MORNING_HOUR onwards (normal daylight)
    
    # Handle midnight crossing scenarios
    if (( $(echo "$current_decimal >= $start_decimal" | bc -l) )); then
        # Evening: 22:00-23:59
        if (( $(echo "$current_decimal <= $end_decimal + 24" | bc -l) )); then
            # Phase 1: Active filtering (22:00 to 01:00)
            local progress=$(echo "scale=3; ($current_decimal - $start_decimal) / (24 - $start_decimal + $end_decimal)" | bc)
        else
            # Should not happen in this branch
            print_color $GRAY "   • ADAPTIVE_START (currently: $ADAPTIVE_START)"
            echo $NORMAL_TEMP
            return
        fi
    elif (( $(echo "$current_decimal <= $end_decimal" | bc -l) )); then
        # Early morning: 00:00-01:00 (still filtering)
        local progress=$(echo "scale=3; (24 - $start_decimal + $current_decimal) / (24 - $start_decimal + $end_decimal)" | bc)
    elif (( $(echo "$current_decimal > $end_decimal && $current_decimal < $morning_decimal" | bc -l) )); then
        # Phase 2: Deep night (01:00-06:00) - stay at minimum temperature
        echo $END_TEMP
        return
    else
        # Phase 3: Day time (06:00-22:00) - normal daylight
        echo $NORMAL_TEMP
        return
    fi
    
    # Ensure progress is between 0 and 1
    if (( $(echo "$progress > 1" | bc -l) )); then
        progress=1
    elif (( $(echo "$progress < 0" | bc -l) )); then
        progress=0
    fi
    
    # Calculate temperature using smooth cosine curve for natural transition
    local smooth_progress=$(echo "scale=3; (1 - c(3.14159 * $progress)) / 2" | bc -l)
    local temp_diff=$(echo "$effective_start_temp - $END_TEMP" | bc)
    local calculated_temp=$(echo "scale=0; $effective_start_temp - $temp_diff * $smooth_progress" | bc)
    
    # Ensure we return an integer temperature value
    calculated_temp=${calculated_temp%.*}
    echo $calculated_temp
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🌅 MAIN OPERATION FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════════════

# Reset color temperature to normal daylight values
reset_filter() {
    print_header "Resetting Blue Light Filter" "🌞"
    
    print_color $BLUE "🔄 Restoring normal daylight temperature (${NORMAL_TEMP}K)..."
    set_color_temp $NORMAL_TEMP
    
    # Disable night light in GNOME/Cinnamon
    if command -v gsettings >/dev/null 2>&1; then
        if [[ "$XDG_CURRENT_DESKTOP" == *"GNOME"* ]]; then
            gsettings set org.gnome.settings-daemon.plugins.color night-light-enabled false 2>/dev/null
            print_status "info" "GNOME Night Light disabled"
        elif [[ "$XDG_CURRENT_DESKTOP" == *"Cinnamon"* ]] || [[ "$XDG_CURRENT_DESKTOP" == *"X-Cinnamon"* ]]; then
            if command -v dconf >/dev/null 2>&1; then
                dconf write /org/cinnamon/settings-daemon/plugins/color/night-light-enabled false 2>/dev/null
                print_status "info" "Cinnamon Night Light disabled"
            fi
        else
            gsettings set org.gnome.settings-daemon.plugins.color night-light-enabled false 2>/dev/null
            print_status "info" "Night Light disabled"
        fi
    fi
    
    # Reset Redshift
    if command -v redshift >/dev/null 2>&1; then
        redshift -x >/dev/null 2>&1
        print_status "info" "Redshift reset to neutral"
    fi
    
    # Reset Gammastep
    if command -v gammastep >/dev/null 2>&1; then
        gammastep -x >/dev/null 2>&1
        print_status "info" "Gammastep reset to neutral"
    fi
    
    print_separator
    print_status "success" "Your screen is now back to normal daylight colors! 🌈"
}

# Show comprehensive status information
show_status() {
    # Get current time information
    local current_hour=$(date +%H)
    local current_minute=$(date +%M)
    local current_time_decimal=$(echo "scale=2; $current_hour + $current_minute/60" | bc)
    local current_time=$(date +"%H:%M")
    local current_date=$(date +"%A, %B %d, %Y")
    
    # Calculate current appropriate temperature
    local temp=$(calculate_temperature $current_time_decimal)
    
    print_header "Blue Light Filter Status Dashboard" "📊"
    
    # Time information section
    print_color $CYAN "🕐 TIME INFORMATION:"
    print_color $WHITE "   Current time: $current_time ($current_date)"
    print_color $WHITE "   Filter period: $(printf "%02d:00" $START_HOUR) → $(printf "%02d:00" $END_HOUR) (active filtering)"
    print_color $WHITE "   Night period: $(printf "%02d:00" $END_HOUR) → $(printf "%02d:00" $MORNING_HOUR) (stay warm)"
    print_color $WHITE "   Day period: $(printf "%02d:00" $MORNING_HOUR) → $(printf "%02d:00" $START_HOUR) (normal light)"
    print_color $WHITE "   Temperature range: ${START_TEMP}K (cool) → ${END_TEMP}K (warm)"
    echo
    
    # Current status section
    print_color $CYAN "🎯 CURRENT STATUS:"
    print_color $WHITE "   Target temperature: ${temp}K"
    
    if (( $(echo "$temp == $NORMAL_TEMP" | bc -l) )); then
        print_status "info" "Filter is INACTIVE - Normal daylight mode 🌞"
        print_color $GRAY "   Your eyes are exposed to full spectrum light"
        print_color $GRAY "   Perfect for daytime productivity and alertness"
    elif (( $(echo "$temp == $END_TEMP" | bc -l) )); then
        print_status "success" "Filter is at MAXIMUM - Deep night mode 🌙"
        print_color $GRAY "   Maximum blue light filtering active"
        print_color $GRAY "   Perfect for deep sleep preparation"
    else
        local progress_percent=$(echo "scale=1; ($START_TEMP - $temp) * 100 / ($START_TEMP - $END_TEMP)" | bc)
        print_status "success" "Filter is ACTIVE - ${progress_percent}% towards night mode 🌙"
        
        # Visual progress bar
        local bar_length=30
        local filled_length=$(echo "scale=0; $bar_length * $progress_percent / 100" | bc)
        filled_length=${filled_length%.*}
        
        local bar=""
        for ((i=1; i<=bar_length; i++)); do
            if [ $i -le $filled_length ]; then
                bar="${bar}█"
            else
                bar="${bar}░"
            fi
        done
        
        print_color $WHITE "   Progress: [$bar] ${progress_percent}%"
        print_color $GRAY "   Blue light is being filtered for better sleep"
    fi
    echo
    
    # Health benefits section
    print_color $CYAN "🏥 HEALTH BENEFITS:"
    if (( $(echo "$temp < $NORMAL_TEMP" | bc -l) )); then
        print_color $GREEN "   ✅ Reduced blue light exposure"
        print_color $GREEN "   ✅ Improved melatonin production"
        print_color $GREEN "   ✅ Better sleep quality preparation"
        print_color $GREEN "   ✅ Reduced eye strain and fatigue"
    else
        print_color $BLUE "   ℹ️  Full spectrum light for alertness"
        print_color $BLUE "   ℹ️  Optimal for reading and work"
        print_color $BLUE "   ℹ️  Natural circadian rhythm support"
    fi
    echo
    
    # System compatibility section
    print_color $CYAN "🔧 SYSTEM COMPATIBILITY:"
    
    local tools_found=0
    if command -v gsettings >/dev/null 2>&1; then
        print_color $GREEN "   ✅ GNOME Night Light (gsettings)"
        tools_found=$((tools_found + 1))
    else
        print_color $GRAY "   ❌ GNOME Night Light (not available)"
    fi
    
    if command -v redshift >/dev/null 2>&1; then
        print_color $GREEN "   ✅ Redshift"
        tools_found=$((tools_found + 1))
    else
        print_color $GRAY "   ❌ Redshift (not installed)"
    fi
    
    if command -v gammastep >/dev/null 2>&1; then
        print_color $GREEN "   ✅ Gammastep"
        tools_found=$((tools_found + 1))
    else
        print_color $GRAY "   ❌ Gammastep (not installed)"
    fi
    
    echo
    if [ $tools_found -eq 0 ]; then
        print_status "error" "No color temperature tools found!"
        print_status "tip" "Install: sudo pacman -S redshift (or gammastep for Wayland)"
    else
        print_status "success" "$tools_found compatible tool(s) detected"
    fi
    
    print_separator
}

# Apply automatic temperature adjustment based on current time
apply_auto_filter() {
    # Get current time as decimal (e.g., 22:30 = 22.5)
    local current_hour=$(date +%H)
    local current_minute=$(date +%M)
    local current_time_decimal=$(echo "scale=2; $current_hour + $current_minute/60" | bc)
    
    # Calculate and apply appropriate temperature
    local temp=$(calculate_temperature $current_time_decimal)
    set_color_temp $temp
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🔧 SYSTEM INTEGRATION FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════════════

# Install systemd timer for automatic operation
install_systemd_timer() {
    local script_path=$(realpath "$0")
    
    print_header "Installing Systemd Timer" "⚙️"
    
    print_color $BLUE "🔧 Setting up automatic blue light filtering..."
    print_color $WHITE "   Script location: $script_path"
    
    # Create systemd user directory
    mkdir -p ~/.config/systemd/user
    
    # Create service file
    cat > ~/.config/systemd/user/blue-light-filter.service << EOF
[Unit]
Description=Blue Light Filter - Automatic Eye Care Protection 👁️‍🗨️
After=graphical-session.target

[Service]
Type=oneshot
ExecStart=$script_path auto
Environment=DISPLAY=:0
Environment=WAYLAND_DISPLAY=wayland-0
EOF

    # Create timer file
    cat > ~/.config/systemd/user/blue-light-filter.timer << EOF
[Unit]
Description=Run blue light filter every 10 minutes ⏰
Requires=blue-light-filter.service

[Timer]
OnCalendar=*:00/10
Persistent=true

[Install]
WantedBy=timers.target
EOF

    # Enable and start the timer
    systemctl --user daemon-reload
    systemctl --user enable blue-light-filter.timer
    systemctl --user start blue-light-filter.timer
    
    print_status "success" "Systemd timer installed and activated!"
    print_color $WHITE "   Service: ~/.config/systemd/user/blue-light-filter.service"
    print_color $WHITE "   Timer: ~/.config/systemd/user/blue-light-filter.timer"
    echo
    
    print_color $CYAN "📅 SCHEDULE:"
    print_color $WHITE "   • Runs every 10 minutes automatically"
    print_color $WHITE "   • Starts filtering at $(printf "%02d:00" $START_HOUR)"
    print_color $WHITE "   • Reaches maximum warmth at $(printf "%02d:00" $END_HOUR)"
    print_color $WHITE "   • Returns to normal during day hours"
    echo
    
    print_status "tip" "Check status with: systemctl --user status blue-light-filter.timer"
    print_separator
}

# Install traditional crontab entry
install_crontab() {
    local script_path=$(realpath "$0")
    
    print_header "Installing Crontab Entry" "⏰"
    
    # Check if crontab is available
    if ! command -v crontab >/dev/null 2>&1; then
        print_status "warning" "Crontab not found! Installing cronie..."
        
        if command -v pacman >/dev/null 2>&1; then
            sudo pacman -S --noconfirm cronie
            sudo systemctl enable cronie
            sudo systemctl start cronie
            print_status "success" "Cronie installed and started"
        else
            print_status "error" "Cannot install crontab automatically"
            print_status "tip" "Install manually: sudo pacman -S cronie"
            return 1
        fi
    fi
    
    local cron_entry="*/10 * * * * $script_path auto >/dev/null 2>&1"
    
    print_color $BLUE "📝 Adding crontab entry..."
    print_color $WHITE "   Entry: $cron_entry"
    
    # Check if entry already exists
    if crontab -l 2>/dev/null | grep -q "$script_path"; then
        print_status "warning" "Crontab entry already exists!"
        return 0
    fi
    
    # Add to crontab
    (crontab -l 2>/dev/null; echo "$cron_entry") | crontab -
    
    print_status "success" "Crontab entry added successfully!"
    print_color $WHITE "   Blue light filter will run every 10 minutes"
    print_separator
}

# Remove automatic scheduling
remove_automation() {
    print_header "Removing Automation" "🗑️"
    
    local removed=0
    
    # Remove systemd timer
    if systemctl --user is-enabled blue-light-filter.timer >/dev/null 2>&1; then
        systemctl --user stop blue-light-filter.timer
        systemctl --user disable blue-light-filter.timer
        rm -f ~/.config/systemd/user/blue-light-filter.{service,timer}
        systemctl --user daemon-reload
        print_status "success" "Systemd timer removed"
        removed=1
    fi
    
    # Remove crontab entry
    if crontab -l 2>/dev/null | grep -q "$(realpath "$0")"; then
        crontab -l 2>/dev/null | grep -v "$(realpath "$0")" | crontab -
        print_status "success" "Crontab entry removed"
        removed=1
    fi
    
    if [ $removed -eq 0 ]; then
        print_status "info" "No automation found to remove"
    else
        print_status "success" "Automation successfully removed"
        print_status "tip" "You can still run the filter manually anytime"
    fi
    
    print_separator
}

# ═══════════════════════════════════════════════════════════════════════════════
# 📚 HELP AND DOCUMENTATION
# ═══════════════════════════════════════════════════════════════════════════════

# Show comprehensive help information
show_help() {
    clear
    print_color $CYAN "╔═══════════════════════════════════════════════════════════════════════════════╗"
    print_color $CYAN "║                                                                               ║"
    printf "${CYAN}║${WHITE}                    🌙 BLUE LIGHT FILTER v6.0 🌞                            ${CYAN}║${RESET}\n"
    printf "${CYAN}║${GRAY}                     Advanced Eye Care Protection                             ${CYAN}║${RESET}\n"
    print_color $CYAN "║                                                                               ║"
    print_color $CYAN "╚═══════════════════════════════════════════════════════════════════════════════╝"
    echo
    
    print_color $YELLOW "🎯 WHAT DOES THIS SCRIPT DO?"
    print_color $WHITE "This advanced blue light filter gradually adjusts your screen's color temperature"
    print_color $WHITE "from cool daylight (${START_TEMP}K) to warm candlelight (${END_TEMP}K) during evening hours."
    print_color $WHITE "It helps reduce eye strain and improves sleep quality by filtering harmful blue light."
    echo
    
    print_color $YELLOW "⏰ DEFAULT SCHEDULE:"
    print_color $WHITE "   🌅 $(printf "%02d:00" $START_HOUR) - Filter activation begins"
    print_color $WHITE "   🌙 $(printf "%02d:00" $END_HOUR) - Maximum warmth reached"
    print_color $WHITE "   😴 $(printf "%02d:00" $END_HOUR) - $(printf "%02d:00" $MORNING_HOUR) - Stay at warm temperature"
    print_color $WHITE "   🌞 $(printf "%02d:00" $MORNING_HOUR) - Return to normal daylight colors"
    echo
    
    print_color $YELLOW "💻 COMMAND USAGE:"
    printf "${WHITE}   %-20s${GRAY} - ${WHITE}%s${RESET}\n" "$(basename $0)" "Show this help menu"
    printf "${WHITE}   %-20s${GRAY} - ${WHITE}%s${RESET}\n" "$(basename $0) auto" "Apply filter based on current time ⚡"
    printf "${WHITE}   %-20s${GRAY} - ${WHITE}%s${RESET}\n" "$(basename $0) status" "Show detailed status dashboard 📊"
    printf "${WHITE}   %-20s${GRAY} - ${WHITE}%s${RESET}\n" "$(basename $0) reset" "Reset to normal daylight colors 🌞"
    printf "${WHITE}   %-20s${GRAY} - ${WHITE}%s${RESET}\n" "$(basename $0) install-systemd" "Setup automatic filtering (recommended) ⚙️"
    printf "${WHITE}   %-20s${GRAY} - ${WHITE}%s${RESET}\n" "$(basename $0) install-crontab" "Setup with traditional crontab ⏰"
    printf "${WHITE}   %-20s${GRAY} - ${WHITE}%s${RESET}\n" "$(basename $0) remove" "Remove all automation 🗑️"
    printf "${WHITE}   %-20s${GRAY} - ${WHITE}%s${RESET}\n" "$(basename $0) test" "Test all available tools 🧪"
    echo
    
    print_color $YELLOW "🚀 QUICK START GUIDE:"
    print_color $GREEN "   1. 📥 Save this script to ~/bin/blue-light-filter"
    print_color $GREEN "   2. 🔧 Make it executable: chmod +x ~/bin/blue-light-filter"
    print_color $GREEN "   3. ⚙️  Install automation: blue-light-filter install-systemd"
    print_color $GREEN "   4. 📊 Check status: blue-light-filter status"
    print_color $GREEN "   5. 🎉 Enjoy better sleep and reduced eye strain!"
    echo
    
    print_color $YELLOW "🔧 SYSTEM REQUIREMENTS:"
    print_color $WHITE "   • 🐧 Linux with one of the following:"
    print_color $GRAY "     - GNOME Desktop Environment (built-in support)"
    print_color $GRAY "     - Cinnamon Desktop Environment (built-in support)"
    print_color $GRAY "     - Redshift: sudo pacman -S redshift"
    print_color $GRAY "     - Gammastep: sudo pacman -S gammastep (Wayland)"
    print_color $WHITE "   • 🧮 bc calculator: sudo pacman -S bc"
    echo
    
    print_color $YELLOW "🏥 HEALTH BENEFITS:"
    print_color $GREEN "   ✅ Reduces eye strain and fatigue"
    print_color $GREEN "   ✅ Improves sleep quality by supporting melatonin production"
    print_color $GREEN "   ✅ Maintains natural circadian rhythm"
    print_color $GREEN "   ✅ Prevents headaches from blue light exposure"
    print_color $GREEN "   ✅ Better focus during evening work sessions"
    echo
    
    print_color $YELLOW "⚙️  CUSTOMIZATION:"
    print_color $WHITE "Edit the configuration section at the top of this script to customize:"
    print_color $GRAY "   • START_HOUR: When filtering begins (default: 22)"
    print_color $GRAY "   • END_HOUR: When maximum warmth is reached (default: 1)"
    print_color $GRAY "   • START_TEMP: Daylight temperature in Kelvin (default: 6500K)"
    print_color $GRAY "   • END_TEMP: Warm night temperature in Kelvin (default: 1800K)"
    print_color $GRAY "   • ADAPTIVE_START: Start from current temp (default: true)"
    echo
    
    print_color $YELLOW "🐛 TROUBLESHOOTING:"
    print_color $WHITE "   Problem: Filter not working"
    print_color $GRAY "   → Run: blue-light-filter test"
    print_color $GRAY "   → Install missing tools as suggested"
    echo
    print_color $WHITE "   Problem: Automation not working"
    print_color $GRAY "   → Check: systemctl --user status blue-light-filter.timer"
    print_color $GRAY "   → Or check: crontab -l"
    echo
    print_color $WHITE "   Problem: Screen too warm/cool"
    print_color $GRAY "   → Adjust START_TEMP and END_TEMP in configuration section"
    print_color $GRAY "   → Use values between 1000K (very warm) and 6500K (cool)"
    echo
    
    print_color $YELLOW "💡 PRO TIPS:"
    print_color $MAGENTA "   🎯 Use 'status' command to see beautiful progress visualization"
    print_color $MAGENTA "   🔄 Run 'auto' command manually to test before installing automation"
    print_color $MAGENTA "   🌙 Lower END_TEMP values (1800K-2000K) for stronger night effect"
    print_color $MAGENTA "   ⏰ Adjust timing to match your sleep schedule"
    print_color $MAGENTA "   🖥️  Works great with multiple monitors"
    echo
    
    print_color $CYAN "📜 Created with ❤️  by Luna AI Assistant"
    print_color $GRAY "Version 6.0 - The most advanced blue light filter for Linux!"
    print_separator
}

# Test all available color temperature tools
test_tools() {
    print_header "Testing Color Temperature Tools" "🧪"
    
    print_color $BLUE "🔍 Scanning for available tools..."
    echo
    
    local test_temp=4000
    local tools_working=0
    
    # Test GNOME/Cinnamon gsettings
    print_color $CYAN "🟣 Desktop Environment Night Light:"
    if command -v gsettings >/dev/null 2>&1; then
        if [[ "$XDG_CURRENT_DESKTOP" == *"GNOME"* ]]; then
            if gsettings set org.gnome.settings-daemon.plugins.color night-light-temperature $test_temp 2>/dev/null; then
                print_status "success" "GNOME Night Light working perfectly!"
                gsettings set org.gnome.settings-daemon.plugins.color night-light-enabled true 2>/dev/null
                tools_working=$((tools_working + 1))
            else
                print_status "warning" "GNOME detected but Night Light not responding"
            fi
        elif [[ "$XDG_CURRENT_DESKTOP" == *"Cinnamon"* ]] || [[ "$XDG_CURRENT_DESKTOP" == *"X-Cinnamon"* ]]; then
            if command -v dconf >/dev/null 2>&1; then
                if dconf write /org/cinnamon/settings-daemon/plugins/color/night-light-temperature "uint32 $test_temp" 2>/dev/null; then
                    print_status "success" "Cinnamon Night Light working perfectly!"
                    dconf write /org/cinnamon/settings-daemon/plugins/color/night-light-enabled true 2>/dev/null
                    tools_working=$((tools_working + 1))
                else
                    print_status "warning" "Cinnamon detected but Night Light not responding"
                fi
            else
                print_status "error" "Cinnamon detected but dconf not available"
            fi
        else
            print_status "info" "Desktop: $XDG_CURRENT_DESKTOP (trying generic approach)"
            if gsettings set org.gnome.settings-daemon.plugins.color night-light-temperature $test_temp 2>/dev/null; then
                print_status "success" "Generic Night Light working!"
                tools_working=$((tools_working + 1))
            else
                print_status "warning" "Generic approach failed"
            fi
        fi
    else
        print_status "error" "gsettings not available"
    fi
    echo
    
    # Test Redshift
    print_color $CYAN "🔴 Redshift:"
    if command -v redshift >/dev/null 2>&1; then
        if redshift -O $test_temp >/dev/null 2>&1; then
            print_status "success" "Working perfectly!"
            tools_working=$((tools_working + 1))
        else
            print_status "warning" "Installed but failed to apply (check your display setup)"
        fi
    else
        print_status "info" "Not installed - install with: sudo pacman -S redshift"
    fi
    echo
    
    # Test Gammastep
    print_color $CYAN "🟠 Gammastep (Wayland):"
    if command -v gammastep >/dev/null 2>&1; then
        if gammastep -O $test_temp >/dev/null 2>&1; then
            print_status "success" "Working perfectly!"
            tools_working=$((tools_working + 1))
        else
            print_status "warning" "Installed but failed to apply (check Wayland setup)"
        fi
    else
        print_status "info" "Not installed - install with: sudo pacman -S gammastep"
    fi
    echo
    
    # Test bc calculator
    print_color $CYAN "🧮 BC Calculator:"
    if command -v bc >/dev/null 2>&1; then
        if echo "2+2" | bc >/dev/null 2>&1; then
            print_status "success" "Working perfectly!"
        else
            print_status "error" "Installed but not working properly"
        fi
    else
        print_status "error" "Not installed - install with: sudo pacman -S bc"
    fi
    echo
    
    # Summary
    print_separator
    if [ $tools_working -gt 0 ]; then
        print_status "success" "$tools_working working tool(s) detected - you're all set! 🎉"
        print_color $WHITE "   Your blue light filter is ready to protect your eyes!"
        print_status "tip" "Test temperature applied (${test_temp}K) - reset with: $(basename $0) reset"
    else
        print_status "error" "No working color temperature tools found!"
        print_status "tip" "Install at least one tool to use this filter"
        print_color $YELLOW "   Recommended for beginners: sudo pacman -S redshift"
        print_color $YELLOW "   For GNOME users: Should work out of the box"
        print_color $YELLOW "   For Wayland users: sudo pacman -S gammastep"
    fi
    
    print_separator
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🎮 MAIN PROGRAM LOGIC
# ═══════════════════════════════════════════════════════════════════════════════

# Main script entry point with comprehensive command handling
main() {
    local command="${1:-help}"
    
    case "$command" in
        auto|a)
            # Automatic mode - apply filter based on current time
            apply_auto_filter
            ;;
        status|s|info)
            # Show detailed status dashboard
            show_status
            ;;
        reset|r|normal|day)
            # Reset to normal daylight colors
            reset_filter
            ;;
        install-systemd|systemd|install)
            # Install systemd timer for automatic operation
            install_systemd_timer
            ;;
        install-crontab|crontab)
            # Install traditional crontab entry
            install_crontab
            ;;
        remove|uninstall|stop)
            # Remove all automation
            remove_automation
            ;;
        test|check|diagnostic)
            # Test all available tools
            test_tools
            ;;
        help|--help|-h|h|"")
            # Show comprehensive help
            show_help
            ;;
        version|--version|-v)
            # Show version information
            print_header "Blue Light Filter v6.0" "🌙"
            print_color $WHITE "Advanced Eye Care Protection System"
            print_color $GRAY "Created by Luna AI Assistant with ❤️"
            print_color $CYAN "Features: Smooth transitions, Health benefits, Multi-tool support"
            print_separator
            ;;
        warm|night)
            # Quickly set to warm night mode
            print_color $CYAN "🌙 Setting warm night mode..."
            set_color_temp $END_TEMP
            ;;
        cool|bright)
            # Quickly set to cool day mode
            print_color $CYAN "🌞 Setting cool day mode..."
            set_color_temp $START_TEMP
            ;;
        demo)
            # Demonstration mode - cycle through temperatures
            print_header "Demonstration Mode" "🎭"
            print_color $BLUE "🎯 Cycling through different temperatures..."
            
            local temps=(6500 5000 3500 2700 6500)
            local labels=("Cool Daylight" "Neutral" "Warm" "Very Warm" "Back to Normal")
            
            for i in "${!temps[@]}"; do
                local temp=${temps[$i]}
                local label=${labels[$i]}
                
                print_color $WHITE "   Setting: $label (${temp}K)"
                set_color_temp $temp
                sleep 3
            done
            
            print_status "success" "Demonstration complete!"
            print_separator
            ;;
        config|configure|edit)
            # Open script for configuration editing
            print_header "Configuration Editor" "⚙️"
            print_color $BLUE "🔧 Opening script for editing..."
            print_color $YELLOW "💡 Edit the configuration section at the top of the file"
            print_color $WHITE "   Variables you can customize:"
            print_color $GRAY "   • START_HOUR (currently: $START_HOUR)"
            print_color $GRAY "   • END_HOUR (currently: $END_HOUR)"
            print_color $GRAY "   • START_TEMP (currently: ${START_TEMP}K)"
            print_color $GRAY "   • END_TEMP (currently: ${END_TEMP}K)"
            print_color $GRAY "   • MORNING_HOUR (currently: $MORNING_HOUR)"
            echo
            
            if command -v nano >/dev/null 2>&1; then
                nano "$0"
            elif command -v vim >/dev/null 2>&1; then
                vim "$0"
            elif command -v code >/dev/null 2>&1; then
                code "$0"
            else
                print_status "info" "No text editor found. Edit manually: $0"
            fi
            ;;
        *)
            # Unknown command - show error and help
            print_status "error" "Unknown command: $command"
            echo
            print_color $YELLOW "🤔 Not sure what you wanted to do?"
            print_color $WHITE "Here are the most common commands:"
            echo
            print_color $CYAN "   • $(basename $0) status    ${GRAY}→ See current filter status"
            print_color $CYAN "   • $(basename $0) auto      ${GRAY}→ Apply filter now"
            print_color $CYAN "   • $(basename $0) reset     ${GRAY}→ Turn off filter"
            print_color $CYAN "   • $(basename $0) install   ${GRAY}→ Setup automatic filtering"
            print_color $CYAN "   • $(basename $0) help      ${GRAY}→ Full documentation"
            echo
            print_status "tip" "Use '$(basename $0) help' for complete command list"
            print_separator
            exit 1
            ;;
    esac
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🚀 SCRIPT EXECUTION
# ═══════════════════════════════════════════════════════════════════════════════

# Check for required dependencies
check_dependencies() {
    if ! command -v bc >/dev/null 2>&1; then
        print_status "error" "Required dependency 'bc' not found!"
        print_status "tip" "Install with: sudo pacman -S bc"
        exit 1
    fi
}

# Ensure proper environment
setup_environment() {
    # Ensure we have a display for GUI applications
    if [[ -z "$DISPLAY" && -z "$WAYLAND_DISPLAY" ]]; then
        export DISPLAY=:0
    fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🎬 MAIN EXECUTION
# ═══════════════════════════════════════════════════════════════════════════════

# Script entry point - run dependency checks and main function
check_dependencies
setup_environment
main "$@"

# End of Blue Light Filter v6.0 🌙✨
# Sweet dreams and healthy eyes! 👁️‍🗨️💤
