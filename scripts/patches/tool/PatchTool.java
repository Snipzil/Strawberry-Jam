import com.jpexs.decompiler.flash.SWF;
import com.jpexs.decompiler.flash.abc.ABC;
import com.jpexs.decompiler.flash.abc.ScriptPack;
import com.jpexs.decompiler.flash.abc.avm2.parser.script.AbcIndexing;
import com.jpexs.decompiler.flash.abc.avm2.parser.script.ActionScript3Parser;
import com.jpexs.decompiler.flash.importers.As3ScriptReplacerFactory;
import com.jpexs.decompiler.flash.importers.As3ScriptReplacerInterface;
import com.jpexs.decompiler.flash.tags.ABCContainerTag;
import com.jpexs.decompiler.flash.tags.Tag;
import java.io.*;
import java.nio.file.*;
import java.util.*;

// General-purpose companion to ModMenuTool: replaces an explicit list of
// fully-qualified classes (regardless of package) instead of everything
// matching a "gui.ModMenu*" prefix. Used for one-off native-class patches
// (e.g. avatar.NameBar) that live outside the ModMenu UI sources.
//
// Usage:
//   java PatchTool replace <in.swf> <out.swf> <srcDir1[,srcDir2,...]> <fqcn1,fqcn2,...>
// Each srcDir is searched (in order) for "<SimpleClassName>.as".
// A listed class that has a source file but isn't in the SWF yet (a new mod
// class such as gui.MasterpiecesPopup) is added first, the way FFDec's
// "Add class" does it, and compiled before the existing classes that use it.
public class PatchTool {
  static List<ScriptPack> targetPacks(SWF swf, Set<String> fqcns) throws Exception {
    List<ABC> abcs = new ArrayList<>();
    for (ABCContainerTag t : swf.getAbcList()) abcs.add(t.getABC());
    List<ScriptPack> out = new ArrayList<>();
    for (ABC abc : abcs)
      for (ScriptPack p : abc.getScriptPacks(null, abcs))
        if (fqcns.contains(p.getClassPath().toString())) out.add(p);
    return out;
  }

  static File findSource(List<File> srcDirs, String fqcn) {
    String cls = fqcn.substring(fqcn.lastIndexOf('.') + 1);
    for (File dir : srcDirs) {
      File candidate = new File(dir, cls + ".as");
      if (candidate.exists()) return candidate;
    }
    return null;
  }

  // Compiles an empty "package x { public class Y { } }" into the ABC that
  // holds the existing targets; the normal replace then fills it in.
  static List<String> addMissingClasses(SWF swf, Set<String> fqcns, List<File> srcDirs) throws Exception {
    List<ScriptPack> existing = targetPacks(swf, fqcns);
    Set<String> found = new HashSet<>();
    for (ScriptPack p : existing) found.add(p.getClassPath().toString());
    List<String> added = new ArrayList<>();
    if (existing.isEmpty()) return added;
    ABCContainerTag container = existing.get(0).abc.parentTag;
    for (String fqcn : fqcns) {
      if (found.contains(fqcn) || findSource(srcDirs, fqcn) == null) continue;
      int dot = fqcn.lastIndexOf('.');
      String pkg = dot < 0 ? "" : fqcn.substring(0, dot);
      String cls = fqcn.substring(dot + 1);
      AbcIndexing index = swf.getAbcIndex();
      index.selectAbc(container.getABC());
      ActionScript3Parser parser = new ActionScript3Parser(index);
      String stub = "package " + pkg + " {public class " + cls + " { }}";
      parser.addScript(stub, fqcn.replace('.', '/'), 0, 0, swf.getDocumentClass(), container.getABC());
      ((Tag) container).setModified(true);
      swf.clearAllCache();
      swf.setModified(true);
      System.out.println("added new class " + fqcn);
      added.add(fqcn);
    }
    return added;
  }

  public static void main(String[] a) throws Exception {
    String mode = a[0];
    if (!mode.equals("replace")) { System.out.println("only 'replace' is supported"); return; }
    SWF swf = new SWF(new FileInputStream(a[1]), false);
    String outSwf = a[2];
    List<File> srcDirs = new ArrayList<>();
    for (String s : a[3].split(",")) srcDirs.add(new File(s.trim()));
    Set<String> fqcns = new HashSet<>(Arrays.asList(a[4].split(",")));
    List<String> added = addMissingClasses(swf, fqcns, srcDirs);
    List<ScriptPack> packs = targetPacks(swf, fqcns);
    packs.sort(Comparator.comparingInt(p -> added.contains(p.getClassPath().toString()) ? 0 : 1));
    As3ScriptReplacerInterface r = As3ScriptReplacerFactory.createFFDec();
    List<SWF> swfs = Collections.singletonList(swf);
    int n = 0;
    for (ScriptPack p : packs) {
      File src = findSource(srcDirs, p.getClassPath().toString());
      if (src == null) { System.out.println("skip script=" + p.scriptIndex + " " + p.getClassPath() + " (no source found)"); continue; }
      String code = new String(Files.readAllBytes(src.toPath()), "UTF-8");
      System.out.println("replacing script=" + p.scriptIndex + " " + p.getClassPath() + " from " + src);
      r.initReplacement(p, swfs);
      r.replaceScript(p, code, swfs);
      r.deinitReplacement(p);
      n++;
    }
    for (String fqcn : fqcns) {
      boolean found = false;
      for (ScriptPack p : packs) if (p.getClassPath().toString().equals(fqcn)) found = true;
      if (!found) System.out.println("WARNING: class not found in SWF: " + fqcn);
    }
    try (FileOutputStream fos = new FileOutputStream(outSwf)) { swf.saveTo(fos); }
    System.out.println("replaced " + n + " packs, saved " + outSwf);
  }
}
