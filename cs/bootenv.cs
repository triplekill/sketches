#if !CODE_ANALYSIS
  #define CODE_ANALYSIS
#endif

using System;
using System.Linq;
using System.Globalization;
using System.ComponentModel;
using System.Runtime.InteropServices;
using System.Diagnostics.CodeAnalysis;

namespace BootEnvironment {
  internal static class NativeMethods {
    internal const Int32 STATUS_SUCCESS = 0;
    internal const Int32 SystemBootEnvironmentInformation = 90;

    internal enum FIRMWARE_TYPE : uint {
      FirmwareTypeUnknown = 0,
      FirmwareTypeBios = 1,
      FirmwareTypeUefi = 2,
      FirmwareTypeMax = 3
    }

    [StructLayout(LayoutKind.Sequential)]
    internal struct GUID {
      internal UInt32 Data1;
      internal UInt16 Data2;
      internal UInt16 Data3;
      [MarshalAs(UnmanagedType.ByValArray, SizeConst = 8)]
      internal Byte[] Data4;

      internal String Guid {
        get {
          return String.Format(
            CultureInfo.InvariantCulture,
            "{{{0:X}-{1:X}-{2:X}-{3}}}",
            this.Data1, this.Data2, this.Data3,
            BitConverter.ToString(this.Data4).Replace("-", "").Insert(4, "-")
          );
        }
      }
    }

    [StructLayout(LayoutKind.Sequential)]
    internal struct SYSTEM_BOOT_ENVIRONMENT_INFORMATION {
      internal GUID BootIdentifier;
      internal FIRMWARE_TYPE FirmwareType;
      internal UInt64 BootFlags;

      internal Int32 Size {
        get { return Marshal.SizeOf(this); }
      }
    }

    [DllImport("ntdll.dll")]
    internal static extern Int32 NtQuerySystemInformation(
       Int32 SystemInformationClass,
       out SYSTEM_BOOT_ENVIRONMENT_INFORMATION SystemInformation,
       Int32 SystemInformationLength,
       Byte[] ReturnLength // out UInt32 ReturnLength
    );

    [DllImport("ntdll.dll")]
    internal static extern Int32 RtlNtStatusToDosError(
       Int32 Status
    );
  }

  internal sealed class Program {
    [SuppressMessage("Microsoft.Globalization",
                     "CA1303:DoNotPassLiteralsAsLocalizedParameters")]
    static void Main() {
      var bei = new NativeMethods.SYSTEM_BOOT_ENVIRONMENT_INFORMATION();
      var nts = NativeMethods.NtQuerySystemInformation(
         NativeMethods.SystemBootEnvironmentInformation, out bei, bei.Size, null
      );

      if (NativeMethods.STATUS_SUCCESS != nts) {
        Console.WriteLine(new Win32Exception(
           NativeMethods.RtlNtStatusToDosError(nts)
        ).Message);
        return;
      }

      Console.WriteLine("Boot identifier: {0}", bei.BootIdentifier.Guid);
      Console.WriteLine("Firmware type  : {0}", bei.FirmwareType);
    }
  }
}
