package hybrid;
import haxe.io.Bytes;
/** Minimal, bounded RIFF decoder for this experiment's mono PCM16/44100 assets. */
class Wav {
 public static function decode(bytes:Bytes):Bytes {
  if(bytes.length<44||bytes.getString(0,4)!="RIFF"||bytes.getString(8,4)!="WAVE"||bytes.getInt32(4)!=bytes.length-8)throw "Invalid WAV header";
  var at=12,format=false,data:Bytes=null;
  while(at+8<=bytes.length){
   var kind=bytes.getString(at,4),length=bytes.getInt32(at+4);at+=8;
   if(length<0||length>bytes.length-at)throw "Truncated WAV chunk";
   if(kind=="fmt "){
    if(format||length<16||bytes.getUInt16(at)!=1||bytes.getUInt16(at+2)!=1||bytes.getInt32(at+4)!=44100||bytes.getInt32(at+8)!=88200||bytes.getUInt16(at+12)!=2||bytes.getUInt16(at+14)!=16)throw "Unsupported WAV format";
    format=true;
   }else if(kind=="data"){
    if(data!=null||length==0||length%2!=0||length>44100*8)throw "Invalid WAV sample data";
    data=Bytes.alloc(length*2);for(i in 0...Std.int(length/2)){var sample=bytes.getUInt16(at+i*2);if(sample>=32768)sample-=65536;data.setFloat(i*4,sample/32768.);}
   }
   at+=length+(length&1);
  }
  if(!format||data==null||at!=bytes.length)throw "Incomplete WAV";return data;
 }
}
