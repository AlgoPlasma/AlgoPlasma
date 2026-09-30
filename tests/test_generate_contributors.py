"""Checks for the generated contributor work lists."""

import re
import unittest
from html import escape as html_escape
from html.parser import HTMLParser

from tools import generate_contributors as contributors


class _VisibleText(HTMLParser):
    def __init__(self):
        super().__init__()
        self.parts = []

    def handle_data(self, data):
        self.parts.append(data)


class ContributorWorkListTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.entries = contributors.load_contributors()

    def test_documented_work_and_pending_members(self):
        detailed = {
            entry["name_zh"]: entry
            for entry in self.entries
            if entry["role"] in ("lead", "maintainer")
        }
        self.assertEqual(len(detailed), 13)
        expected = {
            "赵隐剑": "A01 C01 D01 D02 D04 E01 E02 E03 F01 F02 F03 F04 H01 H02 I01 J01",
            "赵中平": "A01 A02 B03 C01 C02 I02",
            "刘哲": "E01 E02 E03 F01 F02 F03 F04",
            "王佰胜": "D01 D02 D03 D04",
            "彭子龙": "A03 B01 D05 D06 H03",
            "罗鑫": "C02",
            "谢礼桓": "G01",
            "周志君": "B02",
        }
        for name, module_ids in expected.items():
            actual = [work["path"].name[:3] for work in detailed[name]["work"]]
            self.assertEqual(actual, module_ids.split(), name)
            for work in detailed[name]["work"]:
                attribution = work["path"].read_text(encoding="utf-8")
                self.assertTrue(
                    any(
                        "ap-home-contact" in line and name in line
                        for line in attribution.splitlines()
                    ),
                    f"{name}: {work['path'].name}",
                )
                readme_link = contributors._work_href(work, ".")
                docs_link = contributors._work_href(
                    work, contributors.RTD_TARGET_DIR
                )
                self.assertTrue((contributors.ROOT / readme_link).is_file())
                self.assertTrue(
                    (
                        contributors.ROOT
                        / contributors.RTD_TARGET_DIR
                        / docs_link
                    ).with_suffix(".rst").is_file()
                )
        self.assertEqual(
            {name for name, entry in detailed.items() if not entry["work"]},
            {"胡长征", "钟昆硼", "陈曦", "陈英杰", "张武顺"},
        )

    def test_localized_order_and_visible_descriptions(self):
        expected_zh = [
            "赵隐剑", "陈曦", "陈英杰", "胡长征", "刘哲", "罗鑫", "彭子龙",
            "王佰胜", "谢礼桓", "张武顺", "赵中平", "钟昆硼", "周志君",
        ]
        expected_en = [
            "Yinjian Zhao", "Baisheng Wang", "Changzheng Hu", "Kunpeng Zhong",
            "Lihuan Xie", "Wushun Zhang", "Xi Chen", "Xin Luo", "Yingjie Chen",
            "Zhe Liu", "Zhijun Zhou", "Zhongping Zhao", "Zilong Peng",
        ]
        group_roles = ("lead", "maintainer")
        for lang, expected in (("zh", expected_zh), ("en", expected_en)):
            group = contributors._readme_group(self.entries, group_roles, lang)
            self.assertEqual(
                [contributors.display_name(entry, lang) for entry in group], expected
            )
            page = contributors.render_readme_section(self.entries, lang)
            visible = _VisibleText()
            visible.feed(page)
            text = " ".join(visible.parts)
            self.assertEqual([part for part in visible.parts if part in expected], expected)
            self.assertIsNone(re.search(r"\b[A-J][0-9]{2}\b", text))
            self.assertIn(contributors.WORK_PENDING[lang], text)
            self.assertIn("docs/source/rst_files/A_Pusher/A01_Boris_3Dxyz.rst", page)
            self.assertIn("Bocong Zheng", page)
            docs_block = contributors._rtd_block(
                self.entries, lang, contributors.RTD_TARGET_DIR
            )
            docs_visible = _VisibleText()
            docs_visible.feed(docs_block)
            self.assertEqual(
                [part for part in docs_visible.parts if part in expected], expected
            )
            self.assertIsNone(
                re.search(r"\b[A-J][0-9]{2}\b", " ".join(docs_visible.parts))
            )
            self.assertIn("../rst_files/A_Pusher/A01_Boris_3Dxyz.html", docs_block)

    def test_catalog_rejects_invalid_entries(self):
        with self.assertRaises(SystemExit):
            contributors._normalise_work_catalog({"A01": {"zh": "粒子推进"}})
        with self.assertRaises(SystemExit):
            contributors._normalise_work_catalog(
                {"Z99": {"zh": "未知模块", "en": "Unknown module"}}
            )
        with self.assertRaises(ValueError):
            contributors._mini_yaml_load("work_catalog:\n  A01: first\n  A01: second\n")
        with self.assertRaises(SystemExit):
            contributors._normalise_work_catalog(
                {"A01": {"zh": "A01 粒子推进", "en": "Particle pushing"}}
            )

    def test_personal_avatars_and_relative_paths(self):
        expected = {
            "赵隐剑": "docs/source/_static/contributors/zhaoyinjian.png",
            "王佰胜": "docs/source/_static/contributors/wangbaisheng.jpg",
            "彭子龙": "docs/source/_static/contributors/pengzilong.jpg",
            "胡长征": "docs/source/_static/contributors/huchangzheng.jpg",
            "刘哲": "https://gitee.com/lzhe898.png",
        }
        for entry in self.entries:
            name = entry["name_zh"]
            if name not in expected:
                continue
            self.assertEqual(entry["avatar"], expected[name])
            for target_dir in (".", contributors.RTD_TARGET_DIR):
                src = contributors._avatar_url(entry, target_dir)
                table = contributors._work_table([entry], "zh", target_dir)
                self.assertIn(f'src="{src}"', table)
                if name == "刘哲":
                    self.assertEqual(src, expected[name])
                else:
                    path = contributors.ROOT / target_dir / src
                    self.assertEqual(path.resolve(), contributors.ROOT / expected[name])
                    self.assertTrue(path.is_file())

    def test_lead_biography_replaces_work_with_localized_header(self):
        lead = next(entry for entry in self.entries if entry["role"] == "lead")
        self.assertTrue(lead["work"])
        for lang in ("zh", "en"):
            for target_dir in (".", contributors.RTD_TARGET_DIR):
                table = contributors._work_table([lead], lang, target_dir)
                self.assertIn(f'>{contributors.BIOGRAPHY_LABELS[lang]}</th>', table)
                self.assertIn(html_escape(lead["biography"][lang], quote=False), table)
                self.assertIn('class="ap-member-biography"', table)
                self.assertNotIn('class="ap-work-items', table)
                self.assertNotIn(contributors.WORK_PENDING[lang], table)
                for work in lead["work"]:
                    self.assertNotIn(contributors._work_href(work, target_dir), table)

    def test_research_interests_preserve_documented_work(self):
        maintainers = [
            entry for entry in self.entries if entry["role"] == "maintainer"
        ]
        research_members = [
            entry for entry in maintainers if entry["research_interests"]
        ]
        self.assertEqual(
            {entry["name_zh"] for entry in research_members}, {"王佰胜", "彭子龙"}
        )
        for lang in ("zh", "en"):
            for target_dir in (".", contributors.RTD_TARGET_DIR):
                group = contributors._work_table(maintainers, lang, target_dir)
                self.assertIn(
                    f'>{contributors.RESEARCH_WORK_HEADERS[lang]}</th>', group
                )
                for entry in research_members:
                    table = contributors._work_table([entry], lang, target_dir)
                    self.assertIn(
                        html_escape(entry["research_interests"][lang], quote=False),
                        table,
                    )
                    self.assertIn(
                        f'<strong>{contributors.RESEARCH_LABELS[lang]}</strong>', table
                    )
                    self.assertLess(
                        table.index('class="ap-member-research"'),
                        table.index('class="ap-work-items"'),
                    )
                    for work in entry["work"]:
                        self.assertIn(contributors._work_href(work, target_dir), table)
                page = (
                    contributors.render_readme_section(self.entries, lang)
                    if target_dir == "."
                    else contributors._rtd_block(self.entries, lang, target_dir)
                )
                self.assertIn(f'>{contributors.BIOGRAPHY_LABELS[lang]}</th>', page)
                self.assertIn(
                    f'>{contributors.RESEARCH_WORK_HEADERS[lang]}</th>', page
                )

    def test_profile_text_validation_and_html_escaping(self):
        for field in ("biography", "research_interests"):
            self.assertEqual(
                contributors._normalise_profile_text(None, field, "Example"), {}
            )
            self.assertEqual(
                contributors._normalise_profile_text(
                    {"zh": " 中文 ", "en": " English "}, field, "Example"
                ),
                {"zh": "中文", "en": "English"},
            )
            invalid_values = (
                "text", [], {}, {"zh": "中文"}, {"zh": "中文", "en": " "},
                {"zh": True, "en": "English"},
            )
            for invalid in invalid_values:
                with self.subTest(field=field, invalid=invalid):
                    with self.assertRaises(SystemExit):
                        contributors._normalise_profile_text(invalid, field, "Example")
        lead = next(entry for entry in self.entries if entry["role"] == "lead")
        entry = {
            **lead,
            "biography": {
                "zh": '<script>alert("bio")</script>', "en": "Bio & research"
            },
            "research_interests": {
                "zh": "研究 <方向>", "en": "<research> & transport"
            },
        }
        for lang in ("zh", "en"):
            table = contributors._work_table([entry], lang, contributors.RTD_TARGET_DIR)
            self.assertIn(html_escape(entry["biography"][lang], quote=False), table)
            self.assertIn(
                html_escape(entry["research_interests"][lang], quote=False), table
            )
            self.assertNotIn("<script>", table)
            self.assertNotIn("<research>", table)


if __name__ == "__main__":
    unittest.main()
