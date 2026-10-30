package helix.platform.adapters.shared.dom;

import js.html.EventTarget;

/** Holds the listeners one page adapter installed, so its `dispose` removes them all. */
@:noCompletion
class DomListeners {
	final installed:Array<{
		target:EventTarget,
		name:String,
		listener:Dynamic->Void,
		capture:Bool
	}> = [];

	/** Creates one with nothing installed. */
	public function new() {}

	/** Installs a listener.

		@param target  The window, the document or an element.
		@param name  The event's name.
		@param listener  Called with each event.
		@param capture  Optional. True to hear it before the page's elements do. Every listener may prevent the default. */
	public function add(target:EventTarget, name:String, listener:Dynamic->Void, capture = false):Void {
		target.addEventListener(name, listener, {capture: capture, passive: false});
		installed.push({
			target: target,
			name: name,
			listener: listener,
			capture: capture
		});
	}

	/** Removes one listener it installed.

		@param listener  The listener. */
	public function remove(listener:Dynamic->Void):Void {
		for (i in 0...installed.length)
			if (installed[i].listener == listener) {
				var l = installed[i];
				l.target.removeEventListener(l.name, l.listener, l.capture);
				installed.splice(i, 1);
				return;
			}
	}

	/** Removes every listener it installed. */
	public function removeAll():Void {
		for (l in installed)
			l.target.removeEventListener(l.name, l.listener, l.capture);
		installed.resize(0);
	}
}
