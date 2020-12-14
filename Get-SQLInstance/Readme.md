<div id="longDesc">

<span style="font-size:small">This function looks up SQL Instance information via the registry on local and remote systems. Information looked up is Version, Edition type, whether the SQL Instance is part of a cluster and the other nodes in the cluster and the full name that can be used in another script to connect to the SQL instance. If a cluster does exist, there is some code at the bottom of this which can help you to query the SQL cluster name and then exempt the nodes so only the cluster is listed in the report.</span>

<span style="font-size:small">**Updated 5 June 2016: **</span>

*   <span>Added WMI checks</span>

<span style="font-size:small">**Updated 19 Aug 2014: **</span>

*   <span style="font-size:x-small">Added check for SQL 2014</span>

<span style="font-size:small">** Updated 06 Feb 2014:**</span>

*   _Fixed bug where ﻿"SOFTWARE\Wow6432Node\Microsoft\Microsoft SQL Server" was not being checked. Thanks Cookie.Monster!_

<span style="font-size:small">Related blog post: [http://learn-powershell.net/2013/09/15/find-all-sql-instances-using-powershell-plus-a-little-more/](http://learn-powershell.net/2013/09/15/find-all-sql-instances-using-powershell-plus-a-little-more/)</span>

**<span style="font-size:x-small">Remember to dot source the script to load the function into the current session.</span>**

**<span style="font-size:x-small"> </span>**

<div class="scriptcode">**

<div class="pluginEditHolder" plugincommand="mceScriptCode">

<div class="title"><span>PowerShell</span></div>

<div class="pluginLinkHolder"><span class="pluginEditHolderLink">Edit</span>|<span class="pluginRemoveHolderLink">Remove</span></div>

<span class="hidden">powershell</span>

<pre class="hidden">    <#
        .SYNOPSIS
            Retrieves SQL server information from a local or remote servers.

        .DESCRIPTION
            Retrieves SQL server information from a local or remote servers. Pulls all 
            instances from a SQL server and detects if in a cluster or not.

        .PARAMETER Computername
            Local or remote systems to query for SQL information.

        .NOTES
            Name: Get-SQLInstance
            Author: Boe Prox
            Version History:
                1.5 //Boe Prox - 31 May 2016
                    - Added WMI queries for more information
                    - Custom object type name
                1.0 //Boe Prox -  07 Sept 2013
                    - Initial Version

        .EXAMPLE
            Get-SQLInstance -Computername SQL1

            Computername      : SQL1
            Instance          : MSSQLSERVER
            SqlServer         : SQLCLU
            WMINamespace      : ComputerManagement10
            Sqlstates         : 2061
            Version           : 10.53.6000.34
            Splevel           : 3
            Clustered         : True
            Installpath       : C:\Program Files\Microsoft SQL 
                                Server\MSSQL10_50.MSSQLSERVER\MSSQL
            Datapath          : D:\MSSQL10_50.MSSQLSERVER\MSSQL
            Language          : 1033
            Fileversion       : 2009.100.6000.34
            Vsname            : SQLCLU
            Regroot           : Software\Microsoft\Microsoft SQL 
                                Server\MSSQL10_50.MSSQLSERVER
            Sku               : 1804890536
            Skuname           : Enterprise Edition (64-bit)
            Instanceid        : MSSQL10_50.MSSQLSERVER
            Startupparameters : -dD:\MSSQL10_50.MSSQLSERVER\MSSQL\DATA\master.mdf;-eD:\MSSQL1
                                0_50.MSSQLSERVER\MSSQL\Log\ERRORLOG;-lD:\MSSQL10_50.MSSQLSERV
                                ER\MSSQL\DATA\mastlog.ldf
            Errorreporting    : False
            Dumpdir           : D:\MSSQL10_50.MSSQLSERVER\MSSQL\LOG\
            Sqmreporting      : False
            Iswow64           : False
            BackupDirectory   : F:\MSSQL10_50.MSSQLSERVER\MSSQL\Backup
            AlwaysOnName      : 
            Nodes             : {SQL1, SQL2}
            Caption           : SQL Server 2008 R2
            FullName          : SQLCLU\MSSQLSERVER

            Description
            -----------
            Retrieves the SQL information from SQL1
    #></pre>

<div class="preview">

<pre class="powershell">    <span class="powerShell__mlcom"><# 
        .SYNOPSIS 
            Retrieves SQL server information from a local or remote servers. 

        .DESCRIPTION 
            Retrieves SQL server information from a local or remote servers. Pulls all  
            instances from a SQL server and detects if in a cluster or not. 

        .PARAMETER Computername 
            Local or remote systems to query for SQL information. 

        .NOTES 
            Name: Get-SQLInstance 
            Author: Boe Prox 
            Version History: 
                1.5 //Boe Prox - 31 May 2016 
                    - Added WMI queries for more information 
                    - Custom object type name 
                1.0 //Boe Prox -  07 Sept 2013 
                    - Initial Version 

        .EXAMPLE 
            Get-SQLInstance -Computername SQL1 

            Computername      : SQL1 
            Instance          : MSSQLSERVER 
            SqlServer         : SQLCLU 
            WMINamespace      : ComputerManagement10 
            Sqlstates         : 2061 
            Version           : 10.53.6000.34 
            Splevel           : 3 
            Clustered         : True 
            Installpath       : C:\Program Files\Microsoft SQL  
                                Server\MSSQL10_50.MSSQLSERVER\MSSQL 
            Datapath          : D:\MSSQL10_50.MSSQLSERVER\MSSQL 
            Language          : 1033 
            Fileversion       : 2009.100.6000.34 
            Vsname            : SQLCLU 
            Regroot           : Software\Microsoft\Microsoft SQL  
                                Server\MSSQL10_50.MSSQLSERVER 
            Sku               : 1804890536 
            Skuname           : Enterprise Edition (64-bit) 
            Instanceid        : MSSQL10_50.MSSQLSERVER 
            Startupparameters : -dD:\MSSQL10_50.MSSQLSERVER\MSSQL\DATA\master.mdf;-eD:\MSSQL1 
                                0_50.MSSQLSERVER\MSSQL\Log\ERRORLOG;-lD:\MSSQL10_50.MSSQLSERV 
                                ER\MSSQL\DATA\mastlog.ldf 
            Errorreporting    : False 
            Dumpdir           : D:\MSSQL10_50.MSSQLSERVER\MSSQL\LOG\ 
            Sqmreporting      : False 
            Iswow64           : False 
            BackupDirectory   : F:\MSSQL10_50.MSSQLSERVER\MSSQL\Backup 
            AlwaysOnName      :  
            Nodes             : {SQL1, SQL2} 
            Caption           : SQL Server 2008 R2 
            FullName          : SQLCLU\MSSQLSERVER 

            Description 
            ----------- 
            Retrieves the SQL information from SQL1 
    #></span></pre>

</div>

</div>

**</div>

<span style="font-size:small">Query a server for all instances</span>

<span style="font-size:small"> </span>

<div class="scriptcode">

<div class="pluginEditHolder" plugincommand="mceScriptCode">

<div class="title"><span>PowerShell</span></div>

<div class="pluginLinkHolder"><span class="pluginEditHolderLink">Edit</span>|<span class="pluginRemoveHolderLink">Remove</span></div>

<span class="hidden">powershell</span>

<pre class="hidden">Get-SQLInstance -Computername DC1</pre>

<div class="preview">

<pre class="powershell">Get<span class="powerShell__operator">-</span>SQLInstance <span class="powerShell__operator">-</span>Computername DC1</pre>

</div>

</div>

</div>

<span style="font-size:small">Query multiple systems and only show the Cluster instead of the cluster nodes.</span>

<div class="scriptcode">

<div class="pluginEditHolder" plugincommand="mceScriptCode">

<div class="title"><span>PowerShell</span></div>

<div class="pluginLinkHolder"><span class="pluginEditHolderLink">Edit</span>|<span class="pluginRemoveHolderLink">Remove</span></div>

<span class="hidden">powershell</span>

<pre class="hidden">Get-SQLInstance -ComputerName $Computernames -Verbose | ForEach {
    If ($_.isClusterNode) {
        If (($list -notcontains $_.Clustername)) {
            Get-SQLInstance -ComputerName $_.ClusterName
            $list += ,$_.ClusterName
        }
    } Else {
        $_
    }
}</pre>

<div class="preview">

<pre class="powershell">Get<span class="powerShell__operator">-</span>SQLInstance <span class="powerShell__operator">-</span>ComputerName <span class="powerShell__variable">$Computernames</span> <span class="powerShell__operator">-</span>Verbose <span class="powerShell__operator">|</span> <span class="powerShell__keyword">ForEach</span> { 
    <span class="powerShell__keyword">If</span> (<span class="powerShell__variable">$_</span>.isClusterNode) { 
        <span class="powerShell__keyword">If</span> ((<span class="powerShell__variable">$list</span> <span class="powerShell__operator">-</span>notcontains <span class="powerShell__variable">$_</span>.Clustername)) { 
            Get<span class="powerShell__operator">-</span>SQLInstance <span class="powerShell__operator">-</span>ComputerName <span class="powerShell__variable">$_</span>.ClusterName 
            <span class="powerShell__variable">$list</span> <span class="powerShell__operator">+</span>= ,<span class="powerShell__variable">$_</span>.ClusterName 
        } 
    } <span class="powerShell__keyword">Else</span> { 
        <span class="powerShell__variable">$_</span> 
    } 
}</pre>

</div>

</div>

</div>

<div class="scriptcode">

<div class="pluginEditHolder" plugincommand="mceScriptCode">

<div class="title"><span>PowerShell</span></div>

<div class="pluginLinkHolder"><span class="pluginEditHolderLink">Edit</span>|<span class="pluginRemoveHolderLink">Remove</span></div>

<span class="hidden">powershell</span>

<pre class="hidden">. .\Get-SQLInstance.ps1</pre>

<div class="preview">

<pre class="powershell">. .\Get<span class="powerShell__operator">-</span>SQLInstance.ps1</pre>

</div>

</div>

</div>

</div>