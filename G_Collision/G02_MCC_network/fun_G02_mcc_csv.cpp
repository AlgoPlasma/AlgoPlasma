// SPDX-License-Identifier: Apache-2.0
//
// 阅读顺序：单行拆字段 -> 整文件读表 -> 字段转数值 -> 可选校验码。
// 本文件只检查文本格式；物种引用和物理单位由 model/compile 两层检查。

#include "csv.hpp"

#include <cctype>
#include <cstdlib>
#include <fstream>
#include <iomanip>
#include <sstream>

namespace algoplasma {
namespace mcc {
namespace {

[[noreturn]] void fail(const std::string& context, const std::string& message) {
    throw Error(context + ": " + message);
}

[[nodiscard]] std::string context_of(const CsvTable& table, const CsvRow& row,
                                     std::string_view column) {
    return table.path.string() + ":" + std::to_string(row.line) + ": column '" +
           std::string(column) + "'";
}

} // namespace

std::string trim(std::string value) {
    const auto first = value.find_first_not_of(" \t\r\n");
    if (first == std::string::npos) return {};
    const auto last = value.find_last_not_of(" \t\r\n");
    return value.substr(first, last - first + 1U);
}

std::string to_lower(std::string value) {
    for (char& c : value) {
        c = static_cast<char>(std::tolower(static_cast<unsigned char>(c)));
    }
    return value;
}

// 1. 扫描单行：引号内的逗号是内容，引号外的逗号才分列。
// 连续两个双引号表示一个字面双引号；每个字段最后都会去掉首尾空白。
std::vector<std::string> parse_csv_line(const std::string_view line,
                                        const std::string& context) {
    std::vector<std::string> fields;
    std::string field;
    bool quoted = false;
    bool field_had_quotes = false;
    for (std::size_t i = 0; i < line.size(); ++i) {
        const char c = line[i];
        if (c == '"') {
            if (quoted && i + 1U < line.size() && line[i + 1U] == '"') {
                field.push_back('"');
                ++i;
            } else if (!quoted && !field.empty() && field.find_first_not_of(" \t") != std::string::npos) {
                fail(context, "unexpected quote in the middle of an unquoted field");
            } else {
                quoted = !quoted;
                field_had_quotes = true;
            }
        } else if (c == ',' && !quoted) {
            fields.push_back(trim(field));
            field.clear();
            field_had_quotes = false;
        } else if (c == '\r') {
            fail(context, "carriage return inside a record is not supported");
        } else {
            field.push_back(c);
        }
    }
    if (quoted) fail(context, "unterminated quote in CSV record");
    (void)field_had_quotes;
    fields.push_back(trim(field));
    return fields;
}

// 2. 建立列名到下标的索引，避免每读一个数都重新扫描表头。
void CsvTable::build_index() const {
    if (indexed_) return;
    index_.clear();
    for (std::size_t i = 0; i < header.size(); ++i) {
        if (header[i].empty()) continue;
        if (index_.count(header[i]) != 0U) {
            throw Error(path.string() + ":1: duplicate column '" + header[i] + "'");
        }
        index_.emplace(header[i], i);
    }
    indexed_ = true;
}

bool CsvTable::has_column(const std::string_view name) const noexcept {
    try {
        build_index();
    } catch (...) {
        return false;
    }
    return index_.find(std::string(name)) != index_.end();
}

std::size_t CsvTable::column(const std::string_view name) const {
    build_index();
    const auto found = index_.find(std::string(name));
    if (found == index_.end()) {
        throw Error(path.string() + ": missing required column '" + std::string(name) + "'");
    }
    return found->second;
}

std::string CsvTable::value(const CsvRow& row, const std::string_view name) const {
    const std::size_t index = column(name);
    if (index >= row.fields.size()) {
        throw Error(context_of(*this, row, name) + ": record is missing the field");
    }
    return row.fields[index];
}

std::string CsvTable::value_or(const CsvRow& row, const std::string_view name,
                               std::string fallback) const {
    if (!has_column(name)) return fallback;
    const std::string raw = value(row, name);
    return raw.empty() ? std::move(fallback) : raw;
}

// 3. 第一条非空、非注释记录作为表头；其余记录必须与表头等宽。
// CSV 中看似为空的末尾字段也必须用逗号占位，否则会变成缺列。
CsvTable read_csv_table(const std::filesystem::path& path) {
    std::ifstream input(path);
    if (!input) throw Error("cannot open CSV file: " + path.string());
    CsvTable table;
    table.path = path;
    std::string line;
    std::size_t line_number = 0;
    bool have_header = false;
    while (std::getline(input, line)) {
        ++line_number;
        const std::string context = path.string() + ":" + std::to_string(line_number);
        const std::string stripped = trim(line);
        if (stripped.empty() || stripped.front() == '#') continue;
        std::vector<std::string> fields = parse_csv_line(stripped, context);
        if (!have_header) {
            table.header = std::move(fields);
            if (table.header.empty()) fail(context, "empty CSV header");
            have_header = true;
            continue;
        }
        if (fields.size() != table.header.size()) {
            fail(context, "expected " + std::to_string(table.header.size()) +
                              " fields but found " + std::to_string(fields.size()));
        }
        table.rows.push_back(CsvRow{std::move(fields), line_number});
    }
    if (!have_header) throw Error(path.string() + ": file has no header row");
    return table;
}

// 4. 数值转换：不仅检查能否读出数，还检查是否读完全部字符。
// 例如 1.5abc 不能被悄悄当成 1.5，NaN/无穷也不能进入物理计算。
Real csv_real(const CsvTable& table, const CsvRow& row, const std::string_view name) {
    const std::string text = table.value(row, name);
    if (text.empty()) throw Error(context_of(table, row, name) + ": value is empty");
    std::size_t consumed = 0;
    Real value = 0.0;
    try {
        value = std::stod(text, &consumed);
    } catch (const std::exception&) {
        throw Error(context_of(table, row, name) + ": '" + text + "' is not a number");
    }
    if (consumed != text.size()) {
        throw Error(context_of(table, row, name) + ": '" + text + "' has trailing characters");
    }
    if (!std::isfinite(value)) {
        throw Error(context_of(table, row, name) + ": '" + text + "' is NaN or infinite");
    }
    return value;
}

Real csv_real_or(const CsvTable& table, const CsvRow& row, const std::string_view name,
                 const Real fallback) {
    if (!table.has_column(name)) return fallback;
    const std::string raw = table.value(row, name);
    if (raw.empty()) return fallback;
    return csv_real(table, row, name);
}

long long csv_int(const CsvTable& table, const CsvRow& row, const std::string_view name) {
    const std::string text = table.value(row, name);
    if (text.empty()) throw Error(context_of(table, row, name) + ": value is empty");
    std::size_t consumed = 0;
    long long value = 0;
    try {
        value = std::stoll(text, &consumed);
    } catch (const std::exception&) {
        throw Error(context_of(table, row, name) + ": '" + text + "' is not an integer");
    }
    if (consumed != text.size()) {
        throw Error(context_of(table, row, name) + ": '" + text + "' has trailing characters");
    }
    return value;
}

// 布尔列本身必须存在；内容留空按 false，其他允许写法见下面两组判断。
bool csv_bool(const CsvTable& table, const CsvRow& row, const std::string_view name) {
    const std::string normalized = to_lower(trim(table.value(row, name)));
    if (normalized == "1" || normalized == "true" || normalized == "yes" || normalized == "on") {
        return true;
    }
    if (normalized == "0" || normalized == "false" || normalized == "no" ||
        normalized == "off" || normalized.empty()) {
        return false;
    }
    throw Error(context_of(table, row, name) + ": '" + normalized + "' is not a boolean");
}

// 5. 对原始文件字节生成校验码，用来发现数据文件变化；不是物理正确性证明。
std::string fnv1a64_hex(const std::filesystem::path& path) {
    std::ifstream input(path, std::ios::binary);
    if (!input) throw Error("cannot open file for checksum: " + path.string());
    std::uint64_t hash = 1469598103934665603ULL;
    char byte = 0;
    while (input.get(byte)) {
        hash ^= static_cast<std::uint64_t>(static_cast<unsigned char>(byte));
        hash *= 1099511628211ULL;
    }
    std::ostringstream output;
    output << std::hex << std::setw(16) << std::setfill('0') << hash;
    return output.str();
}

} // namespace mcc
} // namespace algoplasma
