package helix.platform.adapters.shared;

import haxe.io.Bytes;
import haxe.io.Path;

/** Provides writing a file whole or not at all, for the adapters that write files: the bytes go to a temporary file beside it, which then
	replaces it in one step, so a reader never sees half a file and a failure leaves the old one.

	Natively the replacing is `atomic_file.c`'s, since Windows' rename (and so `FileSystem.rename`) refuses a file that exists. Safe to
	call on several threads at once. */
@:noCompletion
class AtomicFile {
	static var serial = 0;
	static var lock = new sys.thread.Mutex();

	/** Writes a file, making its directory and the directories above it first.

		@param path  The file's path.
		@param bytes  Its contents.
		@throws String  The directory can't be made, or the file can't be written or replaced; the old file, if any, is left. */
	public static function write(path:String, bytes:Bytes):Void {
		makeDirectory(Path.directory(path));
		lock.acquire();
		var temporary = path + ".part-" + (++serial);
		lock.release();
		try {
			sys.io.File.saveBytes(temporary, bytes);
			if (replace(temporary, path) == 0)
				throw 'Could not replace $path';
		} catch (error:Dynamic) {
			if (sys.FileSystem.exists(temporary))
				sys.FileSystem.deleteFile(temporary);
			throw error;
		}
	}

	// Makes dir and its parents. Two threads may make the same directory at once: one that exists by the time making it fails is fine.
	static function makeDirectory(dir:String):Void
		if (dir != "")
			try
				sys.FileSystem.createDirectory(dir)
			catch (error:Dynamic)
				if (!sys.FileSystem.exists(dir) || !sys.FileSystem.isDirectory(dir))
					throw error;

	// Renames from over to, replacing it in one step: 1 when it did.
	static function replace(from:String, to:String):Int {
		#if cpp
		return AtomicFileC.replace(from, to);
		#else
		// The interpreter's tests: the target's rename, which replaces an existing file on every system but Windows.
		if (Sys.systemName() == "Windows" && sys.FileSystem.exists(to))
			sys.FileSystem.deleteFile(to);
		sys.FileSystem.rename(from, to);
		return 1;
		#end
	}
}

#if cpp
@:buildXml("<set name='HELIX_PLATFORM' value='${haxelib:helix-platform}' unless='HELIX_PLATFORM'/>
<files id='helix-platform-shared-atomic-file' dir='${HELIX_PLATFORM}/src/helix/platform/adapters'>
 <compilerflag value='-I${HELIX_PLATFORM}/src/helix/platform/adapters/shared'/>
 <compilerflag value='-DNDEBUG' unless='debug'/><compilerflag value='-O2' if='windows' unless='debug'/><compilerflag value='-O3' unless='windows||debug'/>
 <depend name='${HELIX_PLATFORM}/src/helix/platform/adapters/shared/atomic_file.h'/>
 <file name='shared/atomic_file.c'/>
</files>
<files id='haxe'><compilerflag value='-I${HELIX_PLATFORM}/src/helix/platform/adapters/shared'/></files>
<target id='haxe'>
 <files id='helix-platform-shared-atomic-file'/>
</target>")
/** Provides `atomic_file.c`, built with the program by hxcpp. */
@:include("atomic_file.h")
private extern class AtomicFileC {
	@:native("helix_replace_file") static function replace(from:cpp.ConstCharStar, to:cpp.ConstCharStar):Int;
}
#end
