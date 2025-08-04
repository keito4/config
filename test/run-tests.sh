#!/bin/bash

# Test runner for shell script tests
# This script runs all Bats tests and generates a coverage report

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BATS_EXEC="$SCRIPT_DIR/bats-libs/bats-core/bin/bats"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Function to print colored output
print_info() {
    echo -e "${BLUE}$1${NC}"
}

print_success() {
    echo -e "${GREEN}$1${NC}"
}

print_error() {
    echo -e "${RED}$1${NC}"
}

print_warning() {
    echo -e "${YELLOW}$1${NC}"
}

# Check if Bats is installed
if [[ ! -f "$BATS_EXEC" ]]; then
    print_warning "Bats is not installed. Setting up..."
    "$SCRIPT_DIR/setup.sh"
fi

# Parse command line arguments
VERBOSE=false
FILTER=""
TAP_OUTPUT=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -f|--filter)
            FILTER="$2"
            shift 2
            ;;
        --tap)
            TAP_OUTPUT=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  -v, --verbose    Show detailed test output"
            echo "  -f, --filter     Filter tests by pattern"
            echo "  --tap            Output in TAP format"
            echo "  -h, --help       Show this help message"
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Build test file list
TEST_FILES=()
if [[ -n "$FILTER" ]]; then
    print_info "Running tests matching pattern: $FILTER"
    for file in "$SCRIPT_DIR"/*.bats; do
        if [[ -f "$file" ]] && [[ "$file" == *"$FILTER"* ]]; then
            TEST_FILES+=("$file")
        fi
    done
else
    print_info "Running all tests..."
    for file in "$SCRIPT_DIR"/*.bats; do
        if [[ -f "$file" ]]; then
            TEST_FILES+=("$file")
        fi
    done
fi

if [[ ${#TEST_FILES[@]} -eq 0 ]]; then
    print_error "No test files found"
    exit 1
fi

# Prepare Bats options
BATS_OPTIONS=()
if [[ "$VERBOSE" == true ]]; then
    BATS_OPTIONS+=("--verbose-run")
fi
if [[ "$TAP_OUTPUT" == true ]]; then
    BATS_OPTIONS+=("--tap")
else
    BATS_OPTIONS+=("--pretty")
fi

# Clean up any previous mock directories
rm -rf "$SCRIPT_DIR/mocks"

# Run tests
print_info "Found ${#TEST_FILES[@]} test file(s)"
echo ""

# Create a summary
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
SKIPPED_TESTS=0

# Run tests and capture results
TEMP_OUTPUT=$(mktemp)
if "$BATS_EXEC" "${BATS_OPTIONS[@]}" "${TEST_FILES[@]}" > "$TEMP_OUTPUT" 2>&1; then
    TEST_RESULT=0
else
    TEST_RESULT=$?
fi

# Display output
cat "$TEMP_OUTPUT"

# Parse results for summary (if not TAP output)
if [[ "$TAP_OUTPUT" == false ]]; then
    # Extract test counts from output
    if grep -q "test" "$TEMP_OUTPUT"; then
        TOTAL_TESTS=$(grep -E "✓|✗|↓" "$TEMP_OUTPUT" | wc -l | tr -d ' ')
        PASSED_TESTS=$(grep -c "✓" "$TEMP_OUTPUT" 2>/dev/null || echo "0")
        FAILED_TESTS=$(grep -c "✗" "$TEMP_OUTPUT" 2>/dev/null || echo "0")
        SKIPPED_TESTS=$(grep -c "↓" "$TEMP_OUTPUT" 2>/dev/null || echo "0")
    fi
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo " TEST SUMMARY"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    if [[ $TEST_RESULT -eq 0 ]]; then
        print_success "✓ All tests passed!"
    else
        print_error "✗ Some tests failed"
    fi
    
    echo ""
    echo "Total:   $TOTAL_TESTS tests"
    print_success "Passed:  $PASSED_TESTS tests"
    
    if [[ $FAILED_TESTS -gt 0 ]]; then
        print_error "Failed:  $FAILED_TESTS tests"
    fi
    
    if [[ "$SKIPPED_TESTS" -gt 0 ]]; then
        print_warning "Skipped: $SKIPPED_TESTS tests"
    fi
    
    # Calculate coverage estimate
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo " COVERAGE ESTIMATE"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    # List shell scripts and their test coverage
    SCRIPT_COUNT=0
    TESTED_COUNT=0
    
    for script in "$SCRIPT_DIR"/../script/*.sh; do
        if [[ -f "$script" ]]; then
            SCRIPT_COUNT=$((SCRIPT_COUNT + 1))
            SCRIPT_NAME=$(basename "$script" .sh)
            TEST_FILE="$SCRIPT_DIR/${SCRIPT_NAME}.bats"
            
            if [[ -f "$TEST_FILE" ]]; then
                TESTED_COUNT=$((TESTED_COUNT + 1))
                TEST_COUNT=$(grep -c "^@test" "$TEST_FILE" 2>/dev/null || echo "0")
                print_success "✓ ${SCRIPT_NAME}.sh - $TEST_COUNT tests"
            else
                print_error "✗ ${SCRIPT_NAME}.sh - no tests"
            fi
        fi
    done
    
    echo ""
    if [[ $SCRIPT_COUNT -gt 0 ]]; then
        COVERAGE_PERCENT=$((TESTED_COUNT * 100 / SCRIPT_COUNT))
    else
        COVERAGE_PERCENT=0
    fi
    echo "Scripts tested: $TESTED_COUNT/$SCRIPT_COUNT ($COVERAGE_PERCENT%)"
    
    if [[ $COVERAGE_PERCENT -lt 70 ]]; then
        print_warning "⚠ Coverage is below 70% threshold"
    else
        print_success "✓ Coverage meets 70% threshold"
    fi
fi

# Clean up
rm -f "$TEMP_OUTPUT"
rm -rf "$SCRIPT_DIR/mocks"

exit $TEST_RESULT