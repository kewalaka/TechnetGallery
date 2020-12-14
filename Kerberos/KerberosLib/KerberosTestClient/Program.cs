using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace KerberosTestClient
{
    class Program
    {
        static void Main(string[] args)
        {
            var tickets = KerberosLib.KerberosTicketCache.GetTickets();
            foreach (var ticket in tickets)
            {
                Console.WriteLine("{0} - {1}", ticket.ServerName, ticket.Realm);
            }

            Console.ReadLine();
        }
    }
}
