#!/bin/bash
set -e  # 遇到错误立即退出

# 配置禅道 API
ZENTAO_URL="http://localhost:8090/api.php/v1"
PROJECT_ID="1"  # 项目集 ID
TASK_ID="1"     # 任务 ID

# ----------------------------
# 动态获取最新构建文件
# ----------------------------
FILE_PATH=$(ls dist/printforloop-*.tar.gz | sort -V | tail -n1)
if [[ ! -f "$FILE_PATH" ]]; then
    echo "❌ 错误: 文件 $FILE_PATH 不存在！"
    exit 1
fi
echo "=== 将上传文件: $FILE_PATH ==="

# ----------------------------
# 上传文件到禅道 (关联到任务)
# ----------------------------
echo "=== 正在上传文件到禅道... ==="
UPLOAD_RESPONSE=$(curl -v -X POST "$ZENTAO_URL/files" \
  -H "Authorization: Bearer $ZENTAO_TOKEN" \
  -H "Content-Type: multipart/form-data" \
  -F "file=@$FILE_PATH" \
  -F "objectType=task" \
  -F "objectID=$TASK_ID" 2>&1)  # 注意使用 -v 并捕获所有输出

# 提取 HTTP 状态码
HTTP_CODE=$(echo "$UPLOAD_RESPONSE" | grep -oP 'HTTP/\d\.\d \K\d+')
JSON_RESPONSE=$(echo "$UPLOAD_RESPONSE" | grep -E '^{.*}')

# 调试输出
echo "=== 调试信息 ==="
echo "HTTP 状态码: $HTTP_CODE"
echo "API 响应: $JSON_RESPONSE"

# 检查上传结果
if [[ "$HTTP_CODE" -ne 200 ]]; then
  echo "❌ 错误: 文件上传失败 (状态码: $HTTP_CODE)"
  exit 1
fi

FILE_ID=$(echo "$JSON_RESPONSE" | jq -r '.id')
if [[ -z "$FILE_ID" || "$FILE_ID" == "null" ]]; then
  echo "❌ 错误: 解析文件 ID 失败"
  exit 1
fi
echo "✅ 文件上传成功！ID: $FILE_ID"

# ----------------------------
# （可选）额外关联到任务（如果必须单独调用）
# ----------------------------
echo "=== 关联文件到任务 $TASK_ID... ==="
TASK_RESPONSE=$(curl -v -X POST "$ZENTAO_URL/tasks/$TASK_ID/files" \
  -H "Authorization: Bearer $ZENTAO_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"files\": [$FILE_ID], \"type\": \"file\"}" 2>&1)

# 检查关联结果
TASK_HTTP_CODE=$(echo "$TASK_RESPONSE" | grep -oP 'HTTP/\d\.\d \K\d+')
if [[ "$TASK_HTTP_CODE" -ne 200 ]]; then
  echo "⚠️ 警告: 文件关联到任务失败 (状态码: $TASK_HTTP_CODE)"
  echo "响应详情: $(echo "$TASK_RESPONSE" | grep -E '^{.*}')"
else
  echo "✅ 文件已成功关联到任务"
fi
