// SPDX-License-Identifier: Apache-2.0
//
// 阅读指引：这是最底层的文本读取工具，不负责判断反应是否符合物理。
// read_csv_table 读取字符串表格，csv_real/csv_int 等再做数值转换。

//
// Strict CSV reader for the G02_MCC_network model package.
//
// Grammar:
//   * comma separated fields;
//   * a field may be wrapped in double quotes; a literal double quote inside a
//     quoted field is written as "" (two double quotes);
//   * fields may not contain newlines (a line is a record);
//   * blank lines and whole-line comments starting with '#' (after optional
//     leading whitespace) are ignored;
//   * every record must have exactly the same number of fields as the header.
//
// Every parse failure reports "<file>:<line>: <message>".
#pragma once

#include "common.hpp"

#include <cstddef>
#include <filesystem>
#include <string>
#include <string_view>
#include <unordered_map>
#include <vector>

namespace algoplasma {
namespace mcc {

// 保留原文件行号，出错时能指向用户需要修改的那一行。
struct CsvRow {
    std::vector<std::string> fields;
    std::size_t line{0};
};

// 按列名访问数据，避免调用方把“第几列”写死。表头索引在首次查询时建立。
class CsvTable {
public:
    std::filesystem::path path;
    std::vector<std::string> header;
    std::vector<CsvRow> rows;

    [[nodiscard]] bool has_column(std::string_view name) const noexcept;
    [[nodiscard]] std::size_t column(std::string_view name) const; // throws Error
    [[nodiscard]] std::string value(const CsvRow& row, std::string_view name) const;
    // 缺列或空字段时使用 fallback；普通 value 不会自行补默认值。
    [[nodiscard]] std::string value_or(const CsvRow& row, std::string_view name,
                                       std::string fallback) const;

private:
    void build_index() const;
    mutable std::unordered_map<std::string, std::size_t> index_;
    mutable bool indexed_{false};
};

// Parse a single CSV record. `context` is used verbatim in error messages.
[[nodiscard]] std::vector<std::string> parse_csv_line(std::string_view line,
                                                      const std::string& context);

[[nodiscard]] CsvTable read_csv_table(const std::filesystem::path& path);

// Typed field readers. Errors include "<file>:<line>: column '<name>' ...".
// 必填实数必须完整转换且有限；带 _or 的函数才允许缺列/留空用默认值。
// 单位、正负范围和物理意义由上层 model/compile 检查。
[[nodiscard]] Real csv_real(const CsvTable& table, const CsvRow& row, std::string_view name);
[[nodiscard]] Real csv_real_or(const CsvTable& table, const CsvRow& row, std::string_view name,
                               Real fallback);
[[nodiscard]] long long csv_int(const CsvTable& table, const CsvRow& row, std::string_view name);
[[nodiscard]] bool csv_bool(const CsvTable& table, const CsvRow& row, std::string_view name);

[[nodiscard]] std::string to_lower(std::string value);
[[nodiscard]] std::string trim(std::string value);

// FNV-1a 64-bit checksum, rendered as 16 lowercase hex digits. The model package
// uses it for optional integrity entries in manifest.csv. This is an integrity
// check, not a cryptographic signature.
[[nodiscard]] std::string fnv1a64_hex(const std::filesystem::path& path);

} // namespace mcc
} // namespace algoplasma
