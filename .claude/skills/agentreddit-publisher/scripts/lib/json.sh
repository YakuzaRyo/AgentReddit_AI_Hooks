#!/bin/bash
#
# JSON Library - Pure Bash + Node.js fallback
# 纯 Bash JSON 处理，在没有 jq 时使用 Node.js 作为备选
#

# 检测 JSON 处理工具
JSON_TOOL=""
detect_json_tool() {
    if command -v jq &> /dev/null; then
        JSON_TOOL="jq"
    elif command -v node &> /dev/null; then
        JSON_TOOL="node"
    else
        echo "Error: Neither jq nor node is installed." >&2
        echo "Please install jq: https://stedolan.github.io/jq/download/" >&2
        echo "Or install Node.js: https://nodejs.org/" >&2
        return 1
    fi
}

# 使用 Node.js 读取 JSON 字段
json_get_node() {
    local json="$1"
    local path="$2"
    node -e "
        try {
            const data = JSON.parse(process.argv[1]);
            const path = process.argv[2];
            const parts = path.split('.');
            let result = data;
            for (const part of parts) {
                if (result === null || result === undefined) break;
                if (part.match(/^\d+$/)) {
                    result = result[parseInt(part)];
                } else {
                    result = result[part];
                }
            }
            if (result === null) console.log('null');
            else if (result === undefined) console.log('');
            else if (typeof result === 'object') console.log(JSON.stringify(result));
            else console.log(result);
        } catch(e) {
            console.log('');
        }
    " "$json" "$path"
}

# 使用 Node.js 设置 JSON 字段
json_set_node() {
    local json="$1"
    local path="$2"
    local value="$3"
    node -e "
        try {
            const data = JSON.parse(process.argv[1]);
            const path = process.argv[2];
            let value = process.argv[3];
            try { value = JSON.parse(value); } catch(e) {}
            const parts = path.split('.');
            let target = data;
            for (let i = 0; i < parts.length - 1; i++) {
                const part = parts[i];
                if (!(part in target)) target[part] = {};
                target = target[part];
            }
            target[parts[parts.length - 1]] = value;
            console.log(JSON.stringify(data, null, 2));
        } catch(e) {
            console.log(process.argv[1]);
        }
    " "$json" "$path" "$value"
}

# 使用 Node.js 创建 JSON 数组
json_array_node() {
    node -e "console.log(JSON.stringify(process.argv.slice(1)));" "$@"
}

# 使用 Node.js 添加数组元素
json_array_append_node() {
    local json="$1"
    local item="$2"
    node -e "
        try {
            const arr = JSON.parse(process.argv[1]);
            let item = process.argv[2];
            try { item = JSON.parse(item); } catch(e) {}
            arr.push(item);
            console.log(JSON.stringify(arr));
        } catch(e) {
            console.log('[]');
        }
    " "$json" "$item"
}

# 使用 Node.js 格式化 JSON
json_format_node() {
    local json="$1"
    node -e "
        try {
            const data = JSON.parse(process.argv[1]);
            console.log(JSON.stringify(data, null, 2));
        } catch(e) {
            console.log(process.argv[1]);
        }
    " "$json"
}

# 使用 jq 读取 JSON 字段
json_get_jq() {
    local json="$1"
    local path="$2"
    echo "$json" | jq -r "${path:-.} // empty" 2>/dev/null
}

# 使用 jq 设置 JSON 字段
json_set_jq() {
    local json="$1"
    local path="$2"
    local value="$3"
    echo "$json" | jq "${path} = \"$value\"" 2>/dev/null
}

# 使用 jq 创建数组
json_array_jq() {
    printf '%s\n' "$@" | jq -R . | jq -s .
}

# 使用 jq 添加数组元素
json_array_append_jq() {
    local json="$1"
    local item="$2"
    echo "$json" | jq --arg item "$item" '. + [$item]'
}

# 使用 jq 格式化 JSON
json_format_jq() {
    local json="$1"
    echo "$json" | jq '.' 2>/dev/null || echo "$json"
}

# 统一的 JSON 读取接口
json_get() {
    local json="$1"
    local path="${2:-.}"

    if [[ -z "$JSON_TOOL" ]]; then
        detect_json_tool || return 1
    fi

    if [[ "$JSON_TOOL" == "jq" ]]; then
        json_get_jq "$json" "$path"
    else
        json_get_node "$json" "$path"
    fi
}

# 统一的 JSON 设置接口
json_set() {
    local json="$1"
    local path="$2"
    local value="$3"

    if [[ -z "$JSON_TOOL" ]]; then
        detect_json_tool || return 1
    fi

    if [[ "$JSON_TOOL" == "jq" ]]; then
        json_set_jq "$json" "$path" "$value"
    else
        json_set_node "$json" "$path" "$value"
    fi
}

# 统一的 JSON 数组创建接口
json_array() {
    if [[ -z "$JSON_TOOL" ]]; then
        detect_json_tool || return 1
    fi

    if [[ "$JSON_TOOL" == "jq" ]]; then
        json_array_jq "$@"
    else
        json_array_node "$@"
    fi
}

# 统一的数组添加接口
json_array_append() {
    local json="$1"
    local item="$2"

    if [[ -z "$JSON_TOOL" ]]; then
        detect_json_tool || return 1
    fi

    if [[ "$JSON_TOOL" == "jq" ]]; then
        json_array_append_jq "$json" "$item"
    else
        json_array_append_node "$json" "$item"
    fi
}

# 统一的 JSON 格式化接口
json_format() {
    local json="$1"

    if [[ -z "$JSON_TOOL" ]]; then
        detect_json_tool || return 1
    fi

    if [[ "$JSON_TOOL" == "jq" ]]; then
        json_format_jq "$json"
    else
        json_format_node "$json"
    fi
}

# 读取 JSON 文件
json_read_file() {
    local filepath="$1"
    if [[ -f "$filepath" ]]; then
        cat "$filepath" 2>/dev/null || echo '{}'
    else
        echo '{}'
    fi
}

# 写入 JSON 文件
json_write_file() {
    local filepath="$1"
    local content="$2"
    local dir
    dir=$(dirname "$filepath")
    mkdir -p "$dir"
    echo "$content" > "$filepath"
}

# 获取 JSON 数组长度
json_array_length() {
    local json="$1"

    if [[ -z "$JSON_TOOL" ]]; then
        detect_json_tool || return 1
    fi

    if [[ "$JSON_TOOL" == "jq" ]]; then
        echo "$json" | jq 'length' 2>/dev/null || echo 0
    else
        node -e "
            try {
                const arr = JSON.parse(process.argv[1]);
                console.log(arr.length);
            } catch(e) {
                console.log(0);
            }
        " "$json"
    fi
}

# 检测 JSON 工具
detect_json_tool
