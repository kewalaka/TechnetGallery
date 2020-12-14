using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Runtime.InteropServices;

namespace KerberosLib
{
    public partial class Win32
    {
        [DllImport("ntdll.dll")]
        internal static extern void RtlFreeUnicodeString(
            [In] ref UnicodeString UnicodeString
            );

        [DllImport("ntdll.dll")]
        [return: MarshalAs(UnmanagedType.I1)]
        internal static extern bool RtlCreateUnicodeString(
            [Out] out UnicodeString DestinationString,
            [MarshalAs(UnmanagedType.LPWStr)]
            [In] string SourceString
            );

        [DllImport("ntdll.dll")]
        internal static extern void RtlFreeAnsiString(
            [In] ref AnsiString AnsiString
            );

        [DllImport("ntdll.dll")]
        internal static extern NtStatus RtlUnicodeStringToAnsiString(
            ref AnsiString DestinationString,
            [In] ref UnicodeString SourceString,
            [In] bool AllocateDestinationString
            );

        [DllImport("ntdll.dll")]
        internal static extern NtStatus RtlAnsiStringToUnicodeString(
            ref UnicodeString DestinationString,
            [In] ref AnsiString SourceString,
            [In] bool AllocateDestinationString
            );

        internal static Win32Error GetLastErrorCode()
        {
            return (Win32Error)Marshal.GetLastWin32Error();
        }
    }
}
