package helix.box2d;

/** These colors are used for debug draw and mostly match the named SVG colors. */
enum abstract B2HexColor(Int) to Int {
	/** The SVG color alice blue, 0xF0F8FF. */
	var b2_colorAliceBlue = 15792383;

	/** The SVG color antique white, 0xFAEBD7. */
	var b2_colorAntiqueWhite = 16444375;

	/** The SVG color aqua, 0x00FFFF. */
	var b2_colorAqua = 65535;

	/** The SVG color aquamarine, 0x7FFFD4. */
	var b2_colorAquamarine = 8388564;

	/** The SVG color azure, 0xF0FFFF. */
	var b2_colorAzure = 15794175;

	/** The SVG color beige, 0xF5F5DC. */
	var b2_colorBeige = 16119260;

	/** The SVG color bisque, 0xFFE4C4. */
	var b2_colorBisque = 16770244;

	/** The SVG color black, 0x000000. */
	var b2_colorBlack = 0;

	/** The SVG color blanched almond, 0xFFEBCD. */
	var b2_colorBlanchedAlmond = 16772045;

	/** The SVG color blue, 0x0000FF. */
	var b2_colorBlue = 255;

	/** The SVG color blue violet, 0x8A2BE2. */
	var b2_colorBlueViolet = 9055202;

	/** The SVG color brown, 0xA52A2A. */
	var b2_colorBrown = 10824234;

	/** The SVG color burlywood, 0xDEB887. */
	var b2_colorBurlywood = 14596231;

	/** The SVG color cadet blue, 0x5F9EA0. */
	var b2_colorCadetBlue = 6266528;

	/** The SVG color chartreuse, 0x7FFF00. */
	var b2_colorChartreuse = 8388352;

	/** The SVG color chocolate, 0xD2691E. */
	var b2_colorChocolate = 13789470;

	/** The SVG color coral, 0xFF7F50. */
	var b2_colorCoral = 16744272;

	/** The SVG color cornflower blue, 0x6495ED. */
	var b2_colorCornflowerBlue = 6591981;

	/** The SVG color cornsilk, 0xFFF8DC. */
	var b2_colorCornsilk = 16775388;

	/** The SVG color crimson, 0xDC143C. */
	var b2_colorCrimson = 14423100;

	/** The SVG color cyan, 0x00FFFF. */
	var b2_colorCyan = 65535;

	/** The SVG color dark blue, 0x00008B. */
	var b2_colorDarkBlue = 139;

	/** The SVG color dark cyan, 0x008B8B. */
	var b2_colorDarkCyan = 35723;

	/** The SVG color dark golden rod, 0xB8860B. */
	var b2_colorDarkGoldenRod = 12092939;

	/** The SVG color dark gray, 0xA9A9A9. */
	var b2_colorDarkGray = 11119017;

	/** The SVG color dark green, 0x006400. */
	var b2_colorDarkGreen = 25600;

	/** The SVG color dark khaki, 0xBDB76B. */
	var b2_colorDarkKhaki = 12433259;

	/** The SVG color dark magenta, 0x8B008B. */
	var b2_colorDarkMagenta = 9109643;

	/** The SVG color dark olive green, 0x556B2F. */
	var b2_colorDarkOliveGreen = 5597999;

	/** The SVG color dark orange, 0xFF8C00. */
	var b2_colorDarkOrange = 16747520;

	/** The SVG color dark orchid, 0x9932CC. */
	var b2_colorDarkOrchid = 10040012;

	/** The SVG color dark red, 0x8B0000. */
	var b2_colorDarkRed = 9109504;

	/** The SVG color dark salmon, 0xE9967A. */
	var b2_colorDarkSalmon = 15308410;

	/** The SVG color dark sea green, 0x8FBC8F. */
	var b2_colorDarkSeaGreen = 9419919;

	/** The SVG color dark slate blue, 0x483D8B. */
	var b2_colorDarkSlateBlue = 4734347;

	/** The SVG color dark slate gray, 0x2F4F4F. */
	var b2_colorDarkSlateGray = 3100495;

	/** The SVG color dark turquoise, 0x00CED1. */
	var b2_colorDarkTurquoise = 52945;

	/** The SVG color dark violet, 0x9400D3. */
	var b2_colorDarkViolet = 9699539;

	/** The SVG color deep pink, 0xFF1493. */
	var b2_colorDeepPink = 16716947;

	/** The SVG color deep sky blue, 0x00BFFF. */
	var b2_colorDeepSkyBlue = 49151;

	/** The SVG color dim gray, 0x696969. */
	var b2_colorDimGray = 6908265;

	/** The SVG color dodger blue, 0x1E90FF. */
	var b2_colorDodgerBlue = 2003199;

	/** The SVG color fire brick, 0xB22222. */
	var b2_colorFireBrick = 11674146;

	/** The SVG color floral white, 0xFFFAF0. */
	var b2_colorFloralWhite = 16775920;

	/** The SVG color forest green, 0x228B22. */
	var b2_colorForestGreen = 2263842;

	/** The SVG color fuchsia, 0xFF00FF. */
	var b2_colorFuchsia = 16711935;

	/** The SVG color gainsboro, 0xDCDCDC. */
	var b2_colorGainsboro = 14474460;

	/** The SVG color ghost white, 0xF8F8FF. */
	var b2_colorGhostWhite = 16316671;

	/** The SVG color gold, 0xFFD700. */
	var b2_colorGold = 16766720;

	/** The SVG color golden rod, 0xDAA520. */
	var b2_colorGoldenRod = 14329120;

	/** The SVG color gray, 0x808080. */
	var b2_colorGray = 8421504;

	/** The SVG color green, 0x008000. */
	var b2_colorGreen = 32768;

	/** The SVG color green yellow, 0xADFF2F. */
	var b2_colorGreenYellow = 11403055;

	/** The SVG color honey dew, 0xF0FFF0. */
	var b2_colorHoneyDew = 15794160;

	/** The SVG color hot pink, 0xFF69B4. */
	var b2_colorHotPink = 16738740;

	/** The SVG color indian red, 0xCD5C5C. */
	var b2_colorIndianRed = 13458524;

	/** The SVG color indigo, 0x4B0082. */
	var b2_colorIndigo = 4915330;

	/** The SVG color ivory, 0xFFFFF0. */
	var b2_colorIvory = 16777200;

	/** The SVG color khaki, 0xF0E68C. */
	var b2_colorKhaki = 15787660;

	/** The SVG color lavender, 0xE6E6FA. */
	var b2_colorLavender = 15132410;

	/** The SVG color lavender blush, 0xFFF0F5. */
	var b2_colorLavenderBlush = 16773365;

	/** The SVG color lawn green, 0x7CFC00. */
	var b2_colorLawnGreen = 8190976;

	/** The SVG color lemon chiffon, 0xFFFACD. */
	var b2_colorLemonChiffon = 16775885;

	/** The SVG color light blue, 0xADD8E6. */
	var b2_colorLightBlue = 11393254;

	/** The SVG color light coral, 0xF08080. */
	var b2_colorLightCoral = 15761536;

	/** The SVG color light cyan, 0xE0FFFF. */
	var b2_colorLightCyan = 14745599;

	/** The SVG color light golden rod yellow, 0xFAFAD2. */
	var b2_colorLightGoldenRodYellow = 16448210;

	/** The SVG color light gray, 0xD3D3D3. */
	var b2_colorLightGray = 13882323;

	/** The SVG color light green, 0x90EE90. */
	var b2_colorLightGreen = 9498256;

	/** The SVG color light pink, 0xFFB6C1. */
	var b2_colorLightPink = 16758465;

	/** The SVG color light salmon, 0xFFA07A. */
	var b2_colorLightSalmon = 16752762;

	/** The SVG color light sea green, 0x20B2AA. */
	var b2_colorLightSeaGreen = 2142890;

	/** The SVG color light sky blue, 0x87CEFA. */
	var b2_colorLightSkyBlue = 8900346;

	/** The SVG color light slate gray, 0x778899. */
	var b2_colorLightSlateGray = 7833753;

	/** The SVG color light steel blue, 0xB0C4DE. */
	var b2_colorLightSteelBlue = 11584734;

	/** The SVG color light yellow, 0xFFFFE0. */
	var b2_colorLightYellow = 16777184;

	/** The SVG color lime, 0x00FF00. */
	var b2_colorLime = 65280;

	/** The SVG color lime green, 0x32CD32. */
	var b2_colorLimeGreen = 3329330;

	/** The SVG color linen, 0xFAF0E6. */
	var b2_colorLinen = 16445670;

	/** The SVG color magenta, 0xFF00FF. */
	var b2_colorMagenta = 16711935;

	/** The SVG color maroon, 0x800000. */
	var b2_colorMaroon = 8388608;

	/** The SVG color medium aqua marine, 0x66CDAA. */
	var b2_colorMediumAquaMarine = 6737322;

	/** The SVG color medium blue, 0x0000CD. */
	var b2_colorMediumBlue = 205;

	/** The SVG color medium orchid, 0xBA55D3. */
	var b2_colorMediumOrchid = 12211667;

	/** The SVG color medium purple, 0x9370DB. */
	var b2_colorMediumPurple = 9662683;

	/** The SVG color medium sea green, 0x3CB371. */
	var b2_colorMediumSeaGreen = 3978097;

	/** The SVG color medium slate blue, 0x7B68EE. */
	var b2_colorMediumSlateBlue = 8087790;

	/** The SVG color medium spring green, 0x00FA9A. */
	var b2_colorMediumSpringGreen = 64154;

	/** The SVG color medium turquoise, 0x48D1CC. */
	var b2_colorMediumTurquoise = 4772300;

	/** The SVG color medium violet red, 0xC71585. */
	var b2_colorMediumVioletRed = 13047173;

	/** The SVG color midnight blue, 0x191970. */
	var b2_colorMidnightBlue = 1644912;

	/** The SVG color mint cream, 0xF5FFFA. */
	var b2_colorMintCream = 16121850;

	/** The SVG color misty rose, 0xFFE4E1. */
	var b2_colorMistyRose = 16770273;

	/** The SVG color moccasin, 0xFFE4B5. */
	var b2_colorMoccasin = 16770229;

	/** The SVG color navajo white, 0xFFDEAD. */
	var b2_colorNavajoWhite = 16768685;

	/** The SVG color navy, 0x000080. */
	var b2_colorNavy = 128;

	/** The SVG color old lace, 0xFDF5E6. */
	var b2_colorOldLace = 16643558;

	/** The SVG color olive, 0x808000. */
	var b2_colorOlive = 8421376;

	/** The SVG color olive drab, 0x6B8E23. */
	var b2_colorOliveDrab = 7048739;

	/** The SVG color orange, 0xFFA500. */
	var b2_colorOrange = 16753920;

	/** The SVG color orange red, 0xFF4500. */
	var b2_colorOrangeRed = 16729344;

	/** The SVG color orchid, 0xDA70D6. */
	var b2_colorOrchid = 14315734;

	/** The SVG color pale golden rod, 0xEEE8AA. */
	var b2_colorPaleGoldenRod = 15657130;

	/** The SVG color pale green, 0x98FB98. */
	var b2_colorPaleGreen = 10025880;

	/** The SVG color pale turquoise, 0xAFEEEE. */
	var b2_colorPaleTurquoise = 11529966;

	/** The SVG color pale violet red, 0xDB7093. */
	var b2_colorPaleVioletRed = 14381203;

	/** The SVG color papaya whip, 0xFFEFD5. */
	var b2_colorPapayaWhip = 16773077;

	/** The SVG color peach puff, 0xFFDAB9. */
	var b2_colorPeachPuff = 16767673;

	/** The SVG color peru, 0xCD853F. */
	var b2_colorPeru = 13468991;

	/** The SVG color pink, 0xFFC0CB. */
	var b2_colorPink = 16761035;

	/** The SVG color plum, 0xDDA0DD. */
	var b2_colorPlum = 14524637;

	/** The SVG color powder blue, 0xB0E0E6. */
	var b2_colorPowderBlue = 11591910;

	/** The SVG color purple, 0x800080. */
	var b2_colorPurple = 8388736;

	/** The SVG color rebecca purple, 0x663399. */
	var b2_colorRebeccaPurple = 6697881;

	/** The SVG color red, 0xFF0000. */
	var b2_colorRed = 16711680;

	/** The SVG color rosy brown, 0xBC8F8F. */
	var b2_colorRosyBrown = 12357519;

	/** The SVG color royal blue, 0x4169E1. */
	var b2_colorRoyalBlue = 4286945;

	/** The SVG color saddle brown, 0x8B4513. */
	var b2_colorSaddleBrown = 9127187;

	/** The SVG color salmon, 0xFA8072. */
	var b2_colorSalmon = 16416882;

	/** The SVG color sandy brown, 0xF4A460. */
	var b2_colorSandyBrown = 16032864;

	/** The SVG color sea green, 0x2E8B57. */
	var b2_colorSeaGreen = 3050327;

	/** The SVG color sea shell, 0xFFF5EE. */
	var b2_colorSeaShell = 16774638;

	/** The SVG color sienna, 0xA0522D. */
	var b2_colorSienna = 10506797;

	/** The SVG color silver, 0xC0C0C0. */
	var b2_colorSilver = 12632256;

	/** The SVG color sky blue, 0x87CEEB. */
	var b2_colorSkyBlue = 8900331;

	/** The SVG color slate blue, 0x6A5ACD. */
	var b2_colorSlateBlue = 6970061;

	/** The SVG color slate gray, 0x708090. */
	var b2_colorSlateGray = 7372944;

	/** The SVG color snow, 0xFFFAFA. */
	var b2_colorSnow = 16775930;

	/** The SVG color spring green, 0x00FF7F. */
	var b2_colorSpringGreen = 65407;

	/** The SVG color steel blue, 0x4682B4. */
	var b2_colorSteelBlue = 4620980;

	/** The SVG color tan, 0xD2B48C. */
	var b2_colorTan = 13808780;

	/** The SVG color teal, 0x008080. */
	var b2_colorTeal = 32896;

	/** The SVG color thistle, 0xD8BFD8. */
	var b2_colorThistle = 14204888;

	/** The SVG color tomato, 0xFF6347. */
	var b2_colorTomato = 16737095;

	/** The SVG color turquoise, 0x40E0D0. */
	var b2_colorTurquoise = 4251856;

	/** The SVG color violet, 0xEE82EE. */
	var b2_colorViolet = 15631086;

	/** The SVG color wheat, 0xF5DEB3. */
	var b2_colorWheat = 16113331;

	/** The SVG color white, 0xFFFFFF. */
	var b2_colorWhite = 16777215;

	/** The SVG color white smoke, 0xF5F5F5. */
	var b2_colorWhiteSmoke = 16119285;

	/** The SVG color yellow, 0xFFFF00. */
	var b2_colorYellow = 16776960;

	/** The SVG color yellow green, 0x9ACD32. */
	var b2_colorYellowGreen = 10145074;

	/** The Box2D logo color red, 0xDC3132. */
	var b2_colorBox2DRed = 14430514;

	/** The Box2D logo color blue, 0x30AEBF. */
	var b2_colorBox2DBlue = 3190463;

	/** The Box2D logo color green, 0x8CC924. */
	var b2_colorBox2DGreen = 9226532;

	/** The Box2D logo color yellow, 0xFFEE8C. */
	var b2_colorBox2DYellow = 16772748;
}
