import pathlib
import runpy
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]
WRAPPER = runpy.run_path(str(ROOT / "bin/cosmos-applet-dropdown-terminal-wrapper-toggle"))


def output(name="DP-1", width=1920, height=1080, scale=1, transform="normal", x=0):
    return {"name": name, "enabled": True, "scale": scale, "transform": transform,
            "position": {"x": x, "y": 0},
            "modes": [{"width": width, "height": height, "current": True}]}


class WrapperTests(unittest.TestCase):
    def test_height_includes_native_one_pixel_frame(self):
        self.assertEqual(WRAPPER["panel_height"](output()) + 1, 432)

    def test_fractional_scale_uses_logical_coordinates(self):
        self.assertEqual(WRAPPER["panel_height"](output(height=2160, scale=1.5)) + 1, 576)

    def test_rotated_output_uses_mode_width(self):
        for transform in ("90", "270", "flipped-90", "flipped-270"):
            with self.subTest(transform=transform):
                self.assertEqual(WRAPPER["panel_height"](output(transform=transform)) + 1, 768)

    def test_invalid_scale_is_rejected(self):
        for scale in (0, -1, float("nan"), float("inf")):
            with self.subTest(scale=scale), self.assertRaises(ValueError):
                WRAPPER["panel_height"](output(scale=scale))

    def test_missing_current_mode_is_rejected(self):
        item = output()
        item["modes"][0]["current"] = False
        with self.assertRaises(ValueError):
            WRAPPER["panel_height"](item)

    def test_selects_leftmost_enabled_output(self):
        right = output("DP-2", x=1920)
        left = output()
        self.assertIs(WRAPPER["select_output"]([right, left]), left)

    def test_explicit_output_wins(self):
        right = output("DP-2", x=1920)
        self.assertIs(WRAPPER["select_output"]([output(), right], "DP-2"), right)

    def test_missing_output_is_not_silently_substituted(self):
        with self.assertRaises(ValueError):
            WRAPPER["select_output"]([output()], "HDMI-A-1")

    def test_disabled_output_is_not_selected(self):
        item = output()
        item["enabled"] = False
        with self.assertRaises(ValueError):
            WRAPPER["select_output"]([item])


if __name__ == "__main__":
    unittest.main()
