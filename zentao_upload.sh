#!/bin/bash

# 配置禅道 API
ZENTAO_URL="http://localhost:8090/api.php/v1"
credentialsId='zentaotoken'
TOKEN="$ZENTAO_TOKEN"  # 从环境变量读取 Token
# 动态获取最新 tar.gz 文件
FILE_PATH=$(ls dist/printforloop-*.tar.gz | sort -V | tail -n1)
# 确保文件存在
if [[ ! -f "$FILE_PATH" ]]; then
    echo "❌ 错误: 文件 $FILE_PATH 不存在！"
    exit 1
fi

# 上传文件到禅道
UPLOAD_RESPONSE=$(curl -s -X POST "$ZENTAO_URL/files" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: multipart/form-data" \
    -F "file=@$FILE_PATH")

# 检查请求是否成功
if [[ $? -ne 0 ]]; then
    echo "❌ 错误: 文件上传失败！"
    exit 1
fi

# 解析返回的 JSON 并获取 fileId
FILE_ID=$(echo "$UPLOAD_RESPONSE" | jq -r '.id')

# 确保 fileId 有效
if [[ -z "$FILE_ID" || "$FILE_ID" == "null" ]]; then
    echo "❌ 错误: 无法获取文件 ID, API 响应: $UPLOAD_RESPONSE"
    exit 1
fi

echo "✅ 上传成功，文件 ID: $FILE_ID"

# 关联到任务
TASK_ID="123"  # 你的任务 ID
TASK_RESPONSE=$(curl -s -X POST "$ZENTAO_URL/tasks/$TASK_ID/files" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"files\": [$FILE_ID], \"type\": \"task\"}")

# # 指定项目集 ID
# PROJECT_ID="1"  
# # 上传文件到某个项目集
# UPLOAD_RESPONSE=$(curl -s -X POST "$ZENTAO_URL/files" \
#     -H "Authorization: Bearer $TOKEN" \
#     -H "Content-Type: multipart/form-data" \
#     -F "file=@$FILE_PATH" \
#     -F "objectType=project" \
#     -F "objectID=$PROJECT_ID")

# 检查任务关联是否成功
if [[ $? -ne 0 ]]; then
    echo "❌ 错误: 关联任务失败！"
    exit 1
fi

echo "✅ 任务关联成功"
