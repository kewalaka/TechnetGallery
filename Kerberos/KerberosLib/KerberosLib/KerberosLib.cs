using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Runtime.InteropServices;
using System.ComponentModel;

namespace KerberosLib
{
    public class KerberosTicket
    {
        public string ServerName { get; set; }
        public string Realm { get; set; }
        public DateTime StartTime { get; set; }
        public DateTime EndTime { get; set; }
        public DateTime RenewTime { get; set; }
        public KERB_TICKET_ENCRYPTIONTYPE EncryptionType { get; set; }
        public KERB_TICKET_FLAGS TicketFlags { get; set; }
    }

    public class KerberosTicketCache : IDisposable
    {
        private static IntPtr lsaHandle = IntPtr.Zero;
        private static ulong authenticationPackage = 0;
        private static string packageName = "Kerberos";

        private static void ConnectUntrusted()
        {
            NtStatus result;
            result = Win32.LsaConnectUntrusted(out lsaHandle);

            if (result != NtStatus.Success)
            {
                throw new Win32Exception((int)result);
            }
        }

        private static void LookupAuthenticationPackage()
        {
            NtStatus result;
            AnsiString PackageName = new AnsiString(packageName);
            result = Win32.LsaLookupAuthenticationPackage(lsaHandle, ref PackageName, out authenticationPackage);
        }

        public static void PurgeTickets()
        {
            try
            {
                ConnectUntrusted();
                LookupAuthenticationPackage();
            }
            catch(Exception ex)
            {
                throw ex;
            }

            NtStatus result;

            KERB_PURGE_TKT_CACHE_REQUEST kerbReq = new KERB_PURGE_TKT_CACHE_REQUEST();
            kerbReq.LogonId = new LUID();
            kerbReq.MessageType = KERB_PROTOCOL_MESSAGE_TYPE.KerbPurgeTicketCacheMessage;

            IntPtr kerbRepPointer = IntPtr.Zero;
            IntPtr kerbReqPointer = Marshal.AllocHGlobal(Marshal.SizeOf(kerbReq));
            Marshal.StructureToPtr(kerbReq, kerbReqPointer, true);
            ulong kerbRepBufferLength = 0;

            Win32.LsaCallAuthenticationPackage(lsaHandle, (uint)authenticationPackage, kerbReqPointer, (int)Marshal.SizeOf(kerbReq), out kerbRepPointer, out kerbRepBufferLength, out result);

            Win32.LsaFreeReturnBuffer(kerbRepPointer);

            if (result != NtStatus.Success)
            {
                throw new Win32Exception((int)result);
            }
        }

        public static List<KerberosTicket> GetTickets()
        {
            try
            {
                ConnectUntrusted();
                LookupAuthenticationPackage();
            }
            catch (Exception ex)
            {
                throw ex;
            }

            NtStatus result;
            List<KerberosTicket> tickets = new List<KerberosTicket>();

            KERB_QUERY_TKT_CACHE_REQUEST kerbReq = new KERB_QUERY_TKT_CACHE_REQUEST();
            kerbReq.LogonId = new LUID();
            kerbReq.MessageType = KERB_PROTOCOL_MESSAGE_TYPE.KerbQueryTicketCacheMessage;

            IntPtr kerbRepPointer = IntPtr.Zero;
            IntPtr kerbReqPointer = Marshal.AllocHGlobal(Marshal.SizeOf(kerbReq));
            Marshal.StructureToPtr(kerbReq, kerbReqPointer, true);
            ulong kerbRepBufferLength = 0;

            Win32.LsaCallAuthenticationPackage(lsaHandle, (uint)authenticationPackage, kerbReqPointer, (int)Marshal.SizeOf(kerbReq), out kerbRepPointer, out kerbRepBufferLength, out result);
            if (result != NtStatus.Success)
            {
                throw new Win32Exception((int)result);
            }

            var KerbRep = (KERB_QUERY_TKT_CACHE_RESPONSE)Marshal.PtrToStructure(kerbRepPointer, typeof(KERB_QUERY_TKT_CACHE_RESPONSE));
            kerbRepPointer = kerbRepPointer.Increment(8);

            //----------------------------------------------------

            DateTime SysTime = new DateTime(1601, 1, 1, 0, 0, 0, 0);
            for (int i = 0; i < KerbRep.CountOfTickets; i++)
            {
                KerberosTicket ticket = new KerberosTicket();

                if (IntPtr.Size == 8)
                {
                    var kerbTicket = (KERB_TICKET_CACHE_INFO_x64)Marshal.PtrToStructure(kerbRepPointer, typeof(KERB_TICKET_CACHE_INFO_x64));

                    ticket.ServerName = Marshal.PtrToStringUni(kerbTicket.ServerName.Buffer);
                    ticket.Realm = Marshal.PtrToStringUni(kerbTicket.RealmName.Buffer).Replace(ticket.ServerName, "");
                    ticket.TicketFlags = (KERB_TICKET_FLAGS)kerbTicket.TicketFlags;
                    ticket.EncryptionType = (KERB_TICKET_ENCRYPTIONTYPE)kerbTicket.EncryptionType;

                    ticket.StartTime = SysTime.AddTicks(kerbTicket.StartTime);
                    ticket.EndTime = SysTime.AddTicks(kerbTicket.EndTime);
                    ticket.RenewTime = SysTime.AddTicks(kerbTicket.RenewTime);
                    tickets.Add(ticket);

                    kerbRepPointer = kerbRepPointer.Increment<KERB_TICKET_CACHE_INFO_x64>();
                }
                else
                {
                    var kerbTicket = (KERB_TICKET_CACHE_INFO_x86)Marshal.PtrToStructure(kerbRepPointer, typeof(KERB_TICKET_CACHE_INFO_x86));

                    ticket.ServerName = Marshal.PtrToStringUni(kerbTicket.ServerName.Buffer);
                    ticket.Realm = Marshal.PtrToStringUni(kerbTicket.RealmName.Buffer).Replace(ticket.ServerName, "");
                    ticket.TicketFlags = (KERB_TICKET_FLAGS)kerbTicket.TicketFlags;
                    ticket.EncryptionType = (KERB_TICKET_ENCRYPTIONTYPE)kerbTicket.EncryptionType;

                    ticket.StartTime = SysTime.AddTicks(kerbTicket.StartTime);
                    ticket.EndTime = SysTime.AddTicks(kerbTicket.EndTime);
                    ticket.RenewTime = SysTime.AddTicks(kerbTicket.RenewTime);
                    tickets.Add(ticket);

                    kerbRepPointer = kerbRepPointer.Increment<KERB_TICKET_CACHE_INFO_x86>();
                }
            }

            //----------------------------------------------------

            Win32.LsaFreeReturnBuffer(kerbRepPointer);
            return tickets;
        }

        public void Dispose()
        {
            Win32.LsaDeregisterLogonProcess(lsaHandle);
        }
    }
}