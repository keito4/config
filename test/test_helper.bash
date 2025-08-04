#!/bin/bash

# Load bats helper libraries
export TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export REPO_ROOT="$(cd "$TEST_DIR/.." && pwd)"
export SCRIPT_DIR="$REPO_ROOT/script"
export FIXTURES_DIR="$TEST_DIR/fixtures"

# Load bats helper libraries
load "$TEST_DIR/bats-libs/bats-support/load"
load "$TEST_DIR/bats-libs/bats-assert/load"
load "$TEST_DIR/bats-libs/bats-file/load"

# Create temporary test directory
setup() {
    export TEST_TEMP_DIR="$(mktemp -d)"
    export ORIGINAL_PATH="$PATH"
    export PATH="$TEST_DIR/mocks:$PATH"
}

# Clean up temporary test directory
teardown() {
    if [[ -d "$TEST_TEMP_DIR" ]]; then
        rm -rf "$TEST_TEMP_DIR"
    fi
    export PATH="$ORIGINAL_PATH"
}

# Helper function to create mock commands
create_mock() {
    local cmd_name="$1"
    local mock_content="$2"
    local mock_file="$TEST_DIR/mocks/$cmd_name"
    
    mkdir -p "$TEST_DIR/mocks"
    cat > "$mock_file" << EOF
#!/bin/bash
$mock_content
EOF
    chmod +x "$mock_file"
}

# Helper function to remove mock commands
remove_mock() {
    local cmd_name="$1"
    rm -f "$TEST_DIR/mocks/$cmd_name"
}

# Helper function to assert output contains text
assert_contains() {
    local output="$1"
    local expected="$2"
    if [[ "$output" != *"$expected"* ]]; then
        echo "Expected output to contain: $expected"
        echo "Actual output: $output"
        return 1
    fi
}

# Helper function to assert output does not contain text
assert_not_contains() {
    local output="$1"
    local unexpected="$2"
    if [[ "$output" == *"$unexpected"* ]]; then
        echo "Expected output NOT to contain: $unexpected"
        echo "Actual output: $output"
        return 1
    fi
}

# Helper function to create test fixtures
create_fixture() {
    local fixture_name="$1"
    local content="$2"
    
    mkdir -p "$FIXTURES_DIR"
    echo "$content" > "$FIXTURES_DIR/$fixture_name"
}