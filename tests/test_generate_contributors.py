"""Checks for the generated contributor work lists."""

import io
import re
import unittest
from contextlib import redirect_stdout
from html import escape as html_escape
from html.parser import HTMLParser
from pathlib import Path
from tempfile import TemporaryDirectory
from unittest.mock import patch
from xml.etree import ElementTree

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
            "赵隐剑": "A01 C01 D01 D02 D04 E01 E02 E03 F01 F02 F03 F04 H01 H02 I01 J01 K04",
            "赵中平": "A01 A02 B03 C01 C02 I02",
            "刘哲": "E01 E02 E03 F01 F02 F03 F04 G02",
            "王佰胜": "C03 D01 D02 D03 D04",
            "彭子龙": "A03 B01 D05 D06 H03 K01 K02 K03",
            "罗鑫": "C02",
            "谢礼桓": "G01 G02",
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

    def test_curated_order_and_compact_profiles_in_both_languages(self):
        expected_zh = [
            "赵隐剑", "王佰胜", "刘哲", "赵中平", "彭子龙", "罗鑫", "谢礼桓",
            "陈曦", "陈英杰", "钟昆硼", "周志君", "张武顺", "胡长征",
        ]
        expected_en = [
            "Yinjian Zhao", "Baisheng Wang", "Zhe Liu", "Zhongping Zhao",
            "Zilong Peng", "Xin Luo", "Lihuan Xie", "Xi Chen", "Yingjie Chen",
            "Kunpeng Zhong", "Zhijun Zhou", "Wushun Zhang", "Changzheng Hu",
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
            self.assertIsNone(re.search(r"\b[A-K][0-9]{2}\b", text))
            self.assertNotIn(contributors.WORK_PENDING[lang], text)
            self.assertNotIn('class="ap-work-items', page)
            self.assertNotIn("Bocong Zheng", page)
            docs_block = contributors._rtd_block(
                self.entries, lang, contributors.RTD_TARGET_DIR
            )
            docs_visible = _VisibleText()
            docs_visible.feed(docs_block)
            self.assertEqual(
                [part for part in docs_visible.parts if part in expected], expected
            )
            self.assertIsNone(
                re.search(r"\b[A-K][0-9]{2}\b", " ".join(docs_visible.parts))
            )
            self.assertNotIn('class="ap-contributor-intro"', docs_block)
            for rendered in (page, docs_block):
                self.assertNotIn("Bocong Zheng", rendered)
                self.assertNotIn('class="ap-contributors"', rendered)
                self.assertIn('class="ap-maintainers"', rendered)
                self.assertEqual(rendered.count('class="ap-member-status"'), 12)
                for entry in group[1:]:
                    self.assertIn(html_escape(entry["academic_status"][lang]), rendered)
                    links = contributors._profile_links(entry, separator=" ")
                    if links:
                        self.assertIn(links, rendered)
                    for work in entry["work"]:
                        target_dir = "." if rendered == page else contributors.RTD_TARGET_DIR
                        self.assertNotIn(contributors._work_href(work, target_dir), rendered)

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
            self.assertFalse(entry["generated_avatar"])
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

    def test_surname_first_initial_avatars(self):
        expected = {
            "陈曦": "CX", "陈英杰": "CY", "罗鑫": "LX", "谢礼桓": "XL",
            "张武顺": "ZW", "赵中平": "ZZ", "钟昆硼": "ZK", "周志君": "ZZ",
        }
        generated = [entry for entry in self.entries if entry["generated_avatar"]]
        self.assertEqual({entry["name_zh"] for entry in generated}, set(expected))
        avatars = contributors.desired_avatars(self.entries)
        self.assertEqual(len(avatars), len(expected))
        namespace = {"svg": "http://www.w3.org/2000/svg"}
        for entry in generated:
            with self.subTest(name=entry["name_zh"]):
                initials = expected[entry["name_zh"]]
                self.assertEqual(contributors._initials(entry["name"]), initials)
                path = contributors.ROOT / entry["avatar"]
                svg = ElementTree.fromstring(avatars[path])
                self.assertEqual(svg.find("svg:text", namespace).text, initials)
                self.assertEqual(svg.get("aria-label"), entry["name"])
                self.assertEqual(svg.get("viewBox"), "0 0 160 160")
                for target_dir in (".", contributors.RTD_TARGET_DIR):
                    src = contributors._avatar_url(entry, target_dir)
                    self.assertEqual(
                        (contributors.ROOT / target_dir / src).resolve(), path
                    )
                    self.assertIn(
                        f'src="{src}"',
                        contributors._work_table([entry], "zh", target_dir),
                    )

    def test_default_avatar_precedence(self):
        for role in ("lead", "maintainer", "contributor"):
            entry = {
                "name": "Yingjie Chen", "role": role,
                "github": "example-github", "gitee": "example-gitee",
            }
            normalised = contributors._normalise(entry, 0, {})
            if role == "contributor":
                self.assertEqual(
                    normalised["avatar"], "https://github.com/example-github.png"
                )
                self.assertFalse(normalised["generated_avatar"])
            else:
                self.assertEqual(
                    normalised["avatar"],
                    "docs/source/_static/contributors/yingjie-chen.svg",
                )
                self.assertTrue(normalised["generated_avatar"])
            explicit = contributors._normalise(
                {**entry, "avatar": "https://example.com/portrait.png"}, 0, {}
            )
            self.assertEqual(explicit["avatar"], "https://example.com/portrait.png")
            self.assertFalse(explicit["generated_avatar"])
        gitee = contributors._normalise(
            {"name": "Example User", "gitee": "example-gitee"}, 0, {}
        )
        self.assertEqual(gitee["avatar"], "https://gitee.com/example-gitee.png")
        self.assertFalse(gitee["generated_avatar"])
        no_account = contributors._normalise({"name": "Example User"}, 0, {})
        self.assertTrue(no_account["generated_avatar"])
        shared = contributors._normalise(
            {"name": "Example User"}, 0, {},
            default_avatar="docs/source/_static/contributors/zhaoyinjian.png",
        )
        self.assertEqual(
            shared["avatar"], "docs/source/_static/contributors/zhaoyinjian.png"
        )
        self.assertFalse(shared["generated_avatar"])
        with self.assertRaises(SystemExit):
            contributors._normalise(
                {"name": "Example User", "avatar": "missing-portrait.png"}, 0, {}
            )

    def test_initial_svg_is_deterministic_and_escaped(self):
        name = 'Xi "A & B" Chen'
        first = contributors._avatar_svg(name)
        self.assertEqual(first, contributors._avatar_svg(name))
        svg = ElementTree.fromstring(first)
        self.assertEqual(svg.get("aria-label"), name)
        self.assertEqual(
            svg.find("{http://www.w3.org/2000/svg}text").text, "CX"
        )
        self.assertEqual(contributors._initials("  Yingjie   Chen  "), "CY")
        self.assertEqual(contributors._initials("A"), "A")
        self.assertEqual(contributors._initials(""), "?")

    def test_generator_checks_and_creates_initial_avatars(self):
        with TemporaryDirectory() as directory:
            root = Path(directory)
            avatar = root / "avatars" / "xi-chen.svg"
            content = contributors._avatar_svg("Xi Chen")
            with (
                patch.object(contributors, "ROOT", root),
                patch.object(contributors, "load_contributors", return_value=self.entries),
                patch.object(contributors, "desired_files", return_value={}),
                patch.object(contributors, "desired_avatars", return_value={avatar: content}),
                redirect_stdout(io.StringIO()),
            ):
                self.assertEqual(contributors.main(["--check"]), 1)
                self.assertFalse(avatar.exists())
                self.assertEqual(contributors.main([]), 0)
                self.assertEqual(avatar.read_text(encoding="utf-8"), content)
                self.assertEqual(contributors.main(["--check"]), 0)
                avatar.write_text("outdated\n", encoding="utf-8")
                self.assertEqual(contributors.main(["--check"]), 1)
                self.assertEqual(avatar.read_text(encoding="utf-8"), "outdated\n")
                self.assertEqual(contributors.main([]), 0)
                self.assertEqual(contributors.main(["--check"]), 0)

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

    def test_research_interests_without_documented_work(self):
        maintainers = [
            entry for entry in self.entries if entry["role"] == "maintainer"
        ]
        research_members = [
            entry for entry in maintainers if entry["research_interests"]
        ]
        self.assertEqual(len(research_members), 12)
        for lang in ("zh", "en"):
            for target_dir in (".", contributors.RTD_TARGET_DIR):
                group = contributors._maintainer_table(maintainers, lang, target_dir)
                self.assertIn('class="ap-maintainers"', group)
                for entry in research_members:
                    table = contributors._maintainer_table([entry], lang, target_dir)
                    self.assertIn(
                        html_escape(entry["research_interests"][lang], quote=False),
                        table,
                    )
                    self.assertIn(
                        f'<strong>{contributors.RESEARCH_LABELS[lang]}</strong>', table
                    )
                    self.assertNotIn('class="ap-work-items"', table)
                    self.assertNotIn(contributors.WORK_HEADERS[lang][1], table)
                    for work in entry["work"]:
                        self.assertNotIn(contributors._work_href(work, target_dir), table)
                page = (
                    contributors.render_readme_section(self.entries, lang)
                    if target_dir == "."
                    else contributors._rtd_block(self.entries, lang, target_dir)
                )
                self.assertIn(f'>{contributors.BIOGRAPHY_LABELS[lang]}</th>', page)
                self.assertNotIn(
                    f'>{contributors.RESEARCH_WORK_HEADERS[lang]}</th>', page
                )
                for entry in research_members:
                    self.assertIn(
                        html_escape(entry["research_interests"][lang], quote=False), page
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
