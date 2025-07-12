#!/bin/bash
# Setup script for Sequential Thinking MCP Server

echo "Setting up Sequential Thinking MCP Server for PowerReview..."

# Make the Python script executable
chmod +x main.py

# Install Python dependencies (if needed)
if command -v pip &> /dev/null; then
    echo "Installing Python dependencies..."
    pip install -r requirements.txt
fi

echo "Sequential Thinking MCP Server setup complete!"
echo ""
echo "Usage:"
echo "  - The server is configured in mcp.json"
echo "  - It enables parallel execution of PowerReview scripts"
echo "  - Multiple scripts can run simultaneously for faster assessments"
echo ""
echo "Example methods:"
echo "  - execute_parallel: Run multiple scripts at once"
echo "  - run_assessment: Run a complete assessment with optimized parallelism"
echo "  - get_scripts: Get list of scripts for an assessment type"