#! /bin/sh

# print header
echo "{\"version\": 1}"
echo "["

while true; do
    # get battery level
    battery_level=$(cat /sys/class/power_supply/*/capacity | head -n 1)

    # charging indicator prefix
    charging_indicator=""

    if cat /sys/class/power_supply/*/status | grep -q -i "\bcharging"; then
        charging_indicator="*"
    fi

    # header bracket
    printf '['
    
    # body
    printf '{"name": "battery", "full_text": "%s%s", "separator_block_width": 12}' "$battery_level" "$charging_indicator"
    printf ',{"name": "time", "full_text": "%s", "separator_block_width": 12}' "$(date "+%m/%d/%Y %H:%M:%S")"
    
    # trailing bracket
    printf '],\n'

    sleep 1
done
        
