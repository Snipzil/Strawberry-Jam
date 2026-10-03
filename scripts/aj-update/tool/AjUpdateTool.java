import com.jpexs.decompiler.flash.SWF;
import com.jpexs.decompiler.flash.SWFCompression;
import com.jpexs.decompiler.flash.abc.ABC;
import com.jpexs.decompiler.flash.abc.ScriptPack;
import com.jpexs.decompiler.flash.abc.avm2.parser.script.AbcIndexing;
import com.jpexs.decompiler.flash.abc.avm2.parser.script.ActionScript3Parser;
import com.jpexs.decompiler.flash.importers.As3ScriptReplaceException;
import com.jpexs.decompiler.flash.importers.As3ScriptReplaceExceptionItem;
import com.jpexs.decompiler.flash.importers.As3ScriptReplacerFactory;
import com.jpexs.decompiler.flash.importers.As3ScriptReplacerInterface;
import com.jpexs.decompiler.flash.tags.ABCContainerTag;
import com.jpexs.decompiler.flash.tags.Tag;
import com.jpexs.decompiler.flash.tags.base.CharacterIdTag;
import java.io.*;
import java.nio.file.*;
import java.security.MessageDigest;
import java.util.*;

// Driven by aj-update.js; see scripts/aj-update/README.md.
//
// Usage:
//   java AjUpdateTool tags <in.swf>
//     Prints one line per non-ABC tag (type, character id, SHA-1 of its data)
//     so the caller can tell whether AJ changed anything besides code.
//   java AjUpdateTool apply <in.swf> <out.swf> <srcRoot> <classList.txt>
//     For every fully-qualified class in classList.txt, compiles
//     <srcRoot>/<package path>/<Class>.as into the SWF: replaces every
//     existing pack for that class, or adds the class if the SWF doesn't have
//     it yet (same as FFDec's "Add class": empty stub, then replace). Saves
//     LZMA-compressed.
public class AjUpdateTool {
  static List<ABC> abcs(SWF swf) {
    List<ABC> out = new ArrayList<>();
    for (ABCContainerTag t : swf.getAbcList()) out.add(t.getABC());
    return out;
  }

  static Map<String, List<ScriptPack>> packsByClass(SWF swf) throws Exception {
    List<ABC> all = abcs(swf);
    Map<String, List<ScriptPack>> out = new HashMap<>();
    for (ABC abc : all) {
      abc.clearPacksCache();
      for (ScriptPack p : abc.getScriptPacks(null, all))
        out.computeIfAbsent(p.getClassPath().toString(), k -> new ArrayList<>()).add(p);
    }
    return out;
  }

  static void tags(String in) throws Exception {
    SWF swf = new SWF(new BufferedInputStream(new FileInputStream(in)), false);
    MessageDigest md = MessageDigest.getInstance("SHA-1");
    int i = 0;
    for (Tag t : swf.getTags()) {
      i++;
      if (t instanceof ABCContainerTag) continue;
      String id = (t instanceof CharacterIdTag) ? "#" + ((CharacterIdTag) t).getCharacterId() : "@" + i;
      byte[] dig = md.digest(t.getData());
      StringBuilder sb = new StringBuilder();
      for (byte b : dig) sb.append(String.format("%02x", b));
      System.out.println(t.getTagName() + id + "\t" + sb);
    }
  }

  static void addStub(SWF swf, String fqcn) throws Exception {
    int dot = fqcn.lastIndexOf('.');
    String pkg = dot < 0 ? "" : fqcn.substring(0, dot);
    String cls = fqcn.substring(dot + 1);
    // The main ABC is the one holding the most scripts (ajclient has exactly one).
    ABCContainerTag target = null;
    for (ABCContainerTag t : swf.getAbcList())
      if (target == null || t.getABC().script_info.size() > target.getABC().script_info.size()) target = t;
    AbcIndexing idx = swf.getAbcIndex();
    idx.selectAbc(target.getABC());
    ActionScript3Parser parser = new ActionScript3Parser(idx);
    String stub = "package " + pkg + " {public class " + cls + " { }}";
    parser.addScript(stub, fqcn.replace('.', '/'), 0, 0, swf.getDocumentClass(), target.getABC());
    ((Tag) target).setModified(true);
    swf.clearAllCache();
    swf.resetAbcIndex();
    swf.setModified(true);
    System.out.println("added " + fqcn);
  }

  static String describe(Exception e) {
    if (e instanceof As3ScriptReplaceException) {
      StringBuilder sb = new StringBuilder();
      for (As3ScriptReplaceExceptionItem it : ((As3ScriptReplaceException) e).getExceptionItems())
        sb.append("\n    line ").append(it.getLine()).append(": ").append(it.getMessage());
      if (sb.length() > 0) return sb.toString();
    }
    return " " + e;
  }

  static void apply(String in, String out, File srcRoot, File classList) throws Exception {
    SWF swf = new SWF(new BufferedInputStream(new FileInputStream(in)), false);
    List<String> classes = new ArrayList<>();
    for (String line : Files.readAllLines(classList.toPath()))
      if (!line.trim().isEmpty()) classes.add(line.trim());

    Map<String, List<ScriptPack>> packs = packsByClass(swf);
    for (String fqcn : classes)
      if (!packs.containsKey(fqcn)) addStub(swf, fqcn);

    As3ScriptReplacerInterface r = As3ScriptReplacerFactory.createFFDec();
    List<SWF> swfs = Collections.singletonList(swf);
    // A class can fail while something it depends on is still old or a stub,
    // so keep retrying the failures as long as each pass makes progress.
    List<String> pending = new ArrayList<>(classes);
    Map<String, String> errors = new LinkedHashMap<>();
    while (!pending.isEmpty()) {
      List<String> failed = new ArrayList<>();
      errors.clear();
      for (String fqcn : pending) {
        File src = new File(srcRoot, fqcn.replace('.', File.separatorChar) + ".as");
        String code = new String(Files.readAllBytes(src.toPath()), "UTF-8");
        List<ScriptPack> targets = packsByClass(swf).get(fqcn);
        try {
          for (ScriptPack p : targets) {
            r.initReplacement(p, swfs);
            try {
              r.replaceScript(p, code, swfs);
            } finally {
              r.deinitReplacement(p);
            }
          }
          System.out.println("compiled " + fqcn + " (" + targets.size() + " pack" + (targets.size() == 1 ? "" : "s") + ")");
        } catch (Exception e) {
          failed.add(fqcn);
          errors.put(fqcn, describe(e));
        }
      }
      if (failed.size() == pending.size()) break;
      pending = failed;
    }
    if (!errors.isEmpty()) {
      for (Map.Entry<String, String> e : errors.entrySet())
        System.out.println("COMPILE ERROR " + e.getKey() + ":" + e.getValue());
      System.exit(2);
    }

    swf.compression = SWFCompression.LZMA;
    try (OutputStream fos = new BufferedOutputStream(new FileOutputStream(out))) { swf.saveTo(fos); }

    // Reload the result to make sure it parses and every class is present.
    SWF check = new SWF(new BufferedInputStream(new FileInputStream(out)), false);
    Map<String, List<ScriptPack>> after = packsByClass(check);
    for (String fqcn : classes)
      if (!after.containsKey(fqcn)) {
        System.out.println("VERIFY ERROR " + fqcn + " missing from saved SWF");
        System.exit(3);
      }
    System.out.println("saved " + out + " (" + classes.size() + " classes)");
  }

  public static void main(String[] a) throws Exception {
    if (a.length >= 2 && a[0].equals("tags")) tags(a[1]);
    else if (a.length >= 5 && a[0].equals("apply")) apply(a[1], a[2], new File(a[3]), new File(a[4]));
    else {
      System.out.println("usage: AjUpdateTool tags <in.swf> | apply <in.swf> <out.swf> <srcRoot> <classList.txt>");
      System.exit(1);
    }
  }
}
