import com.jpexs.decompiler.flash.SWF;
import com.jpexs.decompiler.flash.SWFCompression;
import java.io.*;
public class SwfCompress {
  public static void main(String[] a) throws Exception {
    SWF swf = new SWF(new FileInputStream(a[0]), false);
    swf.compression = SWFCompression.LZMA;
    try (FileOutputStream fos = new FileOutputStream(a[1])) { swf.saveTo(fos); }
    System.out.println("saved " + a[1]);
  }
}
