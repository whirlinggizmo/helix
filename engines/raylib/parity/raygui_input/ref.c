// raygui 4.5-dev's controls over three frames of played input, drawn by raylib 5.5 and raygui's C, the third frame saved as ref.png; Main.hx
// draws the same with helix-raylib. Frame 0 turns the wheel over the list view and types 'H'; frame 1 presses on a list item and types
// 'i'; frame 2 holds the button down on the color panel and types '!'.
#include "raylib.h"

// The characters typed, one a frame, as raygui reads them.
static int typed = 0;
static int TypedChar(void) { int c = typed; typed = 0; return c; }
#define GetCharPressed() TypedChar()
#define RAYGUI_IMPLEMENTATION
#include "raygui.h"

#define R(x, y, w, h) ((Rectangle){ (float)(x), (float)(y), (float)(w), (float)(h) })

// raylib's automation event types (rcore.c), which raylib.h doesn't name.
enum { MOUSE_BUTTON_UP_EVENT = 5, MOUSE_BUTTON_DOWN_EVENT = 6, MOUSE_POSITION = 7, MOUSE_WHEEL = 8 };

static void Play(int type, int a, int b) {
    AutomationEvent e = { 0 };
    e.type = type;
    e.params[0] = a;
    e.params[1] = b;
    PlayAutomationEvent(e);
}

int main(void) {
    SetTraceLogLevel(LOG_WARNING);
    InitWindow(960, 600, "raygui input");
    int listScroll = 0, listActive = -1, tab = 1, drop = 1, valueBox = 25;
    char text[32] = "Edit";
    char input[64] = "secret";
    bool secret = false;
    Color color = { 40, 160, 90, 255 };
    Vector3 hsv = { 200, 0.5f, 0.8f };
    float alpha = 0.6f;
    Vector2 scroll = { -50, -30 }, cell = { 0 };
    Rectangle view = { 0 };
    const char *tabs[] = { "One", "Two", "Three" };
    for (int frame = 0; frame < 3; frame++) {
        BeginDrawing();
        if (frame == 0) { Play(MOUSE_POSITION, 400, 120); Play(MOUSE_WHEEL, 0, -2); typed = 'H'; }
        if (frame == 1) { Play(MOUSE_POSITION, 400, 100); Play(MOUSE_BUTTON_DOWN_EVENT, 0, 0); typed = 'i'; }
        if (frame == 2) { Play(MOUSE_POSITION, 830, 60); typed = '!'; }
        ClearBackground(GetColor(GuiGetStyle(DEFAULT, BACKGROUND_COLOR)));
        GuiWindowBox(R(20, 20, 300, 200), "#198#Window box");
        GuiGroupBox(R(30, 70, 280, 50), "Group");
        GuiLabel(R(40, 80, 260, 30), "Line one\nLine two");
        GuiPanel(R(30, 130, 280, 80), "Panel");
        GuiListView(R(340, 20, 160, 200), "Zero;One;Two;Three;Four;Five;Six;Seven;Eight;Nine;Ten;Eleven", &listScroll, &listActive);
        GuiTextBox(R(340, 380, 160, 24), text, 32, true);
        GuiValueBox(R(380, 410, 120, 24), "Value", &valueBox, 0, 100, true);
        GuiScrollPanel(R(20, 240, 300, 160), "Scroll panel", R(0, 0, 500, 400), &scroll, &view);
        GuiGrid(R(340, 240, 160, 120), NULL, 40, 4, &cell);
        GuiTabBar(R(20, 450, 600, 24), tabs, 3, &tab);
        GuiMessageBox(R(520, 60, 240, 140), "#191#Message", "Hello raygui", "Ok;Cancel");
        GuiTextInputBox(R(520, 220, 240, 160), "Input", "Your name:", "Ok;Cancel", input, 64, &secret);
        GuiSetAlpha(0.5f);
        GuiButton(R(20, 530, 120, 30), "Half alpha");
        GuiSetAlpha(1.0f);
        GuiEnableTooltip();
        GuiSetTooltip("A tooltip");
        GuiSetState(STATE_FOCUSED);
        GuiButton(R(160, 530, 120, 30), "Tooltip");
        GuiSetState(STATE_NORMAL);
        GuiDisableTooltip();
        GuiColorBarAlpha(R(780, 170, 160, 16), NULL, &alpha);
        GuiColorPickerHSV(R(780, 200, 120, 120), NULL, &hsv);
        GuiColorPicker(R(780, 20, 120, 140), NULL, &color);
        DrawRectangle(780, 330, 40, 40, color);
        for (int i = 0; i < 16; i++) GuiDrawIcon(i + 1, 20 + i*36, 490, 2, DARKGRAY);
        GuiSetStyle(DEFAULT, TEXT_WRAP_MODE, TEXT_WRAP_WORD);
        GuiSetStyle(DEFAULT, TEXT_ALIGNMENT_VERTICAL, TEXT_ALIGN_TOP);
        GuiLabel(R(300, 520, 140, 60), "Words wrapped at the label's edge, as raygui wraps them");
        GuiSetStyle(DEFAULT, TEXT_WRAP_MODE, TEXT_WRAP_NONE);
        GuiSetStyle(DEFAULT, TEXT_ALIGNMENT_VERTICAL, TEXT_ALIGN_MIDDLE);
        GuiSetIconScale(2);
        GuiButton(R(460, 530, 140, 40), GuiIconText(ICON_HEART, "Scaled"));
        GuiSetIconScale(1);
        GuiLabel(R(620, 530, 100, 20), "A label too long for its bounds");
        GuiDropdownBox(R(780, 440, 140, 24), "One;Two;Three;Four", &drop, true);
        rlDrawRenderBatchActive();
        if (frame == 2) ExportImage(LoadImageFromScreen(), "ref.png");
        EndDrawing();
    }
    CloseWindow();
    return 0;
}
