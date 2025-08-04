# issue-batch-process

## 目的

複数のIssueを並列で効率的に処理するバッチ処理コマンド。大規模なリポジトリや多数のIssueを扱う場合に、並列実行により処理時間を短縮する。

## 実行手順

### 1. 並列処理エンジンの初期化

```bash
#!/bin/bash
set -euo pipefail

echo "=== Issue Batch Processing System ==="
echo "Parallel issue resolution with intelligent scheduling"
echo ""

# カラー出力
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# ログ関数
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_debug() { [ "${DEBUG:-false}" = "true" ] && echo -e "${CYAN}[DEBUG]${NC} $1"; }
log_progress() { echo -e "${MAGENTA}[PROGRESS]${NC} $1"; }

# 設定
PARALLEL_JOBS=${PARALLEL_JOBS:-4}
BATCH_SIZE=${BATCH_SIZE:-10}
ISSUE_LABELS=${ISSUE_LABELS:-"auto-detected"}
ISSUE_STATE=${ISSUE_STATE:-"open"}
PRIORITY_ORDER=${PRIORITY_ORDER:-"critical,high,medium,low"}
AGENT_TIMEOUT=${AGENT_TIMEOUT:-600}  # 10分
RETRY_COUNT=${RETRY_COUNT:-2}
SKIP_PR_CREATION=${SKIP_PR_CREATION:-false}
MERGE_STRATEGY=${MERGE_STRATEGY:-"squash"}  # squash, merge, rebase

# 実行統計
START_TIME=$(date +%s)
PROCESSED_COUNT=0
SUCCESS_COUNT=0
FAILED_COUNT=0
SKIPPED_COUNT=0

# プロセスプールの管理
declare -A RUNNING_JOBS
declare -A JOB_RESULTS
MAX_PARALLEL=$PARALLEL_JOBS

# 一時ディレクトリ
WORK_DIR=$(mktemp -d -t issue-batch-XXXXXX)
trap "cleanup_and_report" EXIT

cleanup_and_report() {
    local exit_code=$?
    
    # 実行時間の計算
    END_TIME=$(date +%s)
    DURATION=$((END_TIME - START_TIME))
    
    # 最終レポート生成
    generate_final_report
    
    # クリーンアップ
    rm -rf "$WORK_DIR"
    
    exit $exit_code
}
```

### 2. Issue収集と優先度付け

```bash
log_info "Collecting and prioritizing issues..."

# Issueの取得と分類
collect_and_prioritize_issues() {
    local priority_queue="$WORK_DIR/priority_queue.json"
    
    # すべてのオープンIssueを取得
    gh issue list \
        --state "$ISSUE_STATE" \
        --label "$ISSUE_LABELS" \
        --limit "$BATCH_SIZE" \
        --json number,title,labels,createdAt,body \
        > "$WORK_DIR/all_issues.json"
    
    # 優先度付けスクリプト
    cat << 'EOF' > "$WORK_DIR/prioritize.js"
const fs = require('fs');
const issues = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
const priorityOrder = (process.env.PRIORITY_ORDER || 'critical,high,medium,low').split(',');

// 優先度スコアの計算
function calculatePriority(issue) {
    let score = 1000; // ベーススコア
    
    // ラベルによる優先度
    issue.labels.forEach(label => {
        const name = label.name.toLowerCase();
        if (name.includes('critical') || name.includes('security')) score += 500;
        else if (name.includes('high') || name.includes('bug')) score += 300;
        else if (name.includes('medium') || name.includes('enhancement')) score += 200;
        else if (name.includes('low') || name.includes('documentation')) score += 100;
        
        // カテゴリ別の重み
        if (name.includes('security')) score += 400;
        else if (name.includes('testing')) score += 300;
        else if (name.includes('performance')) score += 250;
        else if (name.includes('dependencies')) score += 150;
    });
    
    // 古いIssueほど優先度を上げる
    const ageInDays = (Date.now() - new Date(issue.createdAt)) / (1000 * 60 * 60 * 24);
    score += Math.min(ageInDays * 10, 200);
    
    // タイトルやボディに特定のキーワードがある場合
    const keywords = ['urgent', 'asap', 'blocker', 'critical', 'security'];
    const text = (issue.title + ' ' + (issue.body || '')).toLowerCase();
    keywords.forEach(keyword => {
        if (text.includes(keyword)) score += 100;
    });
    
    return score;
}

// カテゴリの推定
function estimateCategory(issue) {
    const text = (issue.title + ' ' + (issue.body || '')).toLowerCase();
    const labelNames = issue.labels.map(l => l.name.toLowerCase()).join(' ');
    
    if (text.includes('security') || labelNames.includes('security')) return 'security';
    if (text.includes('test') || labelNames.includes('testing')) return 'testing';
    if (text.includes('doc') || labelNames.includes('documentation')) return 'documentation';
    if (text.includes('depend') || labelNames.includes('dependencies')) return 'dependencies';
    if (text.includes('performance') || labelNames.includes('performance')) return 'performance';
    if (text.includes('ci') || text.includes('cd') || labelNames.includes('ci-cd')) return 'ci-cd';
    if (text.includes('refactor') || labelNames.includes('code-quality')) return 'code-quality';
    
    return 'general';
}

// 処理時間の推定（分）
function estimateProcessingTime(category) {
    const estimates = {
        'security': 15,
        'testing': 20,
        'documentation': 10,
        'dependencies': 8,
        'performance': 12,
        'ci-cd': 10,
        'code-quality': 15,
        'general': 10
    };
    return estimates[category] || 10;
}

// ソートと優先度付け
const prioritized = issues.map(issue => ({
    ...issue,
    priority: calculatePriority(issue),
    category: estimateCategory(issue),
    estimatedTime: estimateProcessingTime(estimateCategory(issue))
})).sort((a, b) => b.priority - a.priority);

// バッチ分割の最適化（処理時間のバランシング）
const batches = [];
const batchCount = parseInt(process.env.PARALLEL_JOBS || 4);

for (let i = 0; i < batchCount; i++) {
    batches.push({ issues: [], totalTime: 0 });
}

prioritized.forEach(issue => {
    // 最も処理時間が少ないバッチに割り当て
    const minBatch = batches.reduce((min, batch) => 
        batch.totalTime < min.totalTime ? batch : min
    );
    minBatch.issues.push(issue);
    minBatch.totalTime += issue.estimatedTime;
});

// 結果の出力
fs.writeFileSync(process.argv[3], JSON.stringify({
    total: issues.length,
    prioritized,
    batches,
    summary: {
        categories: prioritized.reduce((acc, issue) => {
            acc[issue.category] = (acc[issue.category] || 0) + 1;
            return acc;
        }, {}),
        estimatedTotalTime: prioritized.reduce((sum, issue) => sum + issue.estimatedTime, 0),
        averagePriority: prioritized.reduce((sum, issue) => sum + issue.priority, 0) / prioritized.length
    }
}, null, 2));

console.log(`Prioritized ${issues.length} issues into ${batchCount} batches`);
EOF
    
    # 優先度付けの実行
    node "$WORK_DIR/prioritize.js" "$WORK_DIR/all_issues.json" "$priority_queue"
    
    # サマリーの表示
    local total=$(jq -r '.total' "$priority_queue")
    local estimated_time=$(jq -r '.summary.estimatedTotalTime' "$priority_queue")
    
    log_info "Found $total issues to process"
    log_info "Estimated total processing time: ${estimated_time} minutes"
    log_info "Using $PARALLEL_JOBS parallel workers"
    
    # カテゴリ別の表示
    echo -e "\n${CYAN}Category Distribution:${NC}"
    jq -r '.summary.categories | to_entries[] | "  \(.key): \(.value) issues"' "$priority_queue"
    
    return 0
}

collect_and_prioritize_issues
```

### 3. 並列処理エンジン

```bash
# ワーカープロセス
process_issue_worker() {
    local worker_id=$1
    local issue_data=$2
    local log_file="$WORK_DIR/worker_${worker_id}.log"
    
    local issue_number=$(echo "$issue_data" | jq -r '.number')
    local category=$(echo "$issue_data" | jq -r '.category')
    local title=$(echo "$issue_data" | jq -r '.title')
    
    {
        echo "[$(date)] Worker $worker_id: Starting issue #$issue_number"
        
        # エージェントの選択と実行
        local agent_script=".claude/agents/issue-resolver-${category}.md"
        if [ ! -f "$agent_script" ]; then
            agent_script=".claude/agents/issue-resolver-general.md"
        fi
        
        # ブランチ作成
        local branch_name="fix/issue-${issue_number}-batch-${worker_id}"
        git checkout -b "$branch_name" 2>&1
        
        # エージェント実行（タイムアウト付き）
        timeout "$AGENT_TIMEOUT" bash "$agent_script" "$issue_number" 2>&1
        local agent_exit=$?
        
        if [ $agent_exit -eq 0 ]; then
            # 変更をコミット
            if [ -n "$(git status --porcelain)" ]; then
                git add -A
                git commit -m "fix: Resolve issue #$issue_number via batch processing

Category: $category
Worker: $worker_id
Automated by issue-batch-process

Closes #$issue_number" 2>&1
                
                # PR作成（オプション）
                if [ "$SKIP_PR_CREATION" != "true" ]; then
                    git push -u origin "$branch_name" 2>&1
                    
                    gh pr create \
                        --title "🤖 Batch fix: Issue #$issue_number ($category)" \
                        --body "Automated resolution via batch processing" \
                        --label "automated,batch-processed,$category" \
                        --base main \
                        --head "$branch_name" 2>&1
                fi
                
                echo "SUCCESS"
            else
                echo "NO_CHANGES"
            fi
        else
            echo "FAILED"
        fi
        
        # クリーンアップ
        git checkout main 2>&1
        git branch -D "$branch_name" 2>/dev/null || true
        
    } > "$log_file" 2>&1
    
    # 結果を返す
    tail -1 "$log_file"
}

# 並列実行マネージャー
run_parallel_processing() {
    local priority_queue="$WORK_DIR/priority_queue.json"
    local batches=$(jq -r '.batches' "$priority_queue")
    local batch_count=$(echo "$batches" | jq 'length')
    
    log_info "Starting parallel processing with $PARALLEL_JOBS workers..."
    
    # プログレスバーの初期化
    local total_issues=$(jq -r '.total' "$priority_queue")
    local completed=0
    
    show_progress() {
        local current=$1
        local total=$2
        local percent=$((current * 100 / total))
        local bar_length=50
        local filled=$((percent * bar_length / 100))
        
        printf "\r${MAGENTA}[PROGRESS]${NC} ["
        printf "%${filled}s" | tr ' ' '='
        printf "%$((bar_length - filled))s" | tr ' ' '-'
        printf "] %3d%% (%d/%d)" "$percent" "$current" "$total"
    }
    
    # バッチごとの処理
    for batch_idx in $(seq 0 $((batch_count - 1))); do
        local batch_issues=$(echo "$batches" | jq -r ".[$batch_idx].issues")
        local issue_count=$(echo "$batch_issues" | jq 'length')
        
        log_info "Processing batch $((batch_idx + 1))/$batch_count with $issue_count issues"
        
        # 各Issueを並列処理
        local pids=()
        for issue_idx in $(seq 0 $((issue_count - 1))); do
            local issue=$(echo "$batch_issues" | jq ".[$issue_idx]")
            
            # 並列ジョブ数の制限
            while [ ${#pids[@]} -ge $MAX_PARALLEL ]; do
                # 完了したジョブを待つ
                for i in "${!pids[@]}"; do
                    if ! kill -0 "${pids[$i]}" 2>/dev/null; then
                        wait "${pids[$i]}"
                        local exit_code=$?
                        unset pids[$i]
                        ((completed++))
                        show_progress "$completed" "$total_issues"
                        break
                    fi
                done
                sleep 0.5
            done
            
            # 新しいワーカーを起動
            process_issue_worker "$batch_idx-$issue_idx" "$issue" &
            pids+=($!)
        done
        
        # バッチ内のすべてのジョブを待つ
        for pid in "${pids[@]}"; do
            wait "$pid"
            ((completed++))
            show_progress "$completed" "$total_issues"
        done
    done
    
    echo # プログレスバーの後の改行
    log_success "Parallel processing completed"
}

run_parallel_processing
```

### 4. 結果の集約とレポート生成

```bash
generate_final_report() {
    log_info "Generating final report..."
    
    # ログファイルから結果を集計
    local success_count=$(grep -c "SUCCESS" "$WORK_DIR"/worker_*.log 2>/dev/null || echo 0)
    local failed_count=$(grep -c "FAILED" "$WORK_DIR"/worker_*.log 2>/dev/null || echo 0)
    local no_changes_count=$(grep -c "NO_CHANGES" "$WORK_DIR"/worker_*.log 2>/dev/null || echo 0)
    
    # HTMLレポートの生成
    cat << EOF > "$WORK_DIR/report.html"
<!DOCTYPE html>
<html>
<head>
    <title>Issue Batch Processing Report</title>
    <style>
        body { font-family: Arial, sans-serif; max-width: 1200px; margin: 0 auto; padding: 20px; }
        h1 { color: #333; border-bottom: 2px solid #4CAF50; padding-bottom: 10px; }
        .summary { display: flex; gap: 20px; margin: 20px 0; }
        .metric { background: #f5f5f5; padding: 15px; border-radius: 8px; flex: 1; }
        .metric h3 { margin: 0 0 10px 0; color: #666; }
        .metric .value { font-size: 2em; font-weight: bold; }
        .success { color: #4CAF50; }
        .failed { color: #f44336; }
        .warning { color: #FF9800; }
        table { width: 100%; border-collapse: collapse; margin: 20px 0; }
        th, td { padding: 10px; text-align: left; border-bottom: 1px solid #ddd; }
        th { background: #4CAF50; color: white; }
        tr:hover { background: #f5f5f5; }
        .chart { margin: 20px 0; }
        .bar { height: 30px; background: linear-gradient(to right, #4CAF50, #8BC34A); border-radius: 4px; }
    </style>
</head>
<body>
    <h1>🤖 Issue Batch Processing Report</h1>
    
    <div class="summary">
        <div class="metric">
            <h3>Total Processed</h3>
            <div class="value">$((success_count + failed_count + no_changes_count))</div>
        </div>
        <div class="metric">
            <h3>Success</h3>
            <div class="value success">$success_count</div>
        </div>
        <div class="metric">
            <h3>Failed</h3>
            <div class="value failed">$failed_count</div>
        </div>
        <div class="metric">
            <h3>No Changes</h3>
            <div class="value warning">$no_changes_count</div>
        </div>
    </div>
    
    <h2>Execution Details</h2>
    <table>
        <tr>
            <th>Metric</th>
            <th>Value</th>
        </tr>
        <tr>
            <td>Start Time</td>
            <td>$(date -d @$START_TIME)</td>
        </tr>
        <tr>
            <td>End Time</td>
            <td>$(date)</td>
        </tr>
        <tr>
            <td>Duration</td>
            <td>$((DURATION / 60)) minutes $((DURATION % 60)) seconds</td>
        </tr>
        <tr>
            <td>Parallel Workers</td>
            <td>$PARALLEL_JOBS</td>
        </tr>
        <tr>
            <td>Average Time per Issue</td>
            <td>$((DURATION / (success_count + failed_count + no_changes_count + 1))) seconds</td>
        </tr>
    </table>
    
    <h2>Success Rate</h2>
    <div class="chart">
        <div class="bar" style="width: $((success_count * 100 / (success_count + failed_count + no_changes_count + 1)))%;">
            $((success_count * 100 / (success_count + failed_count + no_changes_count + 1)))%
        </div>
    </div>
    
    <h2>Worker Logs</h2>
    <pre>
$(cat "$WORK_DIR"/worker_*.log 2>/dev/null | head -100)
    </pre>
    
    <footer>
        <p>Generated by issue-batch-process at $(date)</p>
    </footer>
</body>
</html>
EOF
    
    # Markdownレポート
    cat << EOF > "$WORK_DIR/report.md"
# Issue Batch Processing Report

## 📊 Summary

- **Total Issues Processed**: $((success_count + failed_count + no_changes_count))
- **Successful**: $success_count
- **Failed**: $failed_count
- **No Changes Needed**: $no_changes_count
- **Success Rate**: $((success_count * 100 / (success_count + failed_count + no_changes_count + 1)))%

## ⏱️ Performance

- **Start Time**: $(date -d @$START_TIME)
- **End Time**: $(date)
- **Total Duration**: $((DURATION / 60)) minutes $((DURATION % 60)) seconds
- **Parallel Workers**: $PARALLEL_JOBS
- **Average Time per Issue**: $((DURATION / (success_count + failed_count + no_changes_count + 1))) seconds

## 📈 Efficiency Metrics

- **Parallelization Efficiency**: $((100 * (success_count + failed_count + no_changes_count) / (PARALLEL_JOBS * DURATION / 60 + 1)))%
- **Throughput**: $(((success_count + failed_count + no_changes_count) * 3600 / DURATION)) issues/hour

## 🔍 Detailed Results

$(for log in "$WORK_DIR"/worker_*.log; do
    echo "### $(basename "$log" .log)"
    tail -20 "$log"
    echo ""
done)

---
*Generated at $(date)*
EOF
    
    # 結果の表示
    echo ""
    echo "════════════════════════════════════════════════════════════════"
    echo "                    BATCH PROCESSING COMPLETE                      "
    echo "════════════════════════════════════════════════════════════════"
    echo ""
    cat "$WORK_DIR/report.md"
    
    # レポートの保存
    local report_dir="$HOME/.claude/reports"
    mkdir -p "$report_dir"
    cp "$WORK_DIR/report.html" "$report_dir/batch_$(date +%Y%m%d_%H%M%S).html"
    cp "$WORK_DIR/report.md" "$report_dir/batch_$(date +%Y%m%d_%H%M%S).md"
    
    log_success "Reports saved to $report_dir"
}
```

### 5. 高度な機能

```bash
# インテリジェントリトライメカニズム
retry_failed_issues() {
    local failed_issues="$WORK_DIR/failed_issues.json"
    
    # 失敗したIssueの収集
    grep -h "FAILED" "$WORK_DIR"/worker_*.log | while read -r line; do
        # Issue番号を抽出してリトライキューに追加
        echo "$line" | grep -oE "#[0-9]+" | tr -d '#'
    done > "$WORK_DIR/retry_queue.txt"
    
    if [ -s "$WORK_DIR/retry_queue.txt" ]; then
        log_info "Retrying $(wc -l < "$WORK_DIR/retry_queue.txt") failed issues..."
        
        # リトライロジック
        while read -r issue_number; do
            log_info "Retrying issue #$issue_number"
            
            # 異なるエージェントまたは戦略でリトライ
            process_issue_with_fallback "$issue_number"
        done < "$WORK_DIR/retry_queue.txt"
    fi
}

# フォールバック処理
process_issue_with_fallback() {
    local issue_number=$1
    
    # 複数の戦略を試す
    local strategies=("aggressive" "conservative" "manual")
    
    for strategy in "${strategies[@]}"; do
        log_debug "Trying $strategy strategy for issue #$issue_number"
        
        case "$strategy" in
            "aggressive")
                # より積極的な変更を試みる
                AGGRESSIVE_MODE=true process_issue_worker "retry" "{\"number\": $issue_number}"
                ;;
            "conservative")
                # 最小限の変更のみ
                CONSERVATIVE_MODE=true process_issue_worker "retry" "{\"number\": $issue_number}"
                ;;
            "manual")
                # 手動介入が必要なIssueとしてマーク
                gh issue comment "$issue_number" --body "🤖 Automated resolution failed. Manual intervention required."
                gh issue edit "$issue_number" --add-label "needs-manual-review"
                ;;
        esac
        
        # 成功したら終了
        if [ $? -eq 0 ]; then
            break
        fi
    done
}

# メイン実行フロー
main() {
    # 前処理
    log_info "Initializing batch processing system..."
    
    # デフォルトの実行
    if [ "$#" -eq 0 ]; then
        collect_and_prioritize_issues
        run_parallel_processing
        retry_failed_issues
    else
        # コマンドライン引数の処理
        case "$1" in
            "--retry")
                retry_failed_issues
                ;;
            "--report")
                generate_final_report
                ;;
            "--help")
                show_help
                ;;
            *)
                log_error "Unknown command: $1"
                show_help
                exit 1
                ;;
        esac
    fi
}

# ヘルプメッセージ
show_help() {
    cat << EOF
Usage: claude code issue-batch-process [OPTIONS]

Options:
    --retry     Retry failed issues from previous run
    --report    Generate report from last run
    --help      Show this help message

Environment Variables:
    PARALLEL_JOBS     Number of parallel workers (default: 4)
    BATCH_SIZE        Maximum issues to process (default: 10)
    ISSUE_LABELS      Labels to filter issues (default: "auto-detected")
    ISSUE_STATE       Issue state to process (default: "open")
    PRIORITY_ORDER    Priority order for processing (default: "critical,high,medium,low")
    AGENT_TIMEOUT     Timeout for each agent in seconds (default: 600)
    RETRY_COUNT       Number of retry attempts (default: 2)
    SKIP_PR_CREATION  Skip PR creation (default: false)
    MERGE_STRATEGY    PR merge strategy (default: "squash")
    DEBUG             Enable debug output (default: false)

Examples:
    # Process 20 issues with 8 parallel workers
    PARALLEL_JOBS=8 BATCH_SIZE=20 claude code issue-batch-process
    
    # Process only critical and high priority issues
    PRIORITY_ORDER="critical,high" claude code issue-batch-process
    
    # Retry failed issues from previous run
    claude code issue-batch-process --retry
    
    # Generate report from last run
    claude code issue-batch-process --report

EOF
}

# エントリーポイント
main "$@"
```

## 成功基準

- ✅ 複数のIssueを並列で処理できる
- ✅ 優先度に基づいた intelligent scheduling
- ✅ 失敗したIssueの自動リトライ
- ✅ 詳細なレポート生成
- ✅ 高いスループット（並列化による高速化）
- ✅ プログレストラッキング
- ✅ エラーハンドリングとフォールバック