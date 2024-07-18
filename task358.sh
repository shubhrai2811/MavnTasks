#!/bin/bash

# Directory containing the shell scripts
DIR_SCRIPT="/media/prolevelnoob/Shubh/CodePlayground/mavn"  # Change this to your scripts directory
OUTPUT_DIR="/media/prolevelnoob/Shubh/CodePlayground/mavn/documented"  # Directory to store the generated documentation

# Create the output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Function to extract function definitions and comments
extract_functions() {
    local script="$1"
    local file_out="$2"
    
    local inside_function=0
    local function_name=""
    local function_comment=""
    local line

    while IFS= read -r line || [[ -n "$line" ]]; do
        # Check if the line is a comment
        if [[ "$line" =~ ^[[:space:]]*#[[:space:]]*(.*) ]]; then
            function_comment+="${BASH_REMATCH[1]}\n"
        fi

        # Check if the line is a function definition
        if [[ "$line" =~ ^[[:space:]]*([a-zA-Z_][a-zA-Z_0-9]*)[[:space:]]*\(\)[[:space:]]*\{ ]]; then
            function_name="${BASH_REMATCH[1]}"
            inside_function=1
        fi

        # If inside a function, write the documentation
        if [[ $inside_function -eq 1 && "$line" == "}" ]]; then
            inside_function=0
            {
                echo "## ${function_name}"
                echo -e "$function_comment"
                echo "```bash"
                echo "function ${function_name} { ... }"
                echo "```"
                echo ""
            } >> "$file_out"
            function_name=""
            function_comment=""
        fi
    done < "$script"
}

# Function to identify undocumented functions
identify_undocumented_functions() {
    local script="$1"
    local file_out="$2"
    
    local inside_function=0
    local function_name=""
    local function_comment=""
    local line

    while IFS= read -r line || [[ -n "$line" ]]; do
        # Check if the line is a function definition
        if [[ "$line" =~ ^[[:space:]]*([a-zA-Z_][a-zA-Z_0-9]*)[[:space:]]*\(\)[[:space:]]*\{ ]]; then
            function_name="${BASH_REMATCH[1]}"
            inside_function=1
            function_comment=""
        fi

        # Collect comments inside the function
        if [[ $inside_function -eq 1 && "$line" =~ ^[[:space:]]*#[[:space:]]*(.*) ]]; then
            function_comment+="${BASH_REMATCH[1]}\n"
        fi

        # If inside a function and no comment, write to undocumented list
        if [[ $inside_function -eq 1 && "$line" == "}" ]]; then
            if [[ -z "$function_comment" ]]; then
                echo "$function_name" >> "$file_out"
            fi
            inside_function=0
            function_name=""
            function_comment=""
        fi
    done < "$script"
}

# Error handling function
error_exit() {
    echo "Error: $1"
    exit 1
}

# Check if DIR_SCRIPT exists and is readable
[ -d "$DIR_SCRIPT" ] || error_exit "Directory: $DIR_SCRIPT was Not Found"
[ -r "$DIR_SCRIPT" ] || error_exit "No read permission $DIR_SCRIPT."

# Main script
for script in "$DIR_SCRIPT"/*.sh; do
    if [ -r "$script" ]; then
        file_out="$OUTPUT_DIR/$(basename "$script" .sh)_manual.md"
        undocumented_file="$OUTPUT_DIR/$(basename "$script" .sh)_undocumented.txt"

        echo "# Manual for $(basename "$script")" > "$file_out"
        extract_functions "$script" "$file_out"
        
        echo "# Undocumented functions in $(basename "$script")" > "$undocumented_file"
        identify_undocumented_functions "$script" "$undocumented_file"
    else
        echo "Skipping $script: No read permission."
    fi
done

echo "Documentation generated in $OUTPUT_DIR"
