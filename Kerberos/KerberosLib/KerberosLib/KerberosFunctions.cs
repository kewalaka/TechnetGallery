using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Runtime.InteropServices;

namespace KerberosLib
{
    public partial class Win32
    {
        [DllImport("secur32.dll")]
        internal static extern NtStatus LsaConnectUntrusted(
            [Out] out IntPtr LsaHandle
            );

        [DllImport("secur32.dll")]
        internal static extern NtStatus LsaLookupAuthenticationPackage(
            [In] IntPtr LsaHandle,
            [In] ref AnsiString PackageName,
            [Out] out ulong AuthenticationPackage
            );

        [DllImport("secur32.dll", SetLastError = true, EntryPoint = "LsaCallAuthenticationPackage")]
        internal static extern int LsaCallAuthenticationPackage(
            IntPtr LsaHandle,
            uint AuthenticationPackage,
            IntPtr ProtocolSubmitBuffer,
            int SubmitBufferLength,
            out IntPtr ProtocolReturnBuffer,
            out ulong ReturnBufferLength,
            out NtStatus ProtocolStatus);

        [DllImport("secur32.dll", SetLastError = true)]
        internal static extern int LsaFreeReturnBuffer(IntPtr Buffer);

        [DllImport("secur32.dll", SetLastError = true)]
        internal static extern int LsaDeregisterLogonProcess(IntPtr LsaHandle);
    }
}
