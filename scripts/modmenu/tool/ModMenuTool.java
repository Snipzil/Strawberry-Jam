import com.jpexs.decompiler.flash.SWF;
import com.jpexs.decompiler.flash.abc.ABC;
import com.jpexs.decompiler.flash.abc.ScriptPack;
import com.jpexs.decompiler.flash.abc.avm2.parser.script.AbcIndexing;
import com.jpexs.decompiler.flash.exporters.modes.ScriptExportMode;
import com.jpexs.decompiler.flash.exporters.settings.ScriptExportSettings;
import com.jpexs.decompiler.flash.importers.As3ScriptReplacerFactory;
import com.jpexs.decompiler.flash.importers.As3ScriptReplacerInterface;
import com.jpexs.decompiler.flash.tags.ABCContainerTag;
import java.io.*;
import java.nio.file.*;
import java.util.*;

public class ModMenuTool {
  static List<ScriptPack> modMenuPacks(SWF swf) throws Exception {
    List<ABC> abcs = new ArrayList<>();
    for (ABCContainerTag t : swf.getAbcList()) abcs.add(t.getABC());
    List<ScriptPack> out = new ArrayList<>();
    for (ABC abc : abcs)
      for (ScriptPack p : abc.getScriptPacks(null, abcs))
        if (p.getClassPath().toString().startsWith("gui.ModMenu")) out.add(p);
    return out;
  }

  public static void main(String[] a) throws Exception {
    String mode = a[0];
    SWF swf = new SWF(new FileInputStream(a[1]), false);
    List<ScriptPack> packs = modMenuPacks(swf);
    final List<String> order = Arrays.asList("ModMenuUIHelper","ModMenuScroller","ModMenuTabManager","ModMenuContentBuilder","ModMenu","ModMenuFeatures");
    packs.sort((x, y) -> Integer.compare(order.indexOf(x.getClassPath().className), order.indexOf(y.getClassPath().className)));
    if (mode.equals("dump")) {
      AbcIndexing idx = new AbcIndexing(swf);
      ScriptExportSettings ses = new ScriptExportSettings(ScriptExportMode.AS, false, false, false, false, false);
      for (ScriptPack p : packs) {
        File dir = new File(a[2], "s" + p.scriptIndex);
        dir.mkdirs();
        File f = p.export(idx, new File(dir, p.getClassPath().className + ".as"), ses, false);
        System.out.println("script=" + p.scriptIndex + " " + p.getClassPath() + " -> " + f);
      }
    } else if (mode.equals("replace")) {
      String outSwf = a[2]; File srcDir = new File(a[3]);
      As3ScriptReplacerInterface r = As3ScriptReplacerFactory.createFFDec();
      List<SWF> swfs = Collections.singletonList(swf);
      int n = 0;
      for (ScriptPack p : packs) {
        String cls = p.getClassPath().className;
        File src = new File(srcDir, cls + ".as");
        if (!src.exists()) { System.out.println("skip script=" + p.scriptIndex + " " + cls + " (no source)"); continue; }
        String code = new String(Files.readAllBytes(src.toPath()), "UTF-8");
        System.out.println("replacing script=" + p.scriptIndex + " " + p.getClassPath() + " from " + src.getName());
        r.initReplacement(p, swfs);
        r.replaceScript(p, code, swfs);
        r.deinitReplacement(p);
        n++;
      }
      try (FileOutputStream fos = new FileOutputStream(outSwf)) { swf.saveTo(fos); }
      System.out.println("replaced " + n + " packs, saved " + outSwf);
    }
  }
}
