#! /bin/sh

echo "{\"version\": 1}"
echo "["
echo "[]"

while true; do
    battery_level=$(cat /sys/class/power_supply/*/capacity | head -n 1)
    charging_indicator=""

    if cat /sys/class/power_supply/*/status | grep -q -i "\bcharging"; then
        charging_indicator="*"
    fi

    printf ',[{"name": "battery", "full_text": "%s%s"}]\n' "$battery_level" "$charging_indicator"

    sleep 1
done
        
