"""Tests for the feature-design skill's mockup style check.

Standard library only. Run with `scripts/check-skill-scripts.sh`, or
`python3 -m unittest discover -s scripts/tests`.
"""
import contextlib
import io
import os
import sys
import tempfile
import unittest

SKILL = os.path.normpath(os.path.join(os.path.dirname(__file__), "..", "..",
                                      "plugins", "umbraco-devkit", "skills", "feature-design"))
sys.path.insert(0, os.path.join(SKILL, "scripts"))

import check_mockup  # noqa: E402

STARTERS = os.path.join(SKILL, "templates", "mockups")

STARTER = """<html><head>
<script type="module" src="_mockup.js"></script>
<style>
	.stat { font-size: 2rem; }
</style>
</head><body>
<h3>Content</h3>
<!-- Replace from here -->
<!-- Replace to here -->
</body></html>
"""


class CheckMockupTests(unittest.TestCase):
    def setUp(self):
        self.dir = tempfile.mkdtemp()
        self.starter = self.write("starter.html", STARTER)

    def write(self, name, text):
        path = os.path.join(self.dir, name)
        with open(path, "w", encoding="utf-8") as f:
            f.write(text)
        return path

    def kinds(self, feature, head=""):
        page = STARTER.replace("<style>\n", "<style>\n" + head).replace(
            "<!-- Replace from here -->\n", "<!-- Replace from here -->\n" + feature)
        findings, skipped = check_mockup.check(self.write("screen.html", page),
                                               check_mockup.starter_lines(self.starter))
        self.assertFalse(skipped)
        return [kind for _, kind, _ in findings]

    def test_the_starter_itself_is_clean(self):
        self.assertEqual(self.kinds(""), [])

    def test_every_shipped_starter_is_clean_against_itself(self):
        for name in os.listdir(STARTERS):
            if name.endswith(".html"):
                path = os.path.join(STARTERS, name)
                findings, _ = check_mockup.check(path, check_mockup.starter_lines(path))
                self.assertEqual(findings, [], name)

    def test_plain_uui_markup_passes(self):
        self.assertEqual(self.kinds('<uui-box headline="Sharing"><div class="property">'
                                    '<uui-label>Mode</uui-label></div></uui-box>\n'), [])

    def test_new_css_rule_is_flagged_once(self):
        self.assertEqual(self.kinds("", head=".share-field {\n\tpadding: 4px;\n}\n"),
                         ["custom CSS rule"])

    def test_new_declaration_in_a_starter_rule_is_flagged(self):
        page = STARTER.replace(".stat { font-size: 2rem; }",
                               ".stat {\n\tfont-size: 2rem;\n\tmargin: 3px;\n}")
        starter = self.write("starter2.html", page.replace("\tmargin: 3px;\n", ""))
        findings, _ = check_mockup.check(self.write("screen.html", page),
                                         check_mockup.starter_lines(starter))
        self.assertEqual([kind for _, kind, _ in findings], ["custom CSS"])

    def test_inline_style_is_flagged(self):
        self.assertEqual(self.kinds('<div style="margin: 0">x</div>\n'), ["inline style"])

    def test_raw_colour_and_hex_fallback_are_flagged(self):
        self.assertEqual(self.kinds("", head=".a { color: var(--uui-color-positive, #3a8148); }\n"),
                         ["custom CSS rule", "raw colour"])
        self.assertIn("raw colour", self.kinds('<svg><rect fill="#ff0000"></rect></svg>\n'))

    def test_anchor_links_are_not_colours(self):
        self.assertEqual(self.kinds('<a href="#add">Add</a>\n'), [])

    def test_important_is_flagged(self):
        self.assertIn("!important", self.kinds("", head=".a { margin: 0 !important; }\n"))

    def test_bare_heading_is_flagged_but_a_classed_one_is_not(self):
        self.assertEqual(self.kinds("<h4>Shared with me</h4>\n"), ["bare heading"])
        self.assertEqual(self.kinds('<h3 class="headline">Share</h3>\n'), [])

    def test_css_comments_are_ignored(self):
        self.assertEqual(self.kinds("", head="/* was #a17700, too dark\n   !important */\n"), [])

    def test_mockup_ok_on_a_rule_covers_the_whole_rule(self):
        head = ".bubble { /* mockup-ok: copied from chat-message.element.ts */\n\tbackground: #fff;\n}\n"
        self.assertEqual(self.kinds("", head=head), [])

    def test_mockup_ok_needs_a_reason(self):
        self.assertEqual(self.kinds('<div style="margin: 0"><!-- mockup-ok: --></div>\n'),
                         ["inline style"])

    def test_pages_without_the_harness_are_skipped(self):
        email = self.write("email.html", '<!-- not the _mockup.js harness -->\n'
                                         '<td style="background: #1d1333">Hi</td>\n')
        findings, skipped = check_mockup.check(email, set())
        self.assertTrue(skipped)
        self.assertEqual(findings, [])

    def test_linked_stylesheet_is_checked_once(self):
        self.write("feature.css", ".share-row {\n\tpadding: 4px;\n}\n")
        page = STARTER.replace("</head>", '<link rel="stylesheet" href="feature.css">\n</head>')
        one, two = self.write("one.html", page), self.write("two.html", page)
        out = io.StringIO()
        with contextlib.redirect_stdout(out):
            self.assertEqual(check_mockup.main(["--starter", self.starter, one, two]), 1)
        self.assertEqual(out.getvalue().count("custom CSS rule: .share-row"), 1)

    def test_stylesheet_the_starter_links_is_known(self):
        self.write("surface.css", ".chat {\n\tdisplay: flex;\n}\n")
        link = '<link rel="stylesheet" href="surface.css">\n</head>'
        starter = self.write("surface.html", STARTER.replace("</head>", link))
        screen = self.write("screen.html", STARTER.replace("</head>", link))
        known = check_mockup.starter_lines(starter)
        self.assertEqual(check_mockup.check_stylesheet(os.path.join(self.dir, "surface.css"), known), [])
        with contextlib.redirect_stdout(io.StringIO()):
            self.assertEqual(check_mockup.main(["--starter", starter, screen]), 0)

    def test_remote_and_harness_stylesheets_are_not_followed(self):
        page = self.write("screen.html", STARTER.replace("</head>",
            '<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/@umbraco-ui/uui@2/dist/themes/light.css">\n'
            '<link rel="stylesheet" href="_mockup.css">\n</head>'))
        self.assertEqual(check_mockup.linked_stylesheets(page), [])

    def test_exit_codes(self):
        clean = self.write("clean.html", STARTER)
        dirty = self.write("dirty.html", STARTER.replace("<h3>Content</h3>", "<h3>Content</h3>\n<h4>x</h4>"))
        with contextlib.redirect_stdout(io.StringIO()):
            self.assertEqual(check_mockup.main(["--starter", self.starter, clean]), 0)
            self.assertEqual(check_mockup.main(["--starter", self.starter, dirty]), 1)
        with contextlib.redirect_stderr(io.StringIO()):
            self.assertEqual(check_mockup.main(["--starter", "missing.html", clean]), 2)


if __name__ == "__main__":
    unittest.main()
