package helix.raylib.modules;

#if !macro
import helix.raylib.*;
import helix.raylib.Raylib.*;
import helix.raylib.modules.RCore.*;
import helix.raylib.modules.RShapes.*;
import helix.raylib.modules.RTextures.*;
import helix.raylib.modules.RText.*;
import helix.raylib.Raygui.*;
import helix.raylib.modules.RGui.*;
import helix.raylib.modules.RGuiControls.*;
#end

/** Provides raygui's controls, as raylib 5.5's raygui (4.5-dev, `raygui.h`) draws them and reads the mouse and keys for them.

	`Raygui` forwards to each (`tools/gen_raylib.py`).

	A control is drawn when it is called, each frame, between `BeginDrawing` and `EndDrawing`.

	A value a control changes is passed in a one-element array (`[false]`, `[0]`, `[0.5]`), or as a struct the control changes in
	place (`Vector2`, `Rectangle`, `Color`, `Vector3`).

	Text a control edits is passed as `[text]`. */
@:noCompletion
@:allow(helix.raylib)
class RGuiControls {
	#if !macro
	// ---- Container controls ----

	/** Draws a window, a title bar with a close button over a panel, and returns 1 when the close button is clicked. See `GuiPanel`
		for drawing a panel with no close button.

		@param bounds  The window, its title bar 24 pixels high; it is at least 48.
		@param title  The title, or null.
		@return  1 when the close button is clicked, else 0. */
	static function GuiWindowBox(bounds:Rectangle, title:String):Int {
		var statusBar = new Rectangle(bounds.x, bounds.y, bounds.width, STATUSBAR_HEIGHT);
		var height = bounds.height < STATUSBAR_HEIGHT * 2.?STATUSBAR_HEIGHT * 2.
		:bounds.height;
		var windowPanel = new Rectangle(bounds.x, bounds.y + STATUSBAR_HEIGHT - 1, bounds.width, height - STATUSBAR_HEIGHT + 1);
		var closeButton = new Rectangle(statusBar.x + statusBar.width - GuiGetStyle(STATUSBAR, BORDER_WIDTH) - 20,
			statusBar.y + STATUSBAR_HEIGHT / 2. - 18. / 2, 18, 18);
		GuiStatusBar(statusBar, title);
		GuiPanel(windowPanel, null);
		var tempBorderWidth = GuiGetStyle(BUTTON, BORDER_WIDTH),
			tempTextAlignment = GuiGetStyle(BUTTON, TEXT_ALIGNMENT);
		GuiSetStyle(BUTTON, BORDER_WIDTH, 1);
		GuiSetStyle(BUTTON, TEXT_ALIGNMENT, TEXT_ALIGN_CENTER);
		var result = GuiButton(closeButton, GuiIconText(ICON_CROSS_SMALL, null));
		GuiSetStyle(BUTTON, BORDER_WIDTH, tempBorderWidth);
		GuiSetStyle(BUTTON, TEXT_ALIGNMENT, tempTextAlignment);
		return result;
	}

	/** Draws a group box, a frame with its name in its top line.

		@param bounds  The box.
		@param text  Its name, or null.
		@return  0. */
	static function GuiGroupBox(bounds:Rectangle, text:String):Int {
		var color = styleColor(DEFAULT, guiState == STATE_DISABLED ? BORDER_COLOR_DISABLED : LINE_COLOR);
		drawRectangle(new Rectangle(bounds.x, bounds.y, GROUPBOX_LINE_THICK, bounds.height), 0, BLANK, color);
		drawRectangle(new Rectangle(bounds.x, bounds.y + bounds.height - 1, bounds.width, GROUPBOX_LINE_THICK), 0, BLANK, color);
		drawRectangle(new Rectangle(bounds.x + bounds.width - 1, bounds.y, GROUPBOX_LINE_THICK, bounds.height), 0, BLANK, color);
		GuiLine(new Rectangle(bounds.x, bounds.y - idiv(GuiGetStyle(DEFAULT, TEXT_SIZE), 2), bounds.width, GuiGetStyle(DEFAULT, TEXT_SIZE)), text);
		return 0;
	}

	/** Draws a line across its bounds' middle, with the text in it when provided ("--- text ------").

		@param bounds  The line's bounds.
		@param text  The text, or null for a plain line.
		@return  0. */
	static function GuiLine(bounds:Rectangle, text:String):Int {
		var color = styleColor(DEFAULT, guiState == STATE_DISABLED ? BORDER_COLOR_DISABLED : LINE_COLOR);
		if (text == null)
			drawRectangle(new Rectangle(bounds.x, bounds.y + bounds.height / 2, bounds.width, 1), 0, BLANK, color);
		else {
			var textBounds = new Rectangle(bounds.x + LINE_MARGIN_TEXT, bounds.y, stringWidth(text) + 2, bounds.height);
			drawRectangle(new Rectangle(bounds.x, bounds.y + bounds.height / 2, LINE_MARGIN_TEXT - LINE_TEXT_PADDING, 1), 0, BLANK, color);
			drawText(text, textBounds, TEXT_ALIGN_LEFT, color);
			drawRectangle(new Rectangle(bounds.x
				+ 12
				+ textBounds.width
				+ 4, bounds.y
				+ bounds.height / 2,
				bounds.width
				- textBounds.width
				- LINE_MARGIN_TEXT
				- LINE_TEXT_PADDING, 1),
				0, BLANK, color);
		}
		return 0;
	}

	/** Draws a panel, with a header bar when the text is provided. See `GuiScrollPanel` for showing content larger than the panel.

		@param bounds  The panel; with a header it is at least 48 pixels high.
		@param text  The header's text, or null for none.
		@return  0. */
	static function GuiPanel(bounds:Rectangle, text:String):Int {
		var state = guiState;
		var panel = new Rectangle(bounds.x, bounds.y, bounds.width, bounds.height);
		var statusBar = new Rectangle(bounds.x, bounds.y, bounds.width, STATUSBAR_HEIGHT);
		if (text != null && panel.height < STATUSBAR_HEIGHT * 2.)
			panel.height = STATUSBAR_HEIGHT * 2.;
		if (text != null) {
			panel.y += STATUSBAR_HEIGHT - 1;
			panel.height -= STATUSBAR_HEIGHT - 1;
			GuiStatusBar(statusBar, text);
		}
		drawRectangle(panel, PANEL_BORDER_WIDTH, styleColor(DEFAULT, state == STATE_DISABLED ? BORDER_COLOR_DISABLED : LINE_COLOR),
			styleColor(DEFAULT, state == STATE_DISABLED ? BASE_COLOR_DISABLED : BACKGROUND_COLOR));
		return 0;
	}

	/** Draws a bar of tabs and returns the tab whose close button is clicked or that the middle button presses.

		Each tab is a toggle 160 pixels wide with a close button.

		A click on a tab makes it the active tab.

		Scrolls the bar so the active tab shows.

		@param bounds  The bar; its height is the tabs'.
		@param text  The tabs' names.
		@param count  How many tabs.
		@param active  The active tab, in `active[0]`, clamped to the tabs.
		@return  The tab whose close button was clicked or that the middle button pressed, else -1. */
	static function GuiTabBar(bounds:Rectangle, text:Array<String>, count:Int, active:Array<Int>):Int {
		var result = -1;
		var tab = new Rectangle(bounds.x, bounds.y, TABBAR_ITEM_WIDTH, bounds.height);
		if (active[0] < 0)
			active[0] = 0;
		else if (active[0] > count - 1)
			active[0] = count - 1;
		var offsetX = (active[0] + 2) * TABBAR_ITEM_WIDTH - GetScreenWidth();
		if (offsetX < 0)
			offsetX = 0;
		var toggle = [false];
		for (i in 0...count) {
			tab.x = bounds.x + (TABBAR_ITEM_WIDTH + 4) * i - offsetX;
			if (tab.x < GetScreenWidth()) {
				var textAlignment = GuiGetStyle(TOGGLE, TEXT_ALIGNMENT),
					textPadding = GuiGetStyle(TOGGLE, TEXT_PADDING);
				GuiSetStyle(TOGGLE, TEXT_ALIGNMENT, TEXT_ALIGN_LEFT);
				GuiSetStyle(TOGGLE, TEXT_PADDING, 8);
				if (i == active[0]) {
					toggle[0] = true;
					GuiToggle(tab, GuiIconText(12, text[i]), toggle);
				} else {
					toggle[0] = false;
					GuiToggle(tab, GuiIconText(12, text[i]), toggle);
					if (toggle[0])
						active[0] = i;
				}
				if (CheckCollisionPointRec(GetMousePosition(), tab) && IsMouseButtonPressed(MOUSE_BUTTON_MIDDLE))
					result = i;
				GuiSetStyle(TOGGLE, TEXT_PADDING, textPadding);
				GuiSetStyle(TOGGLE, TEXT_ALIGNMENT, textAlignment);
				var tempBorderWidth = GuiGetStyle(BUTTON, BORDER_WIDTH),
					tempTextAlignment = GuiGetStyle(BUTTON, TEXT_ALIGNMENT);
				GuiSetStyle(BUTTON, BORDER_WIDTH, 1);
				GuiSetStyle(BUTTON, TEXT_ALIGNMENT, TEXT_ALIGN_CENTER);
				if (GuiButton(new Rectangle(tab.x + tab.width - 14 - 5, tab.y + 5, 14, 14), GuiIconText(ICON_CROSS_SMALL, null)) != 0)
					result = i;
				GuiSetStyle(BUTTON, BORDER_WIDTH, tempBorderWidth);
				GuiSetStyle(BUTTON, TEXT_ALIGNMENT, tempTextAlignment);
			}
		}
		drawRectangle(new Rectangle(bounds.x, bounds.y + bounds.height - 1, bounds.width, 1), 0, BLANK, styleColor(TOGGLE, BORDER_COLOR_NORMAL));
		return result;
	}

	/** Draws a scroll panel, a view of content larger than the panel, with scroll bars where the content is wider or taller. See
		`GuiPanel` for drawing a panel with no scrolling.

		The bars and the mouse wheel scroll the content, across while Shift or Control is held.

		@param bounds  The panel; with a header it is at least 48 pixels high.
		@param text  The header's text, or null for none.
		@param content  The content's size (its x and y aren't read).
		@param scroll  The content's offset, changed as it scrolls (0 to minus how much is hidden), or null.
		@param view  Receives the area the content shows in, inside the bars, or null.
		@return  0. */
	static function GuiScrollPanel(bounds:Rectangle, text:String, content:Rectangle, scroll:Vector2, view:Rectangle):Int {
		var state = guiState;
		var b = new Rectangle(bounds.x, bounds.y, bounds.width, bounds.height);
		if (view == null)
			view = new Rectangle();
		var scrollPos = scroll == null ? new Vector2() : new Vector2(scroll.x, scroll.y);
		var statusBar = new Rectangle(b.x, b.y, b.width, STATUSBAR_HEIGHT);
		if (b.height < STATUSBAR_HEIGHT * 2.)
			b.height = STATUSBAR_HEIGHT * 2.;
		if (text != null) {
			b.y += STATUSBAR_HEIGHT - 1;
			b.height -= STATUSBAR_HEIGHT + 1;
		}
		var border = GuiGetStyle(DEFAULT, BORDER_WIDTH),
			barWidth = GuiGetStyle(LISTVIEW, SCROLLBAR_WIDTH);
		var leftSide = GuiGetStyle(LISTVIEW, SCROLLBAR_SIDE) == SCROLLBAR_LEFT_SIDE;
		var hasHorizontal = content.width > b.width - 2 * border;
		var hasVertical = content.height > b.height - 2 * border;
		if (!hasHorizontal)
			hasHorizontal = hasVertical && content.width > b.width - 2 * border - barWidth;
		if (!hasVertical)
			hasVertical = hasHorizontal && content.height > b.height - 2 * border - barWidth;
		var horizontalWidth = hasHorizontal ? barWidth : 0;
		var verticalWidth = hasVertical ? barWidth : 0;
		var horizontalBar = new Rectangle((leftSide ? b.x + verticalWidth : b.x)
			+ border, b.y
			+ b.height
			- horizontalWidth
			- border,
			b.width
			- verticalWidth
			- 2 * border, horizontalWidth);
		var verticalBar = new Rectangle(leftSide ? b.x + border : b.x + b.width - verticalWidth - border, b.y
			+ border, verticalWidth,
			b.height
			- horizontalWidth
			- 2 * border);
		if (horizontalBar.width < MIN_SCROLLBAR_WIDTH)
			horizontalBar.width = MIN_SCROLLBAR_WIDTH;
		if (verticalBar.height < MIN_SCROLLBAR_HEIGHT)
			verticalBar.height = MIN_SCROLLBAR_HEIGHT;
		view.x = leftSide ? b.x + verticalWidth + border : b.x + border;
		view.y = b.y + border;
		view.width = b.width - 2 * border - verticalWidth;
		view.height = b.height - 2 * border - horizontalWidth;
		if (view.width > content.width)
			view.width = content.width;
		if (view.height > content.height)
			view.height = content.height;
		var horizontalMin = (leftSide ? -verticalWidth : 0.) - border;
		var horizontalMax = hasHorizontal ? content.width - b.width + verticalWidth + border - (leftSide ? verticalWidth : 0.) : -border;
		var verticalMin = hasVertical ? 0. : -1.;
		var verticalMax = hasVertical ? content.height - b.height + horizontalWidth + border : -border;
		if (state != STATE_DISABLED && !guiLocked) {
			var mousePoint = GetMousePosition();
			if (CheckCollisionPointRec(mousePoint, b)) {
				state = IsMouseButtonDown(MOUSE_BUTTON_LEFT) ? STATE_PRESSED : STATE_FOCUSED;
				var wheelMove = GetMouseWheelMove();
				var speedX = content.width / b.width,
					speedY = content.height / b.height;
				if (speedX < MIN_MOUSE_WHEEL_SPEED)
					speedX = MIN_MOUSE_WHEEL_SPEED;
				if (speedY < MIN_MOUSE_WHEEL_SPEED)
					speedY = MIN_MOUSE_WHEEL_SPEED;
				if (hasHorizontal && (IsKeyDown(KEY_LEFT_CONTROL) || IsKeyDown(KEY_LEFT_SHIFT)))
					scrollPos.x += wheelMove * speedX;
				else
					scrollPos.y += wheelMove * speedY;
			}
		}
		if (scrollPos.x > -horizontalMin)
			scrollPos.x = -horizontalMin;
		if (scrollPos.x < -horizontalMax)
			scrollPos.x = -horizontalMax;
		if (scrollPos.y > -verticalMin)
			scrollPos.y = -verticalMin;
		if (scrollPos.y < -verticalMax)
			scrollPos.y = -verticalMax;
		if (text != null)
			GuiStatusBar(statusBar, text);
		drawRectangle(b, 0, BLANK, styleColor(DEFAULT, BACKGROUND_COLOR));
		var slider = GuiGetStyle(SCROLLBAR, SCROLL_SLIDER_SIZE);
		if (hasHorizontal) {
			GuiSetStyle(SCROLLBAR, SCROLL_SLIDER_SIZE,
				Std.int(f32(f32((b.width - 2 * border - verticalWidth) / Std.int(content.width)) * (Std.int(b.width) - 2 * border - verticalWidth))));
			scrollPos.x = -scrollBar(horizontalBar, Std.int(-scrollPos.x), Std.int(horizontalMin), Std.int(horizontalMax));
		} else
			scrollPos.x = 0;
		if (hasVertical) {
			GuiSetStyle(SCROLLBAR, SCROLL_SLIDER_SIZE,
				Std.int(f32(f32((b.height - 2 * border - horizontalWidth) / Std.int(content.height)) * (Std.int(b.height) - 2 * border - horizontalWidth))));
			scrollPos.y = -scrollBar(verticalBar, Std.int(-scrollPos.y), Std.int(verticalMin), Std.int(verticalMax));
		} else
			scrollPos.y = 0;
		if (hasHorizontal && hasVertical) {
			var corner = new Rectangle(leftSide ? b.x + border + 2 : horizontalBar.x + horizontalBar.width + 2, verticalBar.y
				+ verticalBar.height
				+ 2,
				horizontalWidth
				- 4, verticalWidth
				- 4);
			drawRectangle(corner, 0, BLANK, styleColor(LISTVIEW, TEXT + state * 3));
		}
		drawRectangle(b, GuiGetStyle(LISTVIEW, BORDER_WIDTH), styleColor(LISTVIEW, BORDER + state * 3), BLANK);
		GuiSetStyle(SCROLLBAR, SCROLL_SLIDER_SIZE, slider);
		if (scroll != null) {
			scroll.x = scrollPos.x;
			scroll.y = scrollPos.y;
		}
		return 0;
	}

	// ---- Basic controls ----

	/** Draws a label, text in its bounds aligned as the label style sets. See `GuiLabelButton` for drawing a label that takes clicks.

		@param bounds  The label.
		@param text  The text, or null.
		@return  0. */
	static function GuiLabel(bounds:Rectangle, text:String):Int {
		drawText(text, textBounds(LABEL, bounds), GuiGetStyle(LABEL, TEXT_ALIGNMENT), styleColor(LABEL, TEXT + guiState * 3));
		return 0;
	}

	/** Draws a button and returns 1 when the left button is released over it.

		Drawn focused while the mouse is over the button, and pressed while the left button is held there.

		@param bounds  The button.
		@param text  Its text, or null.
		@return  1 when the left button is released over it, else 0. */
	static function GuiButton(bounds:Rectangle, text:String):Int {
		var result = 0, state = guiState;
		if (state != STATE_DISABLED && !guiLocked && !guiControlExclusiveMode) {
			if (CheckCollisionPointRec(GetMousePosition(), bounds)) {
				state = IsMouseButtonDown(MOUSE_BUTTON_LEFT) ? STATE_PRESSED : STATE_FOCUSED;
				if (IsMouseButtonReleased(MOUSE_BUTTON_LEFT))
					result = 1;
			}
		}
		drawRectangle(bounds, GuiGetStyle(BUTTON, BORDER_WIDTH), styleColor(BUTTON, BORDER + state * 3), styleColor(BUTTON, BASE + state * 3));
		drawText(text, textBounds(BUTTON, bounds), GuiGetStyle(BUTTON, TEXT_ALIGNMENT), styleColor(BUTTON, TEXT + state * 3));
		if (state == STATE_FOCUSED)
			tooltip(bounds);
		return result;
	}

	/** Draws a label that works as a button, at least as wide as its text, and returns 1 when the left button is released over it.
		See `GuiButton` for drawing a button.

		@param bounds  The label.
		@param text  Its text, or null.
		@return  1 when the left button is released over it, else 0. */
	static function GuiLabelButton(bounds:Rectangle, text:String):Int {
		var state = guiState, pressed = 0;
		var b = new Rectangle(bounds.x, bounds.y, bounds.width, bounds.height);
		var width = stringWidth(text),
			border = GuiGetStyle(LABEL, BORDER_WIDTH),
			padding = GuiGetStyle(LABEL, TEXT_PADDING);
		if (b.width - 2 * border - 2 * padding < width)
			b.width = width + 2 * border + 2 * padding + 2;
		if (state != STATE_DISABLED && !guiLocked && !guiControlExclusiveMode) {
			if (CheckCollisionPointRec(GetMousePosition(), b)) {
				state = IsMouseButtonDown(MOUSE_BUTTON_LEFT) ? STATE_PRESSED : STATE_FOCUSED;
				if (IsMouseButtonReleased(MOUSE_BUTTON_LEFT))
					pressed = 1;
			}
		}
		drawText(text, textBounds(LABEL, b), GuiGetStyle(LABEL, TEXT_ALIGNMENT), styleColor(LABEL, TEXT + state * 3));
		return pressed;
	}

	/** Draws a toggle button, drawn pressed while on. See `GuiCheckBox` for drawing a check box.

		A click turns the toggle over.

		@param bounds  The button.
		@param text  Its text, or null.
		@param active  Whether it is on, in `active[0]`, or null.
		@return  0. */
	static function GuiToggle(bounds:Rectangle, text:String, active:Array<Bool>):Int {
		var state = guiState;
		if (active == null)
			active = [false];
		if (state != STATE_DISABLED && !guiLocked && !guiControlExclusiveMode) {
			if (CheckCollisionPointRec(GetMousePosition(), bounds)) {
				if (IsMouseButtonDown(MOUSE_BUTTON_LEFT))
					state = STATE_PRESSED;
				else if (IsMouseButtonReleased(MOUSE_BUTTON_LEFT)) {
					state = STATE_NORMAL;
					active[0] = !active[0];
				} else
					state = STATE_FOCUSED;
			}
		}
		if (state == STATE_NORMAL) {
			var on = active[0];
			drawRectangle(bounds, GuiGetStyle(TOGGLE, BORDER_WIDTH), styleColor(TOGGLE, on ? BORDER_COLOR_PRESSED : BORDER + state * 3),
				styleColor(TOGGLE, on ? BASE_COLOR_PRESSED : BASE + state * 3));
			drawText(text, textBounds(TOGGLE, bounds), GuiGetStyle(TOGGLE, TEXT_ALIGNMENT), styleColor(TOGGLE, on ? TEXT_COLOR_PRESSED : TEXT + state * 3));
		} else {
			drawRectangle(bounds, GuiGetStyle(TOGGLE, BORDER_WIDTH), styleColor(TOGGLE, BORDER + state * 3), styleColor(TOGGLE, BASE + state * 3));
			drawText(text, textBounds(TOGGLE, bounds), GuiGetStyle(TOGGLE, TEXT_ALIGNMENT), styleColor(TOGGLE, TEXT + state * 3));
		}
		if (state == STATE_FOCUSED)
			tooltip(bounds);
		return 0;
	}

	/** Draws a group of toggles, one on at a time, a toggle for each of the text's items ("One;Two;Three"). See `GuiToggleSlider` for
		drawing the items under one slider.

		Starts a new row at each '\n'.

		A click on a toggle turns it on and the one that was on off.

		@param bounds  The first toggle; each is this size.
		@param text  The items, split at ';' and '\n'.
		@param active  The item on, in `active[0]`, or null.
		@return  0. */
	static function GuiToggleGroup(bounds:Rectangle, text:String, active:Array<Int>):Int {
		var b = new Rectangle(bounds.x, bounds.y, bounds.width, bounds.height);
		if (active == null)
			active = [0];
		var rows = [0], toggle = [false];
		var items = textSplit(text, ";".code, rows);
		var prevRow = rows[0];
		for (i in 0...items.length) {
			if (prevRow != rows[i]) {
				b.x = bounds.x;
				b.y += b.height + GuiGetStyle(TOGGLE, GROUP_PADDING);
				prevRow = rows[i];
			}
			if (i == active[0]) {
				toggle[0] = true;
				GuiToggle(b, items[i], toggle);
			} else {
				toggle[0] = false;
				GuiToggle(b, items[i], toggle);
				if (toggle[0])
					active[0] = i;
			}
			b.x += b.width + GuiGetStyle(TOGGLE, GROUP_PADDING);
		}
		return 0;
	}

	/** Draws a toggle slider, its items ("Off;On") side by side with the active one under a slider, and returns 1 when clicked. See
		`GuiToggleGroup` for drawing a toggle for each item.

		A click moves the slider to the next item, and from the last back to the first.

		@param bounds  The slider.
		@param text  The items, split at ';'.
		@param active  The active item, in `active[0]`, or null.
		@return  1 when clicked, else 0. */
	static function GuiToggleSlider(bounds:Rectangle, text:String, active:Array<Int>):Int {
		var result = 0, state = guiState;
		if (active == null)
			active = [0];
		var items = textSplit(text, ";".code, null), itemCount = items.length;
		var border = GuiGetStyle(SLIDER, BORDER_WIDTH),
			padding = GuiGetStyle(SLIDER, SLIDER_PADDING);
		var width = f32((bounds.width - 2 * border - (itemCount + 1) * padding) / itemCount);
		var slider = new Rectangle(0, bounds.y + border + padding, width, bounds.height - 2 * border - 2 * padding);
		if (state != STATE_DISABLED && !guiLocked) {
			if (CheckCollisionPointRec(GetMousePosition(), bounds)) {
				if (IsMouseButtonDown(MOUSE_BUTTON_LEFT))
					state = STATE_PRESSED;
				else if (IsMouseButtonReleased(MOUSE_BUTTON_LEFT)) {
					state = STATE_PRESSED;
					active[0]++;
					result = 1;
				} else
					state = STATE_FOCUSED;
			}
			if (active[0] != 0 && state != STATE_FOCUSED)
				state = STATE_PRESSED;
		}
		if (active[0] >= itemCount)
			active[0] = 0;
		slider.x = f32(bounds.x + border + (active[0] + 1) * padding + f32(active[0] * slider.width));
		drawRectangle(bounds, border, styleColor(TOGGLE, BORDER + state * 3), styleColor(TOGGLE, BASE_COLOR_NORMAL));
		if (state == STATE_NORMAL)
			drawRectangle(slider, 0, BLANK, styleColor(SLIDER, BASE_COLOR_PRESSED));
		else if (state == STATE_FOCUSED)
			drawRectangle(slider, 0, BLANK, styleColor(SLIDER, BASE_COLOR_FOCUSED));
		else if (state == STATE_PRESSED)
			drawRectangle(slider, 0, BLANK, styleColor(SLIDER, BASE_COLOR_PRESSED));
		if (text != null) {
			var textWidth = stringWidth(text),
				size = GuiGetStyle(DEFAULT, TEXT_SIZE);
			var x = f32(f32(slider.x + f32(slider.width / 2)) - textWidth / 2.);
			drawText(items[active[0]], new Rectangle(x, bounds.y + bounds.height / 2 - idiv(size, 2), textWidth, size), GuiGetStyle(TOGGLE, TEXT_ALIGNMENT),
				Fade(styleColor(TOGGLE, TEXT + state * 3), guiAlpha));
		}
		return result;
	}

	/** Draws a check box with its text beside it, and returns 1 when clicked. See `GuiToggle` for drawing a toggle button.

		A click on the box or its text turns the check over.

		@param bounds  The box.
		@param text  Its text, or null.
		@param checked  Whether it is checked, in `checked[0]`, or null.
		@return  1 when clicked, else 0. */
	static function GuiCheckBox(bounds:Rectangle, text:String, checked:Array<Bool>):Int {
		var result = 0, state = guiState;
		if (checked == null)
			checked = [false];
		var label = new Rectangle();
		var padding = GuiGetStyle(CHECKBOX, TEXT_PADDING),
			alignLeft = GuiGetStyle(CHECKBOX, TEXT_ALIGNMENT) == TEXT_ALIGN_LEFT;
		if (text != null) {
			label.width = stringWidth(text) + 2;
			label.height = GuiGetStyle(DEFAULT, TEXT_SIZE);
			label.x = bounds.x + bounds.width + padding;
			label.y = bounds.y + bounds.height / 2 - idiv(GuiGetStyle(DEFAULT, TEXT_SIZE), 2);
			if (alignLeft)
				label.x = bounds.x - label.width - padding;
		}
		if (state != STATE_DISABLED && !guiLocked && !guiControlExclusiveMode) {
			var total = new Rectangle(alignLeft ? label.x : bounds.x, bounds.y, bounds.width + label.width + padding, bounds.height);
			if (CheckCollisionPointRec(GetMousePosition(), total)) {
				state = IsMouseButtonDown(MOUSE_BUTTON_LEFT) ? STATE_PRESSED : STATE_FOCUSED;
				if (IsMouseButtonReleased(MOUSE_BUTTON_LEFT)) {
					checked[0] = !checked[0];
					result = 1;
				}
			}
		}
		var border = GuiGetStyle(CHECKBOX, BORDER_WIDTH);
		drawRectangle(bounds, border, styleColor(CHECKBOX, BORDER + state * 3), BLANK);
		if (checked[0]) {
			var inset = border + GuiGetStyle(CHECKBOX, CHECK_PADDING);
			drawRectangle(new Rectangle(bounds.x + inset, bounds.y + inset, bounds.width - 2 * inset, bounds.height - 2 * inset), 0, BLANK,
				styleColor(CHECKBOX, TEXT + state * 3));
		}
		drawText(text, label, GuiGetStyle(CHECKBOX, TEXT_ALIGNMENT) == TEXT_ALIGN_RIGHT ? TEXT_ALIGN_LEFT : TEXT_ALIGN_RIGHT,
			styleColor(LABEL, TEXT + state * 3));
		return result;
	}

	/** Draws a combo box, its active item and a button showing which of how many. See `GuiDropdownBox` for listing the items to
		choose from.

		A press on the item or the button moves to the next item, and from the last back to the first.

		@param bounds  The box, its button included.
		@param text  The items, split at ';'.
		@param active  The active item, in `active[0]`, or null; clamped to the items.
		@return  0. */
	static function GuiComboBox(bounds:Rectangle, text:String, active:Array<Int>):Int {
		var state = guiState;
		if (active == null)
			active = [0];
		var b = new Rectangle(bounds.x, bounds.y, bounds.width, bounds.height);
		b.width -= GuiGetStyle(COMBOBOX, COMBO_BUTTON_WIDTH) + GuiGetStyle(COMBOBOX, COMBO_BUTTON_SPACING);
		var selector = new Rectangle(b.x + b.width + GuiGetStyle(COMBOBOX, COMBO_BUTTON_SPACING), b.y, GuiGetStyle(COMBOBOX, COMBO_BUTTON_WIDTH), b.height);
		var items = textSplit(text, ";".code, null), itemCount = items.length;
		if (active[0] < 0)
			active[0] = 0;
		else if (active[0] > itemCount - 1)
			active[0] = itemCount - 1;
		if (state != STATE_DISABLED && !guiLocked && itemCount > 1 && !guiControlExclusiveMode) {
			var mousePoint = GetMousePosition();
			if (CheckCollisionPointRec(mousePoint, b) || CheckCollisionPointRec(mousePoint, selector)) {
				if (IsMouseButtonPressed(MOUSE_BUTTON_LEFT)) {
					active[0] += 1;
					if (active[0] >= itemCount)
						active[0] = 0;
				}
				state = IsMouseButtonDown(MOUSE_BUTTON_LEFT) ? STATE_PRESSED : STATE_FOCUSED;
			}
		}
		drawRectangle(b, GuiGetStyle(COMBOBOX, BORDER_WIDTH), styleColor(COMBOBOX, BORDER + state * 3), styleColor(COMBOBOX, BASE + state * 3));
		drawText(items[active[0]], textBounds(COMBOBOX, b), GuiGetStyle(COMBOBOX, TEXT_ALIGNMENT), styleColor(COMBOBOX, TEXT + state * 3));
		var tempBorderWidth = GuiGetStyle(BUTTON, BORDER_WIDTH),
			tempTextAlign = GuiGetStyle(BUTTON, TEXT_ALIGNMENT);
		GuiSetStyle(BUTTON, BORDER_WIDTH, 1);
		GuiSetStyle(BUTTON, TEXT_ALIGNMENT, TEXT_ALIGN_CENTER);
		GuiButton(selector, '${active[0] + 1}/$itemCount');
		GuiSetStyle(BUTTON, TEXT_ALIGNMENT, tempTextAlign);
		GuiSetStyle(BUTTON, BORDER_WIDTH, tempBorderWidth);
		return 0;
	}

	/** Draws a dropdown box, its active item with its items listed below it in edit mode. See `GuiComboBox` for stepping through the
		items in place.

		The program turns edit mode on and off with the result.

		Lists the items above the box with `DROPDOWN_ROLL_UP`.

		Focuses the item under the mouse.

		@param bounds  The box; each item is its size.
		@param text  The items, split at ';'.
		@param active  The active item, in `active[0]`, or null; an item clicked in edit mode becomes it.
		@param editMode  Whether it is open.
		@return  1 when it was pressed closed, or an item was chosen or a press fell outside it open, else 0. */
	static function GuiDropdownBox(bounds:Rectangle, text:String, active:Array<Int>, editMode:Bool):Int {
		var result = 0, state = guiState;
		if (active == null)
			active = [0];
		var itemSelected = active[0], itemFocused = -1;
		var direction = GuiGetStyle(DROPDOWNBOX, DROPDOWN_ROLL_UP) == 1 ? 1 : 0;
		var items = textSplit(text, ";".code, null), itemCount = items.length;
		var spacing = GuiGetStyle(DROPDOWNBOX, DROPDOWN_ITEMS_SPACING);
		var boundsOpen = new Rectangle(bounds.x, bounds.y, bounds.width, (itemCount + 1) * (bounds.height + spacing));
		if (direction == 1)
			boundsOpen.y -= itemCount * (bounds.height + spacing) + spacing;
		var itemBounds = new Rectangle(bounds.x, bounds.y, bounds.width, bounds.height);
		if (state != STATE_DISABLED && (editMode || !guiLocked) && itemCount > 1 && !guiControlExclusiveMode) {
			var mousePoint = GetMousePosition();
			if (editMode) {
				state = STATE_PRESSED;
				if (!CheckCollisionPointRec(mousePoint, boundsOpen))
					if (IsMouseButtonPressed(MOUSE_BUTTON_LEFT) || IsMouseButtonReleased(MOUSE_BUTTON_LEFT))
						result = 1;
				if (CheckCollisionPointRec(mousePoint, bounds) && IsMouseButtonPressed(MOUSE_BUTTON_LEFT))
					result = 1;
				for (i in 0...itemCount) {
					if (direction == 0)
						itemBounds.y += bounds.height + spacing;
					else
						itemBounds.y -= bounds.height + spacing;
					if (CheckCollisionPointRec(mousePoint, itemBounds)) {
						itemFocused = i;
						if (IsMouseButtonReleased(MOUSE_BUTTON_LEFT)) {
							itemSelected = i;
							result = 1;
						}
						break;
					}
				}
				itemBounds = new Rectangle(bounds.x, bounds.y, bounds.width, bounds.height);
			} else if (CheckCollisionPointRec(mousePoint, bounds)) {
				if (IsMouseButtonPressed(MOUSE_BUTTON_LEFT)) {
					result = 1;
					state = STATE_PRESSED;
				} else
					state = STATE_FOCUSED;
			}
		}
		if (editMode)
			GuiPanel(boundsOpen, null);
		drawRectangle(bounds, GuiGetStyle(DROPDOWNBOX, BORDER_WIDTH), styleColor(DROPDOWNBOX, BORDER + state * 3), styleColor(DROPDOWNBOX, BASE + state * 3));
		drawText(items[itemSelected], textBounds(DROPDOWNBOX, bounds), GuiGetStyle(DROPDOWNBOX, TEXT_ALIGNMENT), styleColor(DROPDOWNBOX, TEXT + state * 3));
		if (editMode) {
			for (i in 0...itemCount) {
				if (direction == 0)
					itemBounds.y += bounds.height + spacing;
				else
					itemBounds.y -= bounds.height + spacing;
				if (i == itemSelected) {
					drawRectangle(itemBounds, GuiGetStyle(DROPDOWNBOX, BORDER_WIDTH), styleColor(DROPDOWNBOX, BORDER_COLOR_PRESSED),
						styleColor(DROPDOWNBOX, BASE_COLOR_PRESSED));
					drawText(items[i], textBounds(DROPDOWNBOX, itemBounds), GuiGetStyle(DROPDOWNBOX, TEXT_ALIGNMENT),
						styleColor(DROPDOWNBOX, TEXT_COLOR_PRESSED));
				} else if (i == itemFocused) {
					drawRectangle(itemBounds, GuiGetStyle(DROPDOWNBOX, BORDER_WIDTH), styleColor(DROPDOWNBOX, BORDER_COLOR_FOCUSED),
						styleColor(DROPDOWNBOX, BASE_COLOR_FOCUSED));
					drawText(items[i], textBounds(DROPDOWNBOX, itemBounds), GuiGetStyle(DROPDOWNBOX, TEXT_ALIGNMENT),
						styleColor(DROPDOWNBOX, TEXT_COLOR_FOCUSED));
				} else
					drawText(items[i], textBounds(DROPDOWNBOX, itemBounds), GuiGetStyle(DROPDOWNBOX, TEXT_ALIGNMENT),
						styleColor(DROPDOWNBOX, TEXT_COLOR_NORMAL));
			}
		}
		if (GuiGetStyle(DROPDOWNBOX, DROPDOWN_ARROW_HIDDEN) == 0)
			drawText(direction != 0 ? "#121#" : "#120#",
				new Rectangle(bounds.x + bounds.width - GuiGetStyle(DROPDOWNBOX, ARROW_PADDING), bounds.y + bounds.height / 2 - 6, 10, 10), TEXT_ALIGN_CENTER,
				styleColor(DROPDOWNBOX, TEXT + state * 3));
		active[0] = itemSelected;
		return result;
	}

	/** Draws a text box that takes typed text in edit mode.

		The program turns edit mode on and off with the result.

		In edit mode, a click places the cursor, and these keys move the cursor and delete, repeating while held:

		- Home and End
		- the arrows
		- Delete and Backspace
		- Control-Backspace, which deletes a word

		@param bounds  The box.
		@param text  The text, in `text[0]`, edited in place.
		@param textSize  The most bytes the text may take, its UTF-8 bytes and one more, as raygui's buffer holds them.
		@param editMode  Whether it is being edited.
		@return  1 when its edit mode should flip: while editing, Enter (a single-line box) or a click outside it; otherwise a click on it. Else 0. */
	static function GuiTextBox(bounds:Rectangle, text:Array<String>, textSize:Int, editMode:Bool):Int {
		var result = 0, state = guiState;
		var wrapMode = GuiGetStyle(DEFAULT, TEXT_WRAP_MODE);
		// The text as raygui's buffer: its bytes, then zeros, edited in place.
		var t = bytes(text[0]);
		var textLength = t.length;
		while (t.length < textSize + 8)
			t.push(0);
		var bounds2 = textBounds(TEXTBOX, bounds);
		var thisCursorIndex = textBoxCursorIndex;
		if (thisCursorIndex > textLength)
			thisCursorIndex = textLength;
		var width = textWidth(t, 0) - textWidth(t, thisCursorIndex);
		var textIndexOffset = 0;
		var textSizeStyle = GuiGetStyle(DEFAULT, TEXT_SIZE);
		var cursor = new Rectangle(bounds2.x + width + GuiGetStyle(DEFAULT, TEXT_SPACING), bounds2.y + bounds2.height / 2 - textSizeStyle, 2,
			textSizeStyle * 2.);
		if (cursor.height >= bounds.height)
			cursor.height = bounds.height - GuiGetStyle(TEXTBOX, BORDER_WIDTH) * 2;
		if (cursor.y < bounds.y + GuiGetStyle(TEXTBOX, BORDER_WIDTH))
			cursor.y = bounds.y + GuiGetStyle(TEXTBOX, BORDER_WIDTH);
		var mouseCursor = new Rectangle(-1, cursor.y, 1, cursor.height);
		if (IsKeyDown(KEY_LEFT) || IsKeyDown(KEY_RIGHT) || IsKeyDown(KEY_UP) || IsKeyDown(KEY_DOWN) || IsKeyDown(KEY_BACKSPACE) || IsKeyDown(KEY_DELETE))
			autoCursorCooldownCounter++;
		else {
			autoCursorCooldownCounter = 0;
			autoCursorDelayCounter = 0;
		}
		if (state != STATE_DISABLED
			&& GuiGetStyle(TEXTBOX, TEXT_READONLY) == 0
			&& !guiLocked
			&& !guiControlExclusiveMode
			&& wrapMode == TEXT_WRAP_NONE) {
			var mousePosition = GetMousePosition();
			if (editMode) {
				state = STATE_PRESSED;
				if (textBoxCursorIndex > textLength)
					textBoxCursorIndex = textLength;
				var size = [0];
				while (width >= bounds2.width) {
					codepointNext(t, textIndexOffset, size);
					textIndexOffset += size[0];
					width = textWidth(t, textIndexOffset) - textWidth(t, textBoxCursorIndex);
				}
				var codepoint = GetCharPressed();
				var encoded = [];
				RText.encode(codepoint, encoded);
				var codepointSize = encoded.length;
				if (codepoint >= 32 && textLength + codepointSize < textSize) {
					var i = textLength + codepointSize;
					while (i > textBoxCursorIndex) {
						t[i] = t[i - codepointSize];
						i--;
					}
					for (k in 0...codepointSize)
						t[textBoxCursorIndex + k] = encoded[k];
					textBoxCursorIndex += codepointSize;
					textLength += codepointSize;
					t[textLength] = 0;
				}
				if (textLength > 0 && IsKeyPressed(KEY_HOME))
					textBoxCursorIndex = 0;
				if (textLength > textBoxCursorIndex && IsKeyPressed(KEY_END))
					textBoxCursorIndex = textLength;
				if (textLength > textBoxCursorIndex
					&& (IsKeyPressed(KEY_DELETE)
						|| (IsKeyDown(KEY_DELETE) && autoCursorCooldownCounter >= TEXTBOX_AUTO_CURSOR_COOLDOWN))) {
					autoCursorDelayCounter++;
					if (IsKeyPressed(KEY_DELETE) || autoCursorDelayCounter % TEXTBOX_AUTO_CURSOR_DELAY == 0) {
						codepointNext(t, textBoxCursorIndex, size);
						for (i in textBoxCursorIndex...textLength)
							t[i] = t[i + size[0]];
						textLength -= codepointSize;
						if (textBoxCursorIndex > textLength)
							textBoxCursorIndex = textLength;
						t[textLength] = 0;
					}
				}
				if (textLength > 0 && IsKeyPressed(KEY_BACKSPACE) && (IsKeyDown(KEY_LEFT_CONTROL) || IsKeyDown(KEY_RIGHT_CONTROL))) {
					var i = textBoxCursorIndex - 1, accumulated = 0;
					inline function space(c:Int):Bool
						return c == " ".code || (c >= 9 && c <= 13);
					while (i > 0 && space(byteAt(t, i))) {
						codepointPrevious(t, i, size);
						i -= size[0];
						accumulated += size[0];
					}
					while (i > 0 && !space(byteAt(t, i))) {
						codepointPrevious(t, i, size);
						i -= size[0];
						accumulated += size[0];
					}
					for (j in textBoxCursorIndex - accumulated...textLength)
						t[j] = t[j + accumulated];
					if (textBoxCursorIndex > 0) {
						textBoxCursorIndex -= accumulated;
						textLength -= accumulated;
					}
					t[textLength] = 0;
				} else if (textLength > 0
					&& (IsKeyPressed(KEY_BACKSPACE)
						|| (IsKeyDown(KEY_BACKSPACE) && autoCursorCooldownCounter >= TEXTBOX_AUTO_CURSOR_COOLDOWN))) {
					autoCursorDelayCounter++;
					if (IsKeyPressed(KEY_BACKSPACE) || autoCursorDelayCounter % TEXTBOX_AUTO_CURSOR_DELAY == 0) {
						if (textBoxCursorIndex > 0) {
							codepointPrevious(t, textBoxCursorIndex, size);
							for (i in textBoxCursorIndex - size[0]...textLength)
								t[i] = t[i + size[0]];
							textBoxCursorIndex -= codepointSize;
							textLength -= codepointSize;
						}
						t[textLength] = 0;
					}
				}
				if (IsKeyPressed(KEY_LEFT) || (IsKeyDown(KEY_LEFT) && autoCursorCooldownCounter > TEXTBOX_AUTO_CURSOR_COOLDOWN)) {
					autoCursorDelayCounter++;
					if (IsKeyPressed(KEY_LEFT) || autoCursorDelayCounter % TEXTBOX_AUTO_CURSOR_DELAY == 0) {
						size[0] = 0;
						if (textBoxCursorIndex > 0)
							codepointPrevious(t, textBoxCursorIndex, size);
						if (textBoxCursorIndex >= size[0])
							textBoxCursorIndex -= size[0];
					}
				} else if (IsKeyPressed(KEY_RIGHT) || (IsKeyDown(KEY_RIGHT) && autoCursorCooldownCounter > TEXTBOX_AUTO_CURSOR_COOLDOWN)) {
					autoCursorDelayCounter++;
					if (IsKeyPressed(KEY_RIGHT) || autoCursorDelayCounter % TEXTBOX_AUTO_CURSOR_DELAY == 0) {
						codepointNext(t, textBoxCursorIndex, size);
						if (textBoxCursorIndex + size[0] <= textLength)
							textBoxCursorIndex += size[0];
					}
				}
				if (CheckCollisionPointRec(mousePosition, bounds2)) {
					var scale = textSizeStyle / guiFont.baseSize, glyph = 0., widthToMouseX = 0., mouseCursorIndex = 0;
					var i = textIndexOffset;
					while (i < textLength) {
						codepoint = codepointNext(t, i, size);
						codepointSize = size[0];
						glyph = glyphWidth(codepoint, scale);
						if (mousePosition.x <= bounds2.x + (widthToMouseX + glyph / 2)) {
							mouseCursor.x = bounds2.x + widthToMouseX;
							mouseCursorIndex = i;
							break;
						}
						widthToMouseX += glyph + GuiGetStyle(DEFAULT, TEXT_SPACING);
						i++;
					}
					var textEndWidth = textWidth(t, textIndexOffset);
					if (GetMousePosition().x >= bounds2.x + textEndWidth - glyph / 2) {
						mouseCursor.x = bounds2.x + textEndWidth;
						mouseCursorIndex = textLength;
					}
					if (mouseCursor.x >= 0 && IsMouseButtonPressed(MOUSE_BUTTON_LEFT)) {
						cursor.x = mouseCursor.x;
						textBoxCursorIndex = mouseCursorIndex;
					}
				} else
					mouseCursor.x = -1;
				cursor.x = bounds.x + GuiGetStyle(TEXTBOX, TEXT_PADDING) + textWidth(t, textIndexOffset) - textWidth(t, textBoxCursorIndex)
					+ GuiGetStyle(DEFAULT, TEXT_SPACING);
				if (IsKeyPressed(KEY_ENTER)
					|| (!CheckCollisionPointRec(mousePosition, bounds) && IsMouseButtonPressed(MOUSE_BUTTON_LEFT))) {
					textBoxCursorIndex = 0;
					result = 1;
				}
			} else if (CheckCollisionPointRec(mousePosition, bounds)) {
				state = STATE_FOCUSED;
				if (IsMouseButtonPressed(MOUSE_BUTTON_LEFT)) {
					textBoxCursorIndex = textLength;
					result = 1;
				}
			}
		}
		var end = 0;
		while (end < t.length && t[end] != 0)
			end++;
		text[0] = RText.decoded(t, 0, end);
		var border = GuiGetStyle(TEXTBOX, BORDER_WIDTH);
		if (state == STATE_PRESSED)
			drawRectangle(bounds, border, styleColor(TEXTBOX, BORDER + state * 3), styleColor(TEXTBOX, BASE_COLOR_PRESSED));
		else if (state == STATE_DISABLED)
			drawRectangle(bounds, border, styleColor(TEXTBOX, BORDER + state * 3), styleColor(TEXTBOX, BASE_COLOR_DISABLED));
		else
			drawRectangle(bounds, border, styleColor(TEXTBOX, BORDER + state * 3), BLANK);
		drawTextBytes(t, textIndexOffset, bounds2, GuiGetStyle(TEXTBOX, TEXT_ALIGNMENT), styleColor(TEXTBOX, TEXT + state * 3));
		if (editMode && GuiGetStyle(TEXTBOX, TEXT_READONLY) == 0) {
			drawRectangle(cursor, 0, BLANK, styleColor(TEXTBOX, BORDER_COLOR_PRESSED));
			if (mouseCursor.x >= 0)
				drawRectangle(mouseCursor, 0, BLANK, styleColor(TEXTBOX, BORDER_COLOR_PRESSED));
		} else if (state == STATE_FOCUSED)
			tooltip(bounds);
		return result;
	}

	/** Draws a spinner, a value box between buttons that step its value down and up. See `GuiValueBox` for drawing the value box
		alone.

		In edit mode, the value box takes typed digits.

		Out of edit mode, the value is clamped to the range.

		@param bounds  The spinner, its buttons included.
		@param text  Its label, beside it, or null.
		@param value  The value, in `value[0]`.
		@param minValue  The least.
		@param maxValue  The most.
		@param editMode  Whether its value box is being edited.
		@return  The value box's result: 1 when its edit mode should flip, as `GuiTextBox`'s; else 0. */
	static function GuiSpinner(bounds:Rectangle, text:String, value:Array<Int>, minValue:Int, maxValue:Int, editMode:Bool):Int {
		var state = guiState;
		var tempValue = [value[0]];
		var buttonWidth = GuiGetStyle(SPINNER, SPIN_BUTTON_WIDTH),
			buttonSpacing = GuiGetStyle(SPINNER, SPIN_BUTTON_SPACING);
		var spinner = new Rectangle(bounds.x + buttonWidth + buttonSpacing, bounds.y, bounds.width - 2 * (buttonWidth + buttonSpacing), bounds.height);
		var left = new Rectangle(bounds.x, bounds.y, buttonWidth, bounds.height);
		var right = new Rectangle(bounds.x + bounds.width - buttonWidth, bounds.y, buttonWidth, bounds.height);
		var label = sideLabel(SPINNER, bounds, text);
		if (state != STATE_DISABLED && !guiLocked && !guiControlExclusiveMode) {
			if (CheckCollisionPointRec(GetMousePosition(), bounds))
				state = IsMouseButtonDown(MOUSE_BUTTON_LEFT) ? STATE_PRESSED : STATE_FOCUSED;
		}
		if (GuiButton(left, GuiIconText(ICON_ARROW_LEFT_FILL, null)) != 0)
			tempValue[0]--;
		if (GuiButton(right, GuiIconText(ICON_ARROW_RIGHT_FILL, null)) != 0)
			tempValue[0]++;
		if (!editMode) {
			if (tempValue[0] < minValue)
				tempValue[0] = minValue;
			if (tempValue[0] > maxValue)
				tempValue[0] = maxValue;
		}
		var result = GuiValueBox(spinner, null, tempValue, minValue, maxValue, editMode);
		drawText(text, label, GuiGetStyle(SPINNER, TEXT_ALIGNMENT) == TEXT_ALIGN_RIGHT ? TEXT_ALIGN_LEFT : TEXT_ALIGN_RIGHT,
			styleColor(LABEL, TEXT + state * 3));
		value[0] = tempValue[0];
		return result;
	}

	/** Draws a value box, a whole number centered. See `GuiValueBoxFloat` for editing a number with a fraction.

		The program turns edit mode on and off with the result.

		In edit mode, the box takes typed digits and Backspace.

		Enter or a click outside ends editing and clamps the value to the range.

		@param bounds  The box.
		@param text  Its label, beside it, or null.
		@param value  The value, in `value[0]`.
		@param minValue  The least.
		@param maxValue  The most.
		@param editMode  Whether it is being edited.
		@return  1 when it was clicked into edit mode, or editing ended, else 0. */
	static function GuiValueBox(bounds:Rectangle, text:String, value:Array<Int>, minValue:Int, maxValue:Int, editMode:Bool):Int {
		var result = 0, state = guiState;
		var textValue = Std.string(value[0]);
		var label = sideLabel(VALUEBOX, bounds, text);
		if (state != STATE_DISABLED && !guiLocked && !guiControlExclusiveMode) {
			var mousePoint = GetMousePosition();
			var changed = false;
			if (editMode) {
				state = STATE_PRESSED;
				if (textValue.length < VALUEBOX_MAX_CHARS && stringWidth(textValue) < bounds.width) {
					var key = GetCharPressed();
					if (key >= 48 && key <= 57) {
						textValue += String.fromCharCode(key);
						changed = true;
					}
				}
				if (textValue.length > 0 && IsKeyPressed(KEY_BACKSPACE)) {
					textValue = textValue.substr(0, textValue.length - 1);
					changed = true;
				}
				if (changed)
					value[0] = TextToInteger(textValue);
				if (IsKeyPressed(KEY_ENTER)
					|| IsKeyPressed(KEY_KP_ENTER)
					|| (!CheckCollisionPointRec(mousePoint, bounds) && IsMouseButtonPressed(MOUSE_BUTTON_LEFT))) {
					if (value[0] > maxValue)
						value[0] = maxValue;
					else if (value[0] < minValue)
						value[0] = minValue;
					result = 1;
				}
			} else {
				if (value[0] > maxValue)
					value[0] = maxValue;
				else if (value[0] < minValue)
					value[0] = minValue;
				if (CheckCollisionPointRec(mousePoint, bounds)) {
					state = STATE_FOCUSED;
					if (IsMouseButtonPressed(MOUSE_BUTTON_LEFT))
						result = 1;
				}
			}
		}
		drawValueBox(bounds, textValue, label, text, state, editMode);
		return result;
	}

	/** Draws a value box for a number with a fraction, showing and editing the number's text and reading the value from it. See
		`GuiValueBox` for editing a whole number.

		The program keeps the text.

		In edit mode, the box takes digits, '.', and a sign first.

		@param bounds  The box.
		@param text  Its label, beside it, or null.
		@param textValue  The number's text, in `textValue[0]`, edited in place.
		@param value  The value, in `value[0]`, read from the text as it changes.
		@param editMode  Whether it is being edited.
		@return  1 when it was clicked into edit mode, or Enter or a click outside ended editing, else 0. */
	static function GuiValueBoxFloat(bounds:Rectangle, text:String, textValue:Array<String>, value:Array<Float>, editMode:Bool):Int {
		var result = 0, state = guiState;
		var label = sideLabel(VALUEBOX, bounds, text);
		var shown = textValue[0] == null ? "" : textValue[0];
		if (state != STATE_DISABLED && !guiLocked && !guiControlExclusiveMode) {
			var mousePoint = GetMousePosition();
			var changed = false;
			if (editMode) {
				state = STATE_PRESSED;
				var keyCount = bytes(shown).length;
				if (keyCount < VALUEBOX_MAX_CHARS && stringWidth(shown) < bounds.width) {
					var key = GetCharPressed();
					if ((key >= 48 && key <= 57) || key == ".".code || (keyCount == 0 && (key == "+".code || key == "-".code))) {
						shown += String.fromCharCode(key);
						changed = true;
					}
				}
				if (IsKeyPressed(KEY_BACKSPACE)) {
					var b = bytes(shown);
					if (b.length > 0) {
						shown = RText.decoded(b, 0, b.length - 1);
						changed = true;
					}
				}
				if (changed)
					value[0] = TextToFloat(shown);
				if (IsKeyPressed(KEY_ENTER)
					|| IsKeyPressed(KEY_KP_ENTER)
					|| (!CheckCollisionPointRec(mousePoint, bounds) && IsMouseButtonPressed(MOUSE_BUTTON_LEFT)))
					result = 1;
			} else if (CheckCollisionPointRec(mousePoint, bounds)) {
				state = STATE_FOCUSED;
				if (IsMouseButtonPressed(MOUSE_BUTTON_LEFT))
					result = 1;
			}
		}
		textValue[0] = shown;
		drawValueBox(bounds, shown, label, text, state, editMode);
		return result;
	}

	/** Draws a slider, a handle along a bar dragged with the left button, and returns 1 when the value changes. See `GuiSliderBar`
		for drawing a bar filled to the value.

		The drag goes on outside the bar until the left button is released.

		@param bounds  The slider.
		@param textLeft  The text left of it, or null.
		@param textRight  The text right of it, or null.
		@param value  The value, in `value[0]`, clamped to the range.
		@param minValue  The value at the left end.
		@param maxValue  The value at the right end.
		@return  1 when the value changed, else 0. */
	static function GuiSlider(bounds:Rectangle, textLeft:String, textRight:String, value:Array<Float>, minValue:Float, maxValue:Float):Int {
		return sliderPro(bounds, textLeft, textRight, value, minValue, maxValue, GuiGetStyle(SLIDER, SLIDER_WIDTH));
	}

	/** Draws a slider bar, filled from the left to the value and dragged with the left button, and returns 1 when the value changes.
		See `GuiSlider` for drawing a handle along a bar.

		@param bounds  The bar.
		@param textLeft  The text left of it, or null.
		@param textRight  The text right of it, or null.
		@param value  The value, in `value[0]`, clamped to the range.
		@param minValue  The value at the left end.
		@param maxValue  The value at the right end.
		@return  1 when the value changed, else 0. */
	static function GuiSliderBar(bounds:Rectangle, textLeft:String, textRight:String, value:Array<Float>, minValue:Float, maxValue:Float):Int {
		return sliderPro(bounds, textLeft, textRight, value, minValue, maxValue, 0);
	}

	/** Draws a progress bar, filled from the left to the value.

		Colors the border as far as the value reaches.

		The fill is the value over the most less the least, so the least only clamps, as raygui's. A null value is drawn at half.

		@param bounds  The bar.
		@param textLeft  The text left of it, or null.
		@param textRight  The text right of it, or null.
		@param value  The value, in `value[0]`, or null; clamped to the most.
		@param minValue  The least.
		@param maxValue  The most.
		@return  0. */
	static function GuiProgressBar(bounds:Rectangle, textLeft:String, textRight:String, value:Array<Float>, minValue:Float, maxValue:Float):Int {
		var state = guiState;
		if (value == null)
			value = [(maxValue - minValue) / 2];
		var border = GuiGetStyle(PROGRESSBAR, BORDER_WIDTH),
			padding = GuiGetStyle(PROGRESSBAR, PROGRESS_PADDING);
		var progress = new Rectangle(bounds.x + border, bounds.y + border + padding, 0, bounds.height - 2 * border - 2 * padding);
		if (value[0] > maxValue)
			value[0] = maxValue;
		if (state != STATE_DISABLED)
			progress.width = f32(f32(value[0] / (maxValue - minValue)) * bounds.width) - (value[0] >= maxValue ? 2 * border : 0.);
		if (state == STATE_DISABLED)
			drawRectangle(bounds, border, styleColor(PROGRESSBAR, BORDER + state * 3), BLANK);
		else {
			var focused = styleColor(PROGRESSBAR, BORDER_COLOR_FOCUSED),
				normal = styleColor(PROGRESSBAR, BORDER_COLOR_NORMAL);
			var reached = Std.int(progress.width);
			if (value[0] > minValue) {
				drawRectangle(new Rectangle(bounds.x, bounds.y, reached + border, border), 0, BLANK, focused);
				drawRectangle(new Rectangle(bounds.x, bounds.y + 1, border, bounds.height - 2), 0, BLANK, focused);
				drawRectangle(new Rectangle(bounds.x, bounds.y + bounds.height - 1, reached + border, border), 0, BLANK, focused);
			} else
				drawRectangle(new Rectangle(bounds.x, bounds.y, border, bounds.height), 0, BLANK, normal);
			if (value[0] >= maxValue)
				drawRectangle(new Rectangle(bounds.x + progress.width + 1, bounds.y, border, bounds.height), 0, BLANK, focused);
			else {
				drawRectangle(new Rectangle(bounds.x + reached + 1, bounds.y, bounds.width - reached - 1, border), 0, BLANK, normal);
				drawRectangle(new Rectangle(bounds.x + reached + 1, bounds.y + bounds.height - 1, bounds.width - reached - 1, border), 0, BLANK, normal);
				drawRectangle(new Rectangle(bounds.x + bounds.width - 1, bounds.y + 1, border, bounds.height - 2), 0, BLANK, normal);
			}
			drawRectangle(progress, 0, BLANK, styleColor(PROGRESSBAR, BASE_COLOR_PRESSED));
		}
		sideTexts(PROGRESSBAR, bounds, textLeft, textRight, styleColor(PROGRESSBAR, TEXT + state * 3));
		return 0;
	}

	/** Draws a status bar, a bordered bar with text, as a window's title.

		@param bounds  The bar.
		@param text  The text, or null.
		@return  0. */
	static function GuiStatusBar(bounds:Rectangle, text:String):Int {
		var state = guiState;
		drawRectangle(bounds, GuiGetStyle(STATUSBAR, BORDER_WIDTH), styleColor(STATUSBAR, BORDER + state * 3), styleColor(STATUSBAR, BASE + state * 3));
		drawText(text, textBounds(STATUSBAR, bounds), GuiGetStyle(STATUSBAR, TEXT_ALIGNMENT), styleColor(STATUSBAR, TEXT + state * 3));
		return 0;
	}

	/** Draws a placeholder, a filled rectangle with centered text.

		@param bounds  The rectangle.
		@param text  The text, or null.
		@return  0. */
	static function GuiDummyRec(bounds:Rectangle, text:String):Int {
		var state = guiState;
		if (state != STATE_DISABLED && !guiLocked && !guiControlExclusiveMode) {
			if (CheckCollisionPointRec(GetMousePosition(), bounds))
				state = IsMouseButtonDown(MOUSE_BUTTON_LEFT) ? STATE_PRESSED : STATE_FOCUSED;
		}
		drawRectangle(bounds, 0, BLANK, styleColor(DEFAULT, state != STATE_DISABLED ? BASE_COLOR_NORMAL : BASE_COLOR_DISABLED));
		drawText(text, textBounds(DEFAULT, bounds), TEXT_ALIGN_CENTER, styleColor(BUTTON, state != STATE_DISABLED ? TEXT_COLOR_NORMAL : TEXT_COLOR_DISABLED));
		return 0;
	}

	/** Draws a grid, a line every spacing divided by subdivs, every subdivs-th line stronger.

		@param bounds  The grid.
		@param text  Not drawn.
		@param spacing  The space between the strong lines, in pixels.
		@param subdivs  How many cells between strong lines; 0 draws no lines.
		@param mouseCell  Receives the cell under the mouse, counted in spacings from the grid's corner, or -1, -1 when it isn't over it;
			or null.
		@return  0. */
	static function GuiGrid(bounds:Rectangle, text:String, spacing:Float, subdivs:Int, mouseCell:Vector2):Int {
		var state = guiState;
		var mousePoint = GetMousePosition();
		var cellX = -1., cellY = -1.;
		var spaceWidth = spacing / subdivs;
		var linesV = Std.int(bounds.width / spaceWidth) + 1,
			linesH = Std.int(bounds.height / spaceWidth) + 1;
		var color = GuiGetStyle(DEFAULT, LINE_COLOR);
		if (state != STATE_DISABLED && !guiLocked && !guiControlExclusiveMode) {
			if (CheckCollisionPointRec(mousePoint, bounds)) {
				cellX = Math.ffloor((mousePoint.x - bounds.x) / spacing);
				cellY = Math.ffloor((mousePoint.y - bounds.y) / spacing);
			}
		}
		if (state == STATE_DISABLED)
			color = GuiGetStyle(DEFAULT, BORDER_COLOR_DISABLED);
		if (subdivs > 0) {
			for (i in 0...linesV)
				drawRectangle(new Rectangle(f32(bounds.x + f32(f32(spacing * i) / subdivs)), bounds.y, 1, bounds.height + 1), 0, BLANK,
					guiFade(GetColor(color), i % subdivs == 0 ? f32(GRID_ALPHA * 4) : GRID_ALPHA));
			for (i in 0...linesH)
				drawRectangle(new Rectangle(bounds.x, f32(bounds.y + f32(f32(spacing * i) / subdivs)), bounds.width + 1, 1), 0, BLANK,
					guiFade(GetColor(color), i % subdivs == 0 ? f32(GRID_ALPHA * 4) : GRID_ALPHA));
		}
		if (mouseCell != null) {
			mouseCell.x = cellX;
			mouseCell.y = cellY;
		}
		return 0;
	}

	// ---- Advanced controls ----

	/** Draws a list view of the text's items ("One;Two;Three"), scrolled by a bar and the mouse wheel when they don't fit. See
		`GuiListViewEx` for listing an array of items and reading the one under the mouse.

		A click on an item chooses it, and a second click unchooses it.

		@param bounds  The list.
		@param text  The items, split at ';'.
		@param scrollIndex  The first item shown, in `scrollIndex[0]`, or null.
		@param active  The item chosen, in `active[0]`, -1 for none, or null.
		@return  0. */
	static function GuiListView(bounds:Rectangle, text:String, scrollIndex:Array<Int>, active:Array<Int>):Int {
		var items = text == null ? null : textSplit(text, ";".code, null);
		return GuiListViewEx(bounds, items, items == null ? 0 : items.length, scrollIndex, active, null);
	}

	/** Draws a list view of an array of items, scrolled by a bar and the mouse wheel when they don't fit. See `GuiListView` for
		listing the items of a string split at ';'.

		Focuses the item under the mouse.

		A click on an item chooses it, and a second click unchooses it.

		@param bounds  The list.
		@param text  The items.
		@param count  How many items.
		@param scrollIndex  The first item shown, in `scrollIndex[0]`, or null.
		@param active  The item chosen, in `active[0]`, -1 for none, or null.
		@param focus  Receives the item under the mouse, in `focus[0]`, -1 for none, or null.
		@return  0. */
	static function GuiListViewEx(bounds:Rectangle, text:Array<String>, count:Int, scrollIndex:Array<Int>, active:Array<Int>, focus:Array<Int>):Int {
		var state = guiState;
		var itemFocused = focus == null ? -1 : focus[0];
		var itemSelected = active == null ? -1 : active[0];
		var itemsHeight = GuiGetStyle(LISTVIEW, LIST_ITEMS_HEIGHT),
			itemsSpacing = GuiGetStyle(LISTVIEW, LIST_ITEMS_SPACING);
		var defaultBorder = GuiGetStyle(DEFAULT, BORDER_WIDTH);
		var useScrollBar = (itemsHeight + itemsSpacing) * count > bounds.height;
		var itemBounds = new Rectangle(bounds.x + itemsSpacing, bounds.y + itemsSpacing + defaultBorder, bounds.width - 2 * itemsSpacing - defaultBorder,
			itemsHeight);
		if (useScrollBar)
			itemBounds.width -= GuiGetStyle(LISTVIEW, SCROLLBAR_WIDTH);
		var visibleItems = idiv(Std.int(bounds.height), itemsHeight + itemsSpacing);
		if (visibleItems > count)
			visibleItems = count;
		var startIndex = scrollIndex == null ? 0 : scrollIndex[0];
		if (startIndex < 0 || startIndex > count - visibleItems)
			startIndex = 0;
		var endIndex = startIndex + visibleItems;
		if (state != STATE_DISABLED && !guiLocked && !guiControlExclusiveMode) {
			var mousePoint = GetMousePosition();
			if (CheckCollisionPointRec(mousePoint, bounds)) {
				state = STATE_FOCUSED;
				for (i in 0...visibleItems) {
					if (CheckCollisionPointRec(mousePoint, itemBounds)) {
						itemFocused = startIndex + i;
						if (IsMouseButtonPressed(MOUSE_BUTTON_LEFT))
							itemSelected = itemSelected == startIndex + i ? -1 : startIndex + i;
						break;
					}
					itemBounds.y += itemsHeight + itemsSpacing;
				}
				if (useScrollBar) {
					startIndex -= Std.int(GetMouseWheelMove());
					if (startIndex < 0)
						startIndex = 0;
					else if (startIndex > count - visibleItems)
						startIndex = count - visibleItems;
					endIndex = startIndex + visibleItems;
					if (endIndex > count)
						endIndex = count;
				}
			} else
				itemFocused = -1;
			itemBounds.y = bounds.y + itemsSpacing + defaultBorder;
		}
		var border = GuiGetStyle(LISTVIEW, BORDER_WIDTH);
		drawRectangle(bounds, border, styleColor(LISTVIEW, BORDER + state * 3), styleColor(DEFAULT, BACKGROUND_COLOR));
		var alignment = GuiGetStyle(LISTVIEW, TEXT_ALIGNMENT);
		if (text != null)
			for (i in 0...visibleItems) {
				var item = text[startIndex + i];
				drawRectangle(itemBounds, GuiGetStyle(LISTVIEW, LIST_ITEMS_BORDER_WIDTH), styleColor(LISTVIEW, BORDER_COLOR_NORMAL), BLANK);
				if (state == STATE_DISABLED) {
					if (startIndex + i == itemSelected)
						drawRectangle(itemBounds, border, styleColor(LISTVIEW, BORDER_COLOR_DISABLED), styleColor(LISTVIEW, BASE_COLOR_DISABLED));
					drawText(item, textBounds(DEFAULT, itemBounds), alignment, styleColor(LISTVIEW, TEXT_COLOR_DISABLED));
				} else if (startIndex + i == itemSelected && active != null) {
					drawRectangle(itemBounds, border, styleColor(LISTVIEW, BORDER_COLOR_PRESSED), styleColor(LISTVIEW, BASE_COLOR_PRESSED));
					drawText(item, textBounds(DEFAULT, itemBounds), alignment, styleColor(LISTVIEW, TEXT_COLOR_PRESSED));
				} else if (startIndex + i == itemFocused) {
					drawRectangle(itemBounds, border, styleColor(LISTVIEW, BORDER_COLOR_FOCUSED), styleColor(LISTVIEW, BASE_COLOR_FOCUSED));
					drawText(item, textBounds(DEFAULT, itemBounds), alignment, styleColor(LISTVIEW, TEXT_COLOR_FOCUSED));
				} else
					drawText(item, textBounds(DEFAULT, itemBounds), alignment, styleColor(LISTVIEW, TEXT_COLOR_NORMAL));
				itemBounds.y += itemsHeight + itemsSpacing;
			}
		if (useScrollBar) {
			var barWidth = GuiGetStyle(LISTVIEW, SCROLLBAR_WIDTH);
			var barBounds = new Rectangle(bounds.x + bounds.width - border - barWidth, bounds.y + border, barWidth, bounds.height - 2 * defaultBorder);
			var percentVisible = f32((endIndex - startIndex) / count);
			var sliderSize = f32(bounds.height * percentVisible);
			var prevSliderSize = GuiGetStyle(SCROLLBAR, SCROLL_SLIDER_SIZE),
				prevScrollSpeed = GuiGetStyle(SCROLLBAR, SCROLL_SPEED);
			GuiSetStyle(SCROLLBAR, SCROLL_SLIDER_SIZE, Std.int(sliderSize));
			GuiSetStyle(SCROLLBAR, SCROLL_SPEED, count - visibleItems);
			startIndex = scrollBar(barBounds, startIndex, 0, count - visibleItems);
			GuiSetStyle(SCROLLBAR, SCROLL_SPEED, prevScrollSpeed);
			GuiSetStyle(SCROLLBAR, SCROLL_SLIDER_SIZE, prevSliderSize);
		}
		if (active != null)
			active[0] = itemSelected;
		if (focus != null)
			focus[0] = itemFocused;
		if (scrollIndex != null)
			scrollIndex[0] = startIndex;
		return 0;
	}

	/** Draws a message box, a window with a centered message and a row of buttons, and returns the button clicked. See
		`GuiTextInputBox` for adding a text box.

		@param bounds  The window.
		@param title  Its title, or null.
		@param message  The message.
		@param buttons  The buttons' texts, split at ';' ("Ok;Cancel").
		@return  The button clicked, from 1, 0 for the close button, else -1. */
	static function GuiMessageBox(bounds:Rectangle, title:String, message:String, buttons:String):Int {
		var result = -1;
		var buttonsText = textSplit(buttons, ";".code, null),
			buttonCount = buttonsText.length;
		var buttonBounds = new Rectangle(bounds.x + MESSAGEBOX_BUTTON_PADDING,
			bounds.y + bounds.height - MESSAGEBOX_BUTTON_HEIGHT - MESSAGEBOX_BUTTON_PADDING,
			(bounds.width - MESSAGEBOX_BUTTON_PADDING * (buttonCount + 1)) / buttonCount, MESSAGEBOX_BUTTON_HEIGHT);
		var messageBounds = new Rectangle(bounds.x
			+ MESSAGEBOX_BUTTON_PADDING, bounds.y
			+ STATUSBAR_HEIGHT
			+ MESSAGEBOX_BUTTON_PADDING,
			bounds.width
			- MESSAGEBOX_BUTTON_PADDING * 2, bounds.height
			- STATUSBAR_HEIGHT
			- 3 * MESSAGEBOX_BUTTON_PADDING
			- MESSAGEBOX_BUTTON_HEIGHT);
		if (GuiWindowBox(bounds, title) != 0)
			result = 0;
		var prevTextAlignment = GuiGetStyle(LABEL, TEXT_ALIGNMENT);
		GuiSetStyle(LABEL, TEXT_ALIGNMENT, TEXT_ALIGN_CENTER);
		GuiLabel(messageBounds, message);
		GuiSetStyle(LABEL, TEXT_ALIGNMENT, prevTextAlignment);
		prevTextAlignment = GuiGetStyle(BUTTON, TEXT_ALIGNMENT);
		GuiSetStyle(BUTTON, TEXT_ALIGNMENT, TEXT_ALIGN_CENTER);
		for (i in 0...buttonCount) {
			if (GuiButton(buttonBounds, buttonsText[i]) != 0)
				result = i + 1;
			buttonBounds.x += buttonBounds.width + MESSAGEBOX_BUTTON_PADDING;
		}
		GuiSetStyle(BUTTON, TEXT_ALIGNMENT, prevTextAlignment);
		return result;
	}

	/** Draws a text input box, a window with a message, a text box and a row of buttons, and returns the button clicked. See
		`GuiMessageBox` for drawing the message and buttons alone.

		A click on the text box starts editing the text.

		With `secretViewActive`, a toggle beside the text box shows the text or hides it behind stars.

		One text input box may be open at a time.

		@param bounds  The window.
		@param title  Its title, or null.
		@param message  The message above the text box, or null.
		@param buttons  The buttons' texts, split at ';' ("Ok;Cancel").
		@param text  The text, in `text[0]`, edited in place.
		@param textMaxSize  The most bytes the text may take, as `GuiTextBox`'s textSize.
		@param secretViewActive  Whether the text shows, in `secretViewActive[0]`, or null for a box that always shows it.
		@return  The button clicked, from 1, 0 for the close button, else -1. */
	static function GuiTextInputBox(bounds:Rectangle, title:String, message:String, buttons:String, text:Array<String>, textMaxSize:Int,
			secretViewActive:Array<Bool>):Int {
		var result = -1;
		var buttonsText = textSplit(buttons, ";".code, null),
			buttonCount = buttonsText.length;
		var buttonBounds = new Rectangle(bounds.x
			+ TEXTINPUTBOX_BUTTON_PADDING,
			bounds.y
			+ bounds.height
			- TEXTINPUTBOX_BUTTON_HEIGHT
			- TEXTINPUTBOX_BUTTON_PADDING,
			(bounds.width - TEXTINPUTBOX_BUTTON_PADDING * (buttonCount + 1)) / buttonCount, TEXTINPUTBOX_BUTTON_HEIGHT);
		var messageInputHeight = Std.int(bounds.height) - STATUSBAR_HEIGHT - GuiGetStyle(STATUSBAR, BORDER_WIDTH) - TEXTINPUTBOX_BUTTON_HEIGHT
			- 2 * TEXTINPUTBOX_BUTTON_PADDING;
		var messageBounds = new Rectangle();
		if (message != null) {
			var textSize = stringWidth(message) + 2;
			messageBounds.x = bounds.x + bounds.width / 2 - idiv(textSize, 2);
			messageBounds.y = bounds.y + STATUSBAR_HEIGHT + idiv(messageInputHeight, 4) - GuiGetStyle(DEFAULT, TEXT_SIZE) / 2.;
			messageBounds.width = textSize;
			messageBounds.height = GuiGetStyle(DEFAULT, TEXT_SIZE);
		}
		var boxBounds = new Rectangle(bounds.x
			+ TEXTINPUTBOX_BUTTON_PADDING, bounds.y
			+ STATUSBAR_HEIGHT
			- idiv(TEXTINPUTBOX_HEIGHT, 2),
			bounds.width
			- TEXTINPUTBOX_BUTTON_PADDING * 2, TEXTINPUTBOX_HEIGHT);
		if (message == null)
			boxBounds.y = bounds.y + 24 + TEXTINPUTBOX_BUTTON_PADDING;
		else
			boxBounds.y += idiv(messageInputHeight, 2) + idiv(messageInputHeight, 4);
		if (GuiWindowBox(bounds, title) != 0)
			result = 0;
		if (message != null) {
			var prevTextAlignment = GuiGetStyle(LABEL, TEXT_ALIGNMENT);
			GuiSetStyle(LABEL, TEXT_ALIGNMENT, TEXT_ALIGN_CENTER);
			GuiLabel(messageBounds, message);
			GuiSetStyle(LABEL, TEXT_ALIGNMENT, prevTextAlignment);
		}
		if (secretViewActive != null) {
			var shown = secretViewActive[0] || textInputEditMode ? text : ["****************"];
			if (GuiTextBox(new Rectangle(boxBounds.x, boxBounds.y, boxBounds.width - 4 - TEXTINPUTBOX_HEIGHT, boxBounds.height), shown, textMaxSize,
				textInputEditMode) != 0)
				textInputEditMode = !textInputEditMode;
			GuiToggle(new Rectangle(boxBounds.x + boxBounds.width - TEXTINPUTBOX_HEIGHT, boxBounds.y, TEXTINPUTBOX_HEIGHT, TEXTINPUTBOX_HEIGHT),
				secretViewActive[0] ? "#44#" : "#45#", secretViewActive);
		} else if (GuiTextBox(boxBounds, text, textMaxSize, textInputEditMode) != 0)
			textInputEditMode = !textInputEditMode;
		var prevBtnTextAlignment = GuiGetStyle(BUTTON, TEXT_ALIGNMENT);
		GuiSetStyle(BUTTON, TEXT_ALIGNMENT, TEXT_ALIGN_CENTER);
		for (i in 0...buttonCount) {
			if (GuiButton(buttonBounds, buttonsText[i]) != 0)
				result = i + 1;
			buttonBounds.x += buttonBounds.width + MESSAGEBOX_BUTTON_PADDING;
		}
		if (result >= 0)
			textInputEditMode = false;
		GuiSetStyle(BUTTON, TEXT_ALIGNMENT, prevBtnTextAlignment);
		return result;
	}

	/** Draws a color picker, a saturation and value panel with a hue bar beside it, both dragged with the left button. See
		`GuiColorPickerHSV` for keeping the hue steady.

		Converts the color through HSV each call, so its hue may shift where red, green and blue are close.

		@param bounds  The panel; the hue bar is beside it.
		@param text  Not drawn.
		@param color  The color in a one-element array, as raygui takes a pointer, changed there; or null. Its alpha is kept.
		@return  0. */
	static function GuiColorPicker(bounds:Rectangle, text:String, color:Null<Array<Color>>):Int {
		if (color == null)
			color = [new Color(200, 0, 0, 255)];
		GuiColorPanel(bounds, null, color);
		var boundsHue = new Rectangle(bounds.x + bounds.width + GuiGetStyle(COLORPICKER, HUEBAR_PADDING), bounds.y, GuiGetStyle(COLORPICKER, HUEBAR_WIDTH),
			bounds.height);
		var hsv = rgbToHsv(f32(color[0].r / 255), f32(color[0].g / 255), f32(color[0].b / 255));
		var hue = [hsv.x];
		GuiColorBarHue(boundsHue, null, hue);
		var rgb = hsvToRgb(hue[0], hsv.y, hsv.z);
		color[0].r = Math.round(f32(rgb.x * 255));
		color[0].g = Math.round(f32(rgb.y * 255));
		color[0].b = Math.round(f32(rgb.z * 255));
		return 0;
	}

	/** Draws a color panel, saturation across and value down at the color's hue, dragged with the left button. See `GuiColorPanelHSV`
		for editing an HSV color.

		@param bounds  The panel.
		@param text  Not drawn.
		@param color  The color in a one-element array, as raygui takes a pointer, changed there when the panel changes it. Its alpha is
			kept.
		@return  0. */
	static function GuiColorPanel(bounds:Rectangle, text:String, color:Array<Color>):Int {
		var hsv = rgbToHsv(f32(color[0].r / 255), f32(color[0].g / 255), f32(color[0].b / 255));
		var prev = new Vector3(hsv.x, hsv.y, hsv.z);
		GuiColorPanelHSV(bounds, text, hsv);
		if (hsv.x != prev.x || hsv.y != prev.y || hsv.z != prev.z) {
			var rgb = hsvToRgb(hsv.x, hsv.y, hsv.z);
			color[0].r = Std.int(f32(255 * rgb.x));
			color[0].g = Std.int(f32(255 * rgb.y));
			color[0].b = Std.int(f32(255 * rgb.z));
		}
		return 0;
	}

	/** Draws an alpha bar, clear to opaque across over a checked background, its selector dragged with the left button.

		@param bounds  The bar.
		@param text  Not drawn.
		@param alpha  The alpha, 0 to 1, in `alpha[0]`.
		@return  0. */
	static function GuiColorBarAlpha(bounds:Rectangle, text:String, alpha:Array<Float>):Int {
		var state = guiState;
		var selectorHeight = GuiGetStyle(COLORPICKER, HUEBAR_SELECTOR_HEIGHT),
			overflow = GuiGetStyle(COLORPICKER, HUEBAR_SELECTOR_OVERFLOW);
		var selector = new Rectangle(bounds.x
			+ f32(alpha[0] * bounds.width)
			- idiv(selectorHeight, 2), bounds.y
			- overflow, selectorHeight,
			bounds.height
			+ overflow * 2);
		if (state != STATE_DISABLED && !guiLocked) {
			var mousePoint = GetMousePosition();
			if (guiControlExclusiveMode) {
				if (IsMouseButtonDown(MOUSE_BUTTON_LEFT)) {
					if (sameBounds(bounds, guiControlExclusiveRec)) {
						state = STATE_PRESSED;
						alpha[0] = clamp01(f32((mousePoint.x - bounds.x) / bounds.width));
					}
				} else
					endDrag();
			} else if (CheckCollisionPointRec(mousePoint, bounds) || CheckCollisionPointRec(mousePoint, selector)) {
				if (IsMouseButtonDown(MOUSE_BUTTON_LEFT)) {
					state = STATE_PRESSED;
					startDrag(bounds);
					alpha[0] = clamp01(f32((mousePoint.x - bounds.x) / bounds.width));
				} else
					state = STATE_FOCUSED;
			}
		}
		if (state != STATE_DISABLED) {
			var checksX = idiv(Std.int(bounds.width), COLORBARALPHA_CHECKED_SIZE),
				checksY = idiv(Std.int(bounds.height), COLORBARALPHA_CHECKED_SIZE);
			for (x in 0...checksX)
				for (y in 0...checksY)
					drawRectangle(new Rectangle(bounds.x + x * COLORBARALPHA_CHECKED_SIZE, bounds.y + y * COLORBARALPHA_CHECKED_SIZE,
						COLORBARALPHA_CHECKED_SIZE, COLORBARALPHA_CHECKED_SIZE),
						0, BLANK, Fade(styleColor(COLORPICKER, (x + y) % 2 != 0 ? BORDER_COLOR_DISABLED : BASE_COLOR_DISABLED), 0.4));
			DrawRectangleGradientEx(bounds, new Color(255, 255, 255, 0), new Color(255, 255, 255, 0), Fade(new Color(0, 0, 0, 255), guiAlpha),
				Fade(new Color(0, 0, 0, 255), guiAlpha));
		} else
			DrawRectangleGradientEx(bounds, Fade(styleColor(COLORPICKER, BASE_COLOR_DISABLED), 0.1), Fade(styleColor(COLORPICKER, BASE_COLOR_DISABLED), 0.1),
				Fade(styleColor(COLORPICKER, BORDER_COLOR_DISABLED), guiAlpha), Fade(styleColor(COLORPICKER, BORDER_COLOR_DISABLED), guiAlpha));
		drawRectangle(bounds, GuiGetStyle(COLORPICKER, BORDER_WIDTH), styleColor(COLORPICKER, BORDER + state * 3), BLANK);
		drawRectangle(selector, 0, BLANK, styleColor(COLORPICKER, BORDER + state * 3));
		return 0;
	}

	/** Draws a hue bar, the hues from red at the top round to red at the bottom, its selector dragged with the left button.

		@param bounds  The bar.
		@param text  Not drawn.
		@param value  The hue, in degrees from 0 to 359, in `value[0]`.
		@return  0. */
	static function GuiColorBarHue(bounds:Rectangle, text:String, value:Array<Float>):Int {
		var state = guiState;
		var selectorHeight = GuiGetStyle(COLORPICKER, HUEBAR_SELECTOR_HEIGHT),
			overflow = GuiGetStyle(COLORPICKER, HUEBAR_SELECTOR_OVERFLOW);
		var selector = new Rectangle(bounds.x
			- overflow, bounds.y
			+ f32(f32(value[0] / 360) * bounds.height)
			- idiv(selectorHeight, 2),
			bounds.width
			+ overflow * 2, selectorHeight);
		inline function hueAt(y:Float):Float {
			var hue = f32(f32((y - bounds.y) * 360) / bounds.height);
			return hue <= 0 ? 0 : hue >= 359 ? 359 : hue;
		}
		if (state != STATE_DISABLED && !guiLocked) {
			var mousePoint = GetMousePosition();
			if (guiControlExclusiveMode) {
				if (IsMouseButtonDown(MOUSE_BUTTON_LEFT)) {
					if (sameBounds(bounds, guiControlExclusiveRec)) {
						state = STATE_PRESSED;
						value[0] = hueAt(mousePoint.y);
					}
				} else
					endDrag();
			} else if (CheckCollisionPointRec(mousePoint, bounds) || CheckCollisionPointRec(mousePoint, selector)) {
				if (IsMouseButtonDown(MOUSE_BUTTON_LEFT)) {
					state = STATE_PRESSED;
					startDrag(bounds);
					value[0] = hueAt(mousePoint.y);
				} else
					state = STATE_FOCUSED;
			}
		}
		if (state != STATE_DISABLED) {
			var x = Std.int(bounds.x),
				w = Std.int(bounds.width),
				sixth = f32(bounds.height / 6),
				step = Std.int(Math.fceil(sixth));
			var hues = [
				new Color(255, 0, 0, 255),
				new Color(255, 255, 0, 255),
				new Color(0, 255, 0, 255),
				new Color(0, 255, 255, 255),
				new Color(0, 0, 255, 255),
				new Color(255, 0, 255, 255),
				new Color(255, 0, 0, 255)
			];
			for (i in 0...6)
				DrawRectangleGradientV(x, Std.int(bounds.y + f32(i * sixth)), w, i < 5 ? step : Std.int(sixth), Fade(hues[i], guiAlpha),
					Fade(hues[i + 1], guiAlpha));
		} else
			DrawRectangleGradientV(Std.int(bounds.x), Std.int(bounds.y), Std.int(bounds.width), Std.int(bounds.height),
				Fade(Fade(styleColor(COLORPICKER, BASE_COLOR_DISABLED), 0.1), guiAlpha), Fade(styleColor(COLORPICKER, BORDER_COLOR_DISABLED), guiAlpha));
		drawRectangle(bounds, GuiGetStyle(COLORPICKER, BORDER_WIDTH), styleColor(COLORPICKER, BORDER + state * 3), BLANK);
		drawRectangle(selector, 0, BLANK, styleColor(COLORPICKER, BORDER + state * 3));
		return 0;
	}

	/** Draws a color picker for an HSV color, a saturation and value panel with a hue bar beside it. See `GuiColorPicker` for editing
		a `Color`.

		Keeps the color as HSV, so its hue never shifts.

		@param bounds  The panel; the hue bar is beside it.
		@param text  Not drawn.
		@param colorHsv  The color, hue in degrees (x), saturation (y) and value (z) 0 to 1, changed in place; or null.
		@return  0. */
	static function GuiColorPickerHSV(bounds:Rectangle, text:String, colorHsv:Vector3):Int {
		if (colorHsv == null)
			colorHsv = rgbToHsv(f32(200 / 255), 0, 0);
		GuiColorPanelHSV(bounds, null, colorHsv);
		var boundsHue = new Rectangle(bounds.x + bounds.width + GuiGetStyle(COLORPICKER, HUEBAR_PADDING), bounds.y, GuiGetStyle(COLORPICKER, HUEBAR_WIDTH),
			bounds.height);
		var hue = [colorHsv.x];
		GuiColorBarHue(boundsHue, null, hue);
		colorHsv.x = hue[0];
		return 0;
	}

	/** Draws a color panel for an HSV color, saturation across and value down at its hue, dragged with the left button. See
		`GuiColorPanel` for editing a `Color`.

		@param bounds  The panel.
		@param text  Not drawn.
		@param colorHsv  The color, hue in degrees (x), saturation (y) and value (z) 0 to 1; saturation and value change in place.
		@return  0. */
	static function GuiColorPanelHSV(bounds:Rectangle, text:String, colorHsv:Vector3):Int {
		var state = guiState;
		var pickX = bounds.x + f32(colorHsv.y * bounds.width),
			pickY = bounds.y + f32(f32(1 - colorHsv.z) * bounds.height);
		var rgbHue = hsvToRgb(colorHsv.x, 1, 1);
		var maxHueCol = new Color(Std.int(f32(255 * rgbHue.x)), Std.int(f32(255 * rgbHue.y)), Std.int(f32(255 * rgbHue.z)), 255);
		inline function pick():Void {
			colorHsv.y = f32(f32(pickX - bounds.x) / bounds.width);
			colorHsv.z = f32(1 - f32(f32(pickY - bounds.y) / bounds.height));
		}
		if (state != STATE_DISABLED && !guiLocked) {
			var mousePoint = GetMousePosition();
			if (guiControlExclusiveMode) {
				if (IsMouseButtonDown(MOUSE_BUTTON_LEFT)) {
					if (sameBounds(bounds, guiControlExclusiveRec)) {
						pickX = mousePoint.x;
						pickY = mousePoint.y;
						if (pickX < bounds.x)
							pickX = bounds.x;
						if (pickX > bounds.x + bounds.width)
							pickX = bounds.x + bounds.width;
						if (pickY < bounds.y)
							pickY = bounds.y;
						if (pickY > bounds.y + bounds.height)
							pickY = bounds.y + bounds.height;
						pick();
					}
				} else
					endDrag();
			} else if (CheckCollisionPointRec(mousePoint, bounds)) {
				if (IsMouseButtonDown(MOUSE_BUTTON_LEFT)) {
					state = STATE_PRESSED;
					startDrag(bounds);
					pickX = mousePoint.x;
					pickY = mousePoint.y;
					pick();
				} else
					state = STATE_FOCUSED;
			}
		}
		var white = new Color(255, 255, 255, 255),
			black = new Color(0, 0, 0, 255);
		if (state != STATE_DISABLED) {
			DrawRectangleGradientEx(bounds, Fade(white, guiAlpha), Fade(white, guiAlpha), Fade(maxHueCol, guiAlpha), Fade(maxHueCol, guiAlpha));
			DrawRectangleGradientEx(bounds, Fade(black, 0), Fade(black, guiAlpha), Fade(black, guiAlpha), Fade(black, 0));
			var size = GuiGetStyle(COLORPICKER, COLOR_SELECTOR_SIZE);
			drawRectangle(new Rectangle(pickX - idiv(size, 2), pickY - idiv(size, 2), size, size), 0, BLANK, white);
		} else
			DrawRectangleGradientEx(bounds, Fade(Fade(styleColor(COLORPICKER, BASE_COLOR_DISABLED), 0.1), guiAlpha), Fade(Fade(black, 0.6), guiAlpha),
				Fade(Fade(black, 0.6), guiAlpha), Fade(Fade(styleColor(COLORPICKER, BORDER_COLOR_DISABLED), 0.6), guiAlpha));
		drawRectangle(bounds, GuiGetStyle(COLORPICKER, BORDER_WIDTH), styleColor(COLORPICKER, BORDER + state * 3), BLANK);
		return 0;
	}

	// ---- What the controls share ----
	static inline final STATUSBAR_HEIGHT = 24;
	static inline final GROUPBOX_LINE_THICK = 1;
	static inline final LINE_MARGIN_TEXT = 12;
	static inline final LINE_TEXT_PADDING = 4;
	static inline final PANEL_BORDER_WIDTH = 1;
	static inline final TABBAR_ITEM_WIDTH = 160;
	static inline final MIN_SCROLLBAR_WIDTH = 40;
	static inline final MIN_SCROLLBAR_HEIGHT = 40;
	static inline final MIN_MOUSE_WHEEL_SPEED = 20;
	static inline final TEXTBOX_AUTO_CURSOR_COOLDOWN = 40;
	static inline final TEXTBOX_AUTO_CURSOR_DELAY = 1;
	static inline final VALUEBOX_MAX_CHARS = 32;
	static inline final COLORBARALPHA_CHECKED_SIZE = 10;
	static inline final MESSAGEBOX_BUTTON_HEIGHT = 24;
	static inline final MESSAGEBOX_BUTTON_PADDING = 12;
	static inline final TEXTINPUTBOX_BUTTON_HEIGHT = 24;
	static inline final TEXTINPUTBOX_BUTTON_PADDING = 12;
	static inline final TEXTINPUTBOX_HEIGHT = 26;
	// raygui's 0.15f.
	static inline final GRID_ALPHA = 0.15000000596046448;

	// The text box cursor, shared by every text box, and its repeat counters.
	static var textBoxCursorIndex = 0;
	static var autoCursorCooldownCounter = 0;
	static var autoCursorDelayCounter = 0;
	// Whether the text input box's text box is being edited.
	static var textInputEditMode = false;

	// A color of a control's style.
	static inline function styleColor(control:Int, property:Int):Color {
		return GetColor(GuiGetStyle(control, property));
	}

	// A value held to 0 to 1, as the alpha bar holds it.
	static inline function clamp01(v:Float):Float {
		return v <= 0 ? 0 : v >= 1 ? 1 : v;
	}

	// A drag starting on a control, which keeps the input until the left button is released.
	static function startDrag(bounds:Rectangle):Void {
		guiControlExclusiveMode = true;
		guiControlExclusiveRec = new Rectangle(bounds.x, bounds.y, bounds.width, bounds.height);
	}

	// The drag ended.
	static function endDrag():Void {
		guiControlExclusiveMode = false;
		guiControlExclusiveRec = new Rectangle();
	}

	// The label beside a value box or spinner, right of it or, aligned left, left of it.
	static function sideLabel(control:Int, bounds:Rectangle, text:Null<String>):Rectangle {
		var label = new Rectangle();
		if (text != null) {
			label.width = stringWidth(text) + 2;
			label.height = GuiGetStyle(DEFAULT, TEXT_SIZE);
			label.x = bounds.x + bounds.width + GuiGetStyle(control, TEXT_PADDING);
			label.y = bounds.y + bounds.height / 2 - idiv(GuiGetStyle(DEFAULT, TEXT_SIZE), 2);
			if (GuiGetStyle(control, TEXT_ALIGNMENT) == TEXT_ALIGN_LEFT)
				label.x = bounds.x - label.width - GuiGetStyle(control, TEXT_PADDING);
		}
		return label;
	}

	// A value box drawn with its text centered, a cursor after it in edit mode, and its label.
	static function drawValueBox(bounds:Rectangle, textValue:String, label:Rectangle, text:Null<String>, state:Int, editMode:Bool):Void {
		var baseColor = BLANK;
		if (state == STATE_PRESSED)
			baseColor = styleColor(VALUEBOX, BASE_COLOR_PRESSED);
		else if (state == STATE_DISABLED)
			baseColor = styleColor(VALUEBOX, BASE_COLOR_DISABLED);
		var border = GuiGetStyle(VALUEBOX, BORDER_WIDTH);
		drawRectangle(bounds, border, styleColor(VALUEBOX, BORDER + state * 3), baseColor);
		drawText(textValue, textBounds(VALUEBOX, bounds), TEXT_ALIGN_CENTER, styleColor(VALUEBOX, TEXT + state * 3));
		if (editMode)
			drawRectangle(new Rectangle(bounds.x + idiv(stringWidth(textValue), 2) + bounds.width / 2 + 1, bounds.y + 2 * border, 4,
				bounds.height - 4 * border), 0,
				BLANK, styleColor(VALUEBOX, BORDER_COLOR_PRESSED));
		drawText(text, label, GuiGetStyle(VALUEBOX, TEXT_ALIGNMENT) == TEXT_ALIGN_RIGHT ? TEXT_ALIGN_LEFT : TEXT_ALIGN_RIGHT,
			styleColor(LABEL, TEXT + state * 3));
	}

	// The texts left and right of a slider or progress bar.
	static function sideTexts(control:Int, bounds:Rectangle, textLeft:Null<String>, textRight:Null<String>, color:Color):Void {
		var size = GuiGetStyle(DEFAULT, TEXT_SIZE),
			y = bounds.y + bounds.height / 2 - idiv(size, 2);
		if (textLeft != null) {
			var width = stringWidth(textLeft);
			drawText(textLeft, new Rectangle(bounds.x - width - GuiGetStyle(control, TEXT_PADDING), y, width, size), TEXT_ALIGN_RIGHT, color);
		}
		if (textRight != null) {
			var width = stringWidth(textRight);
			drawText(textRight, new Rectangle(bounds.x + bounds.width + GuiGetStyle(control, TEXT_PADDING), y, width, size), TEXT_ALIGN_LEFT, color);
		}
	}

	// A slider or slider bar, as raygui's GuiSliderPro: a handle sliderWidth wide, or a bar filled to the value for 0.
	static function sliderPro(bounds:Rectangle, textLeft:Null<String>, textRight:Null<String>, value:Null<Array<Float>>, minValue:Float, maxValue:Float,
			sliderWidth:Int):Int {
		var state = guiState;
		if (value == null)
			value = [(maxValue - minValue) / 2];
		var oldValue = value[0];
		var border = GuiGetStyle(SLIDER, BORDER_WIDTH),
			padding = GuiGetStyle(SLIDER, SLIDER_PADDING);
		var slider = new Rectangle(bounds.x, bounds.y + border + padding, 0, bounds.height - 2 * border - 2 * padding);
		inline function valueAt(x:Float):Float
			return f32(f32((maxValue - minValue) * f32(f32(x - bounds.x - idiv(sliderWidth, 2)) / (bounds.width - sliderWidth))) + minValue);
		if (state != STATE_DISABLED && !guiLocked) {
			var mousePoint = GetMousePosition();
			if (guiControlExclusiveMode) {
				if (IsMouseButtonDown(MOUSE_BUTTON_LEFT)) {
					if (sameBounds(bounds, guiControlExclusiveRec)) {
						state = STATE_PRESSED;
						value[0] = valueAt(mousePoint.x);
					}
				} else
					endDrag();
			} else if (CheckCollisionPointRec(mousePoint, bounds)) {
				if (IsMouseButtonDown(MOUSE_BUTTON_LEFT)) {
					state = STATE_PRESSED;
					startDrag(bounds);
					if (!CheckCollisionPointRec(mousePoint, slider))
						value[0] = valueAt(mousePoint.x);
				} else
					state = STATE_FOCUSED;
			}
			if (value[0] > maxValue)
				value[0] = maxValue;
			else if (value[0] < minValue)
				value[0] = minValue;
		}
		var result = oldValue == value[0] ? 0 : 1;
		var sliderValue = f32(f32(f32(value[0] - minValue) / f32(maxValue - minValue)) * (bounds.width - sliderWidth - 2 * border));
		if (sliderWidth > 0) {
			slider.x += sliderValue;
			slider.width = sliderWidth;
			if (slider.x <= bounds.x + border)
				slider.x = bounds.x + border;
			else if (slider.x + slider.width >= bounds.x + bounds.width)
				slider.x = bounds.x + bounds.width - slider.width - border;
		} else if (sliderWidth == 0) {
			slider.x += border;
			slider.width = sliderValue;
			if (slider.width > bounds.width)
				slider.width = bounds.width - 2 * border;
		}
		drawRectangle(bounds, border, styleColor(SLIDER, BORDER + state * 3),
			styleColor(SLIDER, state != STATE_DISABLED ? BASE_COLOR_NORMAL : BASE_COLOR_DISABLED));
		if (state == STATE_NORMAL)
			drawRectangle(slider, 0, BLANK, styleColor(SLIDER, BASE_COLOR_PRESSED));
		else if (state == STATE_FOCUSED)
			drawRectangle(slider, 0, BLANK, styleColor(SLIDER, TEXT_COLOR_FOCUSED));
		else if (state == STATE_PRESSED)
			drawRectangle(slider, 0, BLANK, styleColor(SLIDER, TEXT_COLOR_PRESSED));
		sideTexts(SLIDER, bounds, textLeft, textRight, styleColor(SLIDER, TEXT + state * 3));
		return result;
	}

	// A scroll bar, as raygui's GuiScrollBar: its slider dragged, or moved to a click on the bar, by its arrows, or by the mouse wheel.
	// Returns the value, held to the range.
	static function scrollBar(bounds:Rectangle, value:Int, minValue:Int, maxValue:Int):Int {
		var state = guiState;
		var isVertical = !(bounds.width > bounds.height);
		var border = GuiGetStyle(SCROLLBAR, BORDER_WIDTH);
		var spinnerSize = GuiGetStyle(SCROLLBAR,
			ARROWS_VISIBLE) != 0 ? (isVertical ? Std.int(bounds.width) - 2 * border : Std.int(bounds.height) - 2 * border) : 0;
		if (value > maxValue)
			value = maxValue;
		if (value < minValue)
			value = minValue;
		var valueRange = maxValue - minValue;
		if (valueRange <= 0)
			valueRange = 1;
		var sliderSize = GuiGetStyle(SCROLLBAR, SCROLL_SLIDER_SIZE);
		if (sliderSize < 1)
			sliderSize = 1;
		var scrollPadding = GuiGetStyle(SCROLLBAR, SCROLL_PADDING),
			sliderPadding = GuiGetStyle(SCROLLBAR, SCROLL_SLIDER_PADDING);
		var arrowUpLeft = new Rectangle(bounds.x + border, bounds.y + border, spinnerSize, spinnerSize);
		var arrowDownRight, scrollbar, slider;
		if (isVertical) {
			arrowDownRight = new Rectangle(bounds.x + border, bounds.y + bounds.height - spinnerSize - border, spinnerSize, spinnerSize);
			scrollbar = new Rectangle(bounds.x
				+ border
				+ scrollPadding, arrowUpLeft.y
				+ arrowUpLeft.height, bounds.width
				- 2 * (border + scrollPadding),
				bounds.height
				- arrowUpLeft.height
				- arrowDownRight.height
				- 2 * border);
			sliderSize = sliderSize >= scrollbar.height ? Std.int(scrollbar.height) - 2 : sliderSize;
			slider = new Rectangle(bounds.x
				+ border
				+ sliderPadding,
				scrollbar.y
				+ Std.int(f32(f32((value - minValue) / valueRange) * (scrollbar.height - sliderSize))),
				bounds.width
				- 2 * (border + sliderPadding), sliderSize);
		} else {
			arrowDownRight = new Rectangle(bounds.x + bounds.width - spinnerSize - border, bounds.y + border, spinnerSize, spinnerSize);
			scrollbar = new Rectangle(arrowUpLeft.x
				+ arrowUpLeft.width, bounds.y
				+ border
				+ scrollPadding,
				bounds.width
				- arrowUpLeft.width
				- arrowDownRight.width
				- 2 * border, bounds.height
				- 2 * (border + scrollPadding));
			sliderSize = sliderSize >= scrollbar.width ? Std.int(scrollbar.width) - 2 : sliderSize;
			slider = new Rectangle(scrollbar.x
				+ Std.int(f32(f32((value - minValue) / valueRange) * (scrollbar.width - sliderSize))),
				bounds.y
				+ border
				+ sliderPadding, sliderSize, bounds.height
				- 2 * (border + sliderPadding));
		}
		inline function valueAt(mousePoint:Vector2):Int
			return isVertical ? Std.int(f32(f32((mousePoint.y - scrollbar.y - slider.height / 2) * valueRange) / (scrollbar.height - slider.height))
				+ minValue) : Std.int(f32(f32((mousePoint.x - scrollbar.x - slider.width / 2) * valueRange) / (scrollbar.width - slider.width)) + minValue);
		if (state != STATE_DISABLED && !guiLocked) {
			var mousePoint = GetMousePosition();
			if (guiControlExclusiveMode) {
				if (IsMouseButtonDown(MOUSE_BUTTON_LEFT)
					&& !CheckCollisionPointRec(mousePoint, arrowUpLeft)
					&& !CheckCollisionPointRec(mousePoint, arrowDownRight)) {
					if (sameBounds(bounds, guiControlExclusiveRec)) {
						state = STATE_PRESSED;
						value = valueAt(mousePoint);
					}
				} else
					endDrag();
			} else if (CheckCollisionPointRec(mousePoint, bounds)) {
				state = STATE_FOCUSED;
				var wheel = Std.int(GetMouseWheelMove());
				if (wheel != 0)
					value += wheel;
				if (IsMouseButtonPressed(MOUSE_BUTTON_LEFT)) {
					startDrag(bounds);
					if (CheckCollisionPointRec(mousePoint, arrowUpLeft))
						value -= idiv(valueRange, GuiGetStyle(SCROLLBAR, SCROLL_SPEED));
					else if (CheckCollisionPointRec(mousePoint, arrowDownRight))
						value += idiv(valueRange, GuiGetStyle(SCROLLBAR, SCROLL_SPEED));
					else if (!CheckCollisionPointRec(mousePoint, slider))
						value = valueAt(mousePoint);
					state = STATE_PRESSED;
				}
			}
			if (value > maxValue)
				value = maxValue;
			if (value < minValue)
				value = minValue;
		}
		drawRectangle(bounds, border, styleColor(LISTVIEW, BORDER + state * 3), styleColor(DEFAULT, BORDER_COLOR_DISABLED));
		drawRectangle(scrollbar, 0, BLANK, styleColor(BUTTON, BASE_COLOR_NORMAL));
		drawRectangle(slider, 0, BLANK, styleColor(SLIDER, BORDER + state * 3));
		if (GuiGetStyle(SCROLLBAR, ARROWS_VISIBLE) != 0) {
			var side = isVertical ? bounds.width : bounds.height;
			drawText(isVertical ? "#121#" : "#118#", new Rectangle(arrowUpLeft.x, arrowUpLeft.y, side, side), TEXT_ALIGN_CENTER,
				styleColor(SCROLLBAR, TEXT + state * 3));
			drawText(isVertical ? "#120#" : "#119#", new Rectangle(arrowDownRight.x, arrowDownRight.y, side, side), TEXT_ALIGN_CENTER,
				styleColor(SCROLLBAR, TEXT + state * 3));
		}
		return value;
	}
	#end
}
