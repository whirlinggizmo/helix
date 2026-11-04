// raygui 4.5-dev's results and the values its controls change, over frames of scripted mouse input, and the vertices a few controls
// batch, printed by raygui's C built against raylib 5.5; RayguiBits.hx prints helix-raylib's alike. The mouse is raygui's input functions
// read from the script below, as RayguiBits.hx plays it into helix-raylib's automation state.
#include "parity.h"

static Vector2 mouse = { -100, -100 };
static bool down = false, wasDown = false;
static float wheel = 0;
#define GetMousePosition() (mouse)
#define IsMouseButtonDown(b) ((b) == 0 && down)
#define IsMouseButtonPressed(b) ((b) == 0 && down && !wasDown)
#define IsMouseButtonReleased(b) ((b) == 0 && !down && wasDown)
#define GetMouseWheelMove() (wheel)
#define IsKeyDown(k) (false)
#define IsKeyPressed(k) (false)
#define RAYGUI_IMPLEMENTATION
#include "raygui.h"

// A frame of input: the mouse at x, y, its left button down or up, the wheel turned by w.
static void F(float x, float y, bool d, float w) { wasDown = down; down = d; mouse = (Vector2){ x, y }; wheel = w; }
static void I(const char *name, int v) { printf("%s int %d\n", name, v); }
static void Dump(const char *name) {
    for (int c = 0; c < 16; c++) {
        printf("%s %d", name, c);
        for (int p = 0; p < 24; p++) printf(" %d", GuiGetStyle(c, p));
        printf("\n");
    }
}

int main(void) {
    parity_open();
    parity_depth = false;
    GuiLoadStyleDefault();
    for (int c = 0; c < 16; c++) {
        printf("style %d", c);
        for (int p = 0; p < 24; p++) printf(" %d", GuiGetStyle(c, p));
        printf("\n");
    }
    GuiSetStyle(DEFAULT, BORDER_WIDTH, 3);
    I("propagated", GuiGetStyle(SLIDER, BORDER_WIDTH));
    GuiSetStyle(DEFAULT, TEXT_SIZE, 12);
    I("extended", GuiGetStyle(SLIDER, TEXT_SIZE));
    GuiLoadStyleDefault();
    I("reloaded", GuiGetStyle(SLIDER, BORDER_WIDTH));
    str("icontext", GuiIconText(5, "Open"));
    str("iconalone", GuiIconText(123, NULL));
    str("iconnegative", GuiIconText(-1, NULL));
    unsigned int *icons = GuiGetIcons();
    long long sum = 0;
    for (int i = 0; i < 2048; i++) sum += icons[i];
    printf("icons sum %lld %u %u\n", sum, icons[8], icons[2047]);
    GuiLock(); I("locked", GuiIsLocked()); GuiUnlock(); I("unlocked", GuiIsLocked());
    GuiDisable(); I("disabled", GuiGetState()); GuiEnable(); I("enabled", GuiGetState());
    shape("start");

    Rectangle b = R(10, 10, 100, 30);
    F(50, 20, false, 0); I("button.hover", GuiButton(b, "Ok"));
    F(50, 20, true, 0); I("button.down", GuiButton(b, "Ok"));
    F(50, 20, false, 0); I("button.released", GuiButton(b, "Ok"));
    F(200, 20, true, 0); F(200, 20, false, 0); I("button.away", GuiButton(b, "Ok"));
    shape("button");

    bool on = false;
    F(50, 20, true, 0); GuiToggle(b, "T", &on); F(50, 20, false, 0); GuiToggle(b, "T", &on); I("toggle", on);
    bool checked = false;
    F(15, 15, true, 0); GuiCheckBox(R(10, 10, 12, 12), "Check", &checked);
    F(40, 15, false, 0); I("checkbox.result", GuiCheckBox(R(10, 10, 12, 12), "Check", &checked)); I("checkbox", checked);
    int combo = 1;
    F(50, 20, true, 0); GuiComboBox(b, "A;B;C", &combo); I("combo", combo);
    F(50, 20, false, 0); F(50, 20, true, 0); GuiComboBox(b, "A;B;C", &combo); I("combo.wrapped", combo);
    int drop = 0;
    F(50, 20, false, 0); F(50, 20, true, 0); I("dropdown.open", GuiDropdownBox(b, "A;B;C", &drop, false));
    F(50, 85, true, 0); GuiDropdownBox(b, "A;B;C", &drop, true);
    F(50, 85, false, 0); I("dropdown.chosen", GuiDropdownBox(b, "A;B;C", &drop, true)); I("dropdown", drop);
    shape("choices");

    int group = 0;
    F(10, 10, false, 0); F(160, 20, true, 0); F(160, 20, false, 0); GuiToggleGroup(R(10, 10, 60, 20), "A;B;C\nD;E", &group); I("group", group);
    F(40, 40, true, 0); F(40, 40, false, 0); GuiToggleGroup(R(10, 10, 60, 20), "A;B;C\nD;E", &group); I("group.row", group);
    int slide = 0;
    F(50, 20, true, 0); F(50, 20, false, 0); I("toggleslider.result", GuiToggleSlider(b, "Off;On;Auto", &slide)); I("toggleslider", slide);
    shape("toggles");

    float value = 0;
    Rectangle s = R(20, 50, 200, 20);
    F(120, 60, true, 0); I("slider.result", GuiSlider(s, "L", "R", &value, 0, 10)); num("slider", value);
    F(300, 60, true, 0); GuiSlider(s, "L", "R", &value, 0, 10); num("slider.dragged", value);
    F(77.5f, 60, true, 0); GuiSlider(s, "L", "R", &value, 0, 10); num("slider.back", value);
    F(77.5f, 60, false, 0); GuiSlider(s, "L", "R", &value, 0, 10); num("slider.released", value);
    float bar = 0;
    F(90, 60, true, 0); GuiSliderBar(s, NULL, NULL, &bar, -5, 5); num("sliderbar", bar);
    F(90, 60, false, 0); GuiSliderBar(s, NULL, NULL, &bar, -5, 5);
    float progress = 150;
    GuiProgressBar(s, NULL, NULL, &progress, 0, 100); num("progress", progress);
    shape("sliders");

    int spin = 5;
    F(205, 60, true, 0); GuiSpinner(s, NULL, &spin, 0, 6, false); F(205, 60, false, 0); GuiSpinner(s, NULL, &spin, 0, 6, false); I("spinner", spin);
    F(205, 60, true, 0); GuiSpinner(s, NULL, &spin, 0, 6, false); F(205, 60, false, 0); GuiSpinner(s, NULL, &spin, 0, 6, false); I("spinner.held", spin);
    int box = 500;
    F(0, 0, false, 0); GuiValueBox(s, "V", &box, 0, 100, false); I("valuebox", box);
    F(50, 60, true, 0); I("valuebox.click", GuiValueBox(s, "V", &box, 0, 100, false));
    shape("numbers");

    int scrollIndex = 0, active = -1, focus = -1;
    const char *items[] = { "a", "b", "c", "d", "e", "f", "g", "h", "i", "j" };
    Rectangle l = R(10, 10, 100, 100);
    F(50, 30, false, -3); GuiListViewEx(l, items, 10, &scrollIndex, &active, &focus); I("list.scroll", scrollIndex); I("list.focus", focus);
    F(50, 30, true, 0); GuiListViewEx(l, items, 10, &scrollIndex, &active, &focus); I("list.active", active);
    F(50, 30, false, 0); F(50, 30, true, 0); GuiListViewEx(l, items, 10, &scrollIndex, &active, &focus); I("list.unchosen", active);
    F(105, 100, false, 0); F(105, 100, true, 0); GuiListView(l, "x;y;z;w;v;u", &scrollIndex, &active); I("list.bar", scrollIndex);
    F(105, 100, false, 0);
    shape("list");

    Vector2 scroll = { 0, 0 }, cell = { 0 };
    Rectangle view = { 0 };
    F(50, 50, false, -1); GuiScrollPanel(R(10, 10, 150, 120), "Panel", R(0, 0, 400, 300), &scroll, &view); vec2("scroll", scroll); rect("view", view);
    F(50, 50, false, 2); GuiScrollPanel(R(10, 10, 150, 120), NULL, R(0, 0, 400, 300), &scroll, &view); vec2("scroll.up", scroll); rect("view.plain", view);
    F(73, 58, false, 0); GuiGrid(R(10, 10, 200, 100), NULL, 20, 2, &cell); vec2("grid.cell", cell);
    F(500, 58, false, 0); GuiGrid(R(10, 10, 200, 100), NULL, 20, 2, &cell); vec2("grid.outside", cell);
    shape("panels");

    Color col = { 200, 50, 50, 255 };
    Rectangle p = R(10, 10, 100, 100);
    F(30, 40, true, 0); GuiColorPanel(p, NULL, &col); color("colorpanel", col);
    F(80, 90, true, 0); GuiColorPanel(p, NULL, &col); color("colorpanel.drag", col);
    F(80, 90, false, 0); GuiColorPanel(p, NULL, &col);
    float hue = 0;
    F(15, 70, true, 0); GuiColorBarHue(R(10, 10, 20, 120), NULL, &hue); num("hue", hue);
    F(15, 300, true, 0); GuiColorBarHue(R(10, 10, 20, 120), NULL, &hue); num("hue.below", hue);
    F(15, 300, false, 0); GuiColorBarHue(R(10, 10, 20, 120), NULL, &hue);
    float alpha = 1;
    F(47, 15, true, 0); GuiColorBarAlpha(R(10, 10, 120, 16), NULL, &alpha); num("alpha", alpha);
    F(47, 15, false, 0); GuiColorBarAlpha(R(10, 10, 120, 16), NULL, &alpha);
    Color pick = { 10, 120, 240, 255 };
    F(500, 500, false, 0); GuiColorPicker(p, NULL, &pick); color("picker.idle", pick);
    F(120, 40, true, 0); GuiColorPicker(p, NULL, &pick); color("picker.hue", pick);
    F(120, 40, false, 0); GuiColorPicker(p, NULL, &pick);
    Vector3 hsv = { 120, 0.5f, 0.5f };
    F(60, 30, true, 0); GuiColorPickerHSV(p, NULL, &hsv); printf("hsv vec3 %.9g %.9g %.9g\n", hsv.x, hsv.y, hsv.z);
    F(60, 30, false, 0); GuiColorPickerHSV(p, NULL, &hsv);
    shape("colors");

    Rectangle m = R(10, 10, 250, 150);
    F(50, 140, false, 0); F(50, 140, true, 0); GuiMessageBox(m, "Title", "Message", "Yes;No"); F(50, 140, false, 0);
    I("message.yes", GuiMessageBox(m, "Title", "Message", "Yes;No"));
    F(245, 20, true, 0); GuiMessageBox(m, "Title", "Message", "Yes;No"); F(245, 20, false, 0);
    I("message.close", GuiMessageBox(m, "Title", "Message", "Yes;No"));
    F(500, 500, false, 0);
    I("labelbutton", GuiLabelButton(R(10, 10, 5, 10), "A long label"));
    GuiLabel(R(10, 10, 60, 30), "#12#Cut text that runs on\nand a second line");
    GuiSetStyle(DEFAULT, TEXT_WRAP_MODE, TEXT_WRAP_CHAR);
    GuiLabel(R(10, 10, 60, 60), "Wrapped by character at the edge");
    GuiSetStyle(DEFAULT, TEXT_WRAP_MODE, TEXT_WRAP_NONE);
    shape("text");

    // Style and icon files.
    GuiLoadStyle("web/style.rgs");
    Dump("textstyle");
    I("textstyle.font", GuiGetFont().texture.id == GetFontDefault().texture.id);
    GuiLoadStyle("web/dark.rgs");
    Dump("binarystyle");
    char **names = GuiLoadIcons("web/icons.rgi", true);
    str("icon.name0", names[0]);
    str("icon.name1", names[1]);
    printf("icons loaded");
    for (int i = 0; i < 18; i++) printf(" %u", GuiGetIcons()[i]);
    printf("\n");
    I("icons.unnamed", GuiLoadIcons("web/icons.rgi", false) == NULL);
    GuiLoadStyle("web/none.rgs");
    Dump("nostyle");
    parity_close();
    return 0;
}
