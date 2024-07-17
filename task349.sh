#!/bin/bash

# Define a function to analyze script
analyze_script() {
    local script="$1"
    local report="$2"

    echo "Analyzing $script" >> "$report"
    echo "-----------------------------------" >> "$report"

    # Check for long functions
    echo "Checking for long functions..." >> "$report"
    awk '/^\s*function\s+[a-zA-Z0-9_]+\s*\(\)\s*\{/,/^\s*\}/' "$script" | \
    awk '{ if(NR==1) name=$0; } /^\s*\}/ { if(length(name)) { print name; name=""; }}' | \
    while read -r function; do
        if [ "$(echo "$function" | wc -l)" -gt 20 ]; then
            echo "Long function detected: $function" >> "$report"
        fi
    done

    # Check for undefined variables
    echo "Checking for undefined variables..." >> "$report"
    grep -P '(\$\{?[a-zA-Z_][a-zA-Z0-9_]*\}?)' "$script" | \
    grep -Pv '(\$\{?[a-zA-Z_][a-zA-Z0-9_]*\}?=.*)' | \
    grep -Pv '(\$\{?[a-zA-Z_][a-zA-Z0-9_]*\}?[-:+?]?)' >> "$report"

    # Check for repeated code blocks
    echo "Checking for repeated code blocks..." >> "$report"
    awk '{
        if (length($0) > 0) {
            if (block[$0]) {
                print "Repeated code block: " $0;
            } else {
                block[$0] = 1;
            }
        }
    }' "$script" >> "$report"

    echo "-----------------------------------" >> "$report"
}

# Main function
main() {
    local report="build_report.txt"
    > "$report"

    for script in "$@"; do
        analyze_script "$script" "$report"
    done

    echo "Analysis complete. Report generated at $report"
}

main "$@"
