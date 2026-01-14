#!/bin/bash
# Wrapper script to run dbt commands with environment variables from root .env

# Load environment variables from root .env file (handles special characters)
while IFS= read -r line || [ -n "$line" ]; do
  # Skip comments and empty lines
  if [[ ! "$line" =~ ^#.* ]] && [[ -n "$line" ]]; then
    export "$line"
  fi
done < ../.env

# Activate virtual environment
source venv/bin/activate

# Run dbt with all passed arguments
dbt "$@"
