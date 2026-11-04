// raygui 4.5-dev's controls in each state, drawn by raylib 5.5 and raygui's C, its third frame saved as ref.png; Main.hx draws the same with
// helix-raylib. The mouse is played off the window each frame, so only the state set with GuiSetState shows.
#include "raylib.h"
#define RAYGUI_IMPLEMENTATION
#include "raygui.h"

#define R(x, y, w, h) ((Rectangle){ (float)(x), (float)(y), (float)(w), (float)(h) })

// raylib's automation event types (rcore.c), which raylib.h doesn't name.
enum { MOUSE_POSITION = 7 };

static void Play(int type, int a, int b) {
    AutomationEvent e = { 0 };
    e.type = type;
    e.params[0] = a;
    e.params[1] = b;
    PlayAutomationEvent(e);
}

static void Toggle(Rectangle r, const char *t, bool v) { GuiToggle(r, t, &v); }
static void CheckBox(Rectangle r, const char *t, bool v) { GuiCheckBox(r, t, &v); }
static void ComboBox(Rectangle r, const char *t, int v) { GuiComboBox(r, t, &v); }
static void DropdownBox(Rectangle r, const char *t, int v) { GuiDropdownBox(r, t, &v, false); }
static void Slider(Rectangle r, const char *a, const char *b, float v) { GuiSlider(r, a, b, &v, 0, 100); }
static void SliderBar(Rectangle r, const char *a, const char *b, float v) { GuiSliderBar(r, a, b, &v, 0, 100); }
static void ProgressBar(Rectangle r, const char *a, const char *b, float v) { GuiProgressBar(r, a, b, &v, 0, 100); }
static void Spinner(Rectangle r, const char *t, int v) { GuiSpinner(r, t, &v, 0, 10, false); }
static void ValueBox(Rectangle r, const char *t, int v) { GuiValueBox(r, t, &v, 0, 100, false); }
static void TextBox(Rectangle r, const char *t) { char b[64]; TextCopy(b, t); GuiTextBox(r, b, 64, false); }
static void ToggleGroup(Rectangle r, const char *t, int v) { GuiToggleGroup(r, t, &v); }
static void ToggleSlider(Rectangle r, const char *t, int v) { GuiToggleSlider(r, t, &v); }

static void Column(int x, int state) {
    GuiSetState(state);
    GuiButton(R(x, 20, 200, 30), "#05#Button");
    Toggle(R(x, 60, 95, 30), "Off", false);
    Toggle(R(x + 105, 60, 95, 30), "On", true);
    CheckBox(R(x, 100, 20, 20), "Checked", true);
    CheckBox(R(x + 110, 100, 20, 20), "Not", false);
    ComboBox(R(x, 130, 200, 24), "One;Two;Three", 1);
    DropdownBox(R(x, 160, 200, 24), "Alpha;Beta;Gamma", 2);
    Slider(R(x + 40, 195, 120, 16), "Min", "Max", 40);
    SliderBar(R(x + 40, 220, 120, 16), "0", "100", 70);
    ProgressBar(R(x + 40, 245, 120, 16), "P", "55%", 55);
    Spinner(R(x + 40, 270, 120, 24), "Spin", 7);
    ValueBox(R(x + 40, 300, 120, 24), "Val", 42);
    TextBox(R(x, 330, 200, 24), "Text box");
    ToggleGroup(R(x, 360, 64, 24), "A;B;C", 1);
    ToggleSlider(R(x, 390, 200, 24), "Off;On", 1);
    GuiLabel(R(x, 420, 200, 20), "#191#Label text");
    GuiLabelButton(R(x, 440, 200, 20), "Label button");
    GuiStatusBar(R(x, 465, 200, 22), "Status bar");
    GuiDummyRec(R(x, 492, 200, 30), "Dummy");
    GuiLine(R(x, 525, 200, 12), "Line");
    GuiLine(R(x, 540, 200, 12), NULL);
    GuiSetState(STATE_NORMAL);
}

int main(void) {
    SetTraceLogLevel(LOG_WARNING);
    InitWindow(960, 560, "raygui");
    for (int frame = 0; frame < 3; frame++) {
        BeginDrawing();
        Play(MOUSE_POSITION, -100, -100);
        ClearBackground(GetColor(GuiGetStyle(DEFAULT, BACKGROUND_COLOR)));
        Column(20, STATE_NORMAL);
        Column(255, STATE_FOCUSED);
        Column(490, STATE_PRESSED);
        Column(725, STATE_DISABLED);
        rlDrawRenderBatchActive();
        if (frame == 2) ExportImage(LoadImageFromScreen(), "ref.png");
        EndDrawing();
    }
    CloseWindow();
    return 0;
}
