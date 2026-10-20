package helix.ui;

/** When a scrolling widget's scrollbar (a list's, a scroll area's) is drawn. Hidden or not, the widget scrolls alike: by the wheel, a drag and
	keys. */
enum ScrollbarVisibility {
	/** Always: with content that fits, its thumb the track's whole length, dimmed. */
	Always;

	/** Only while the content is longer than the view: there's more to scroll to. */
	WhenNeeded;

	/** Never: the content takes the bar's room too. */
	Never;
}
