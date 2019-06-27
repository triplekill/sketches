#if !CODE_ANALYSIS
  #define CODE_ANALYSIS
#endif

using System;
using System.IO;
using System.Reflection;
using System.Diagnostics.CodeAnalysis;

[assembly: AssemblyDescription("Computing a file entropy")]
[assembly: AssemblyTitle("ent")]
[assembly: AssemblyVersion("1.0.0.0")]
[assembly: CLSCompliant(true)]

namespace Entropy {
  internal sealed class AssemblyInfo {
    private  Type a;
    internal AssemblyInfo() { a = typeof(Program); }

    internal String Description {
      get {
        return ((AssemblyDescriptionAttribute)Attribute
          .GetCustomAttribute(a.Assembly, typeof(AssemblyDescriptionAttribute)
        )).Description;
      }
    }

    internal String Title {
      get {
        return ((AssemblyTitleAttribute)Attribute
          .GetCustomAttribute(a.Assembly, typeof(AssemblyTitleAttribute)
        )).Title;
      }
    }

    internal String Version {
      get { return a.Assembly.GetName().Version.ToString(2); }
    }
  } // AssemblyInfo

  internal sealed class Program {
    static unsafe Double Entropy(Byte[] buf) {
      Int32* rgi = stackalloc Int32[0x100], pi = rgi + 0x100;
      Double ent = 0.0, src = buf.Length;

      for (Int32 i = buf.Length; --i >= 0;) rgi[buf[i]]++;
      while (--pi >= rgi) {
        if (*pi > 0) ent += *pi * Math.Log(*pi / src, 2.0);
      }

      return -ent / src;
    }

    [SuppressMessage("Microsoft.Globalization",
                     "CA1303:DoNotPassLiteralsAsLocalizedParameters")]
    static void Main(String[] args) {
      if (1 != args.Length) {
        AssemblyInfo ai = new AssemblyInfo();
        Console.WriteLine("{0} v{1} - {2}\nUsage: {3} <file>",
          ai.Title, ai.Version, ai.Description, ai.Title
        );

        return;
      }

      try {
        Console.WriteLine("{0} *{1}",
          Math.Round(Entropy(File.ReadAllBytes(args[0])), 3),
          Path.GetFullPath(args[0])
        );
      }
      catch (Exception e) {
        Console.WriteLine(e.Message);
      }
    }
  } // Program
}
