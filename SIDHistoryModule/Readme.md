<div id="longDesc">

You can find the full documentation for this module in the following blog posts:

[http://aka.ms/SIDHistory](http://aka.ms/SIDHistory "http://aka.ms/SIDHistory")

### Introduction

This post is the fifth in the "SID Walker, Texas Ranger" series on **SID history remediation with PowerShell**.  Today we're wrapping up with a handy summary of each post in the series. We will also take the function library we've been using and upgrade it to a PowerShell module. Then we'll walk through the entire SID history remediation process using the provided cmdlets in this module.

### The Story So Far

Those of you who follow my blog know that I have been stuck on this theme of SID history for several months now.  Why?  Because I see this quite frequently with customers, and I want to offer some practical guidance on dealing with it.  Here is a summary of the [blog series](/b/ashleymcglone/archive/tags/sid+history/ "blog series") that brought us to today's module:

1.  [Using PowerShell to resolve Token Size issues caused by SID history](/b/ashleymcglone/archive/2011/05/19/using-powershell-to-resolve-token-size-issues-caused-by-sid-history.aspx "Using PowerShell to resolve Token Size issues caused by SID history")  
    Prior to starting the module development this post explained the background of token size issues as related to SID history.  I provided the basic SID history query that we use to produce the report and some great links for more information on token size.
2.  [Do Over: SID History One-Liner](/b/ashleymcglone/archive/2011/05/26/do-over-sid-history-one-liner.aspx "Do Over: SID History One-Liner")  
    As a follow up to the Token Size post I re-wrote the SID history report query as a one-liner.
3.  [PowerShell: SID Walker, Texas Ranger (Part 1)](/b/ashleymcglone/archive/2011/08/29/powershell-sid-walker-texas-ranger-part-1.aspx "PowerShell: SID Walker, Texas Ranger (Part 1)")  
    This time we looked at Get-ACL and parsing SDDL strings, a warm up for the next post.
4.  [PowerShell: SID Walker, Texas Ranger (Part 2)](/b/ashleymcglone/archive/2011/09/16/powershell-sid-walker-texas-ranger-part-2.aspx "PowerShell: SID Walker, Texas Ranger (Part 2)")  
    Next I wrote a function to swap SID history entries in ACLs/ACEs.  This compensates for a gap in the ADMT, because it cannot migrate SID history for file shares hosted on a NAS.
5.  [PowerShell: SID Walker, Texas Ranger (Part 3): Exporting Domain SIDs and Trusts](/b/ashleymcglone/archive/2011/10/12/powershell-sid-walker-texas-ranger-part-3-getting-domain-sids-and-trusts.aspx "PowerShell: SID Walker, Texas Ranger (Part 3): Exporting Domain SIDs and Trusts")  
    Looking at raw SIDs in a report is not very friendly, so I wrote a function that translates domain SIDs into domain names.  This makes the SID history report more meaningful when you can see the name of the domain from whence they came.  Enumerating all forest trusts and their domain SIDs required using some .NET ninja skills.
6.  [How To Remove SID History With PowerShell](/b/ashleymcglone/archive/2011/11/23/how-to-remove-sid-history-with-powershell.aspx "How To Remove SID History With PowerShell")  
    To round out the functions I provided Get-SIDHistory and Remove-SIDHistory, emphasizing that this is the LAST step in the process.  I leveraged the previous domain SID function to even give us the ability to remove SID history selectively by old domain name.

I suggest that you go back and read all of the articles linked above. They will give you much more insight into the SID history cleanup process and the nuances of the provided functions. Then skim through the [ADMT Guide](http://www.microsoft.com/downloads/en/details.aspx?FamilyID=6D710919-1BA5-41CA-B2F3-C11BCB4857AF "ADMT Guide") to get familiar with the big picture.

All of these functions are now wrapped up in the module provided in today's blog post.

### Installing the Module

If you've never installed a module there really isn't much to it.  Here's what you do:

1.  Create the module folder (adjust Documents path if necessary):  
    <span style="font-family:Courier New">New-Item -Type Directory -path "$home\Documents\WindowsPowerShell\Modules\SIDHistory"</span>
2.  Download the attached ZIP file at the bottom of this article.
3.  Unzip the contents into this path:  
    C:\Users\<username>\Documents\WindowsPowerShell\Modules\SIDHistory\
4.  Fire up the PowerShell console or ISE.
5.  <span style="font-family:Courier New">Import-Module ActiveDirectory</span> (This is a prerequisite.)
6.  <span style="font-family:Courier New">Import-Module SIDHistory</span>

Now you can use Get-Command and Get-Help to unwrap the present and see what's inside:

*   <span style="font-family:Courier New">Get-Command -Module SIDHistory</span>
*   <span style="font-family:Courier New">Get-Help Get-SIDHistory -Full</span>
*   <span style="font-family:Courier New">Get-Help Get-SIDHistory -Online</span>
*   <span style="font-family:Courier New">Get-Command -Module SIDHistory | Get-Help -Full | More</span>

You can use <span style="font-family:Courier New">Get-Help -Full</span> for each of the included functions to find syntax and descriptions.

### Using the Module

The outline below will guide you through the process of using the functions to help remediate SID history.  Run them in this order.

*   Start up:
    *   <span style="font-family:Courier New">Import-Module ActiveDirectory</span>
    *   <span style="font-family:Courier New">Import-Module SIDHistory</span>
*   Get the SID history report:
    *   <span style="font-family:Courier New">Export-DomainSIDs</span>
    *   <span style="font-family:Courier New">Export-SIDMapping</span>
    *   <span style="font-family:Courier New">Update-SIDMapping</span>
    *   Open the SIDReportUpdated.csv file in Excel to see all of the SID history in your environment.
    *   Keep an archive copy of these output files for documentation at the end of the project.
*   Use the [ADMT](http://www.microsoft.com/download/en/details.aspx?id=8377 "ADMT") for server migration:
    *   Use the SIDMap.csv file with the ADMT to migrate servers with SID history.  This file recovers your OldSID/NewSID data from former migrations so that you can finish security translation on servers.
*   NAS permission migration:
    *   If you have NAS-based file shares, migrate SID history of NTFS shares this way:
    *   Run with -WhatIf the first time to see if there is any SID history to translate.
    *   <span style="font-family:Courier New">Convert-SIDHistoryNTFS \\server\share\path –WhatIf</span>
    *   Review the report files.  Run again without -WhatIf to actually update the ACLs.
    *   <span style="font-family:Courier New">Convert-SIDHistoryNTFS \\server\share\path</span>
    *   Review the report files.
    *   Confirm share file access with affected users and groups.
*   Remove the SID history:
    *   Confirm that you have good backups of Active Directory system state on two DCs in every domain.  You should always have a backout plan in case you missed some SID history remediation.
    *   Once SID history remediation is verified on all servers you can begin removing SID history in phases.  First, use Get-SIDHistory to target the removal population with a specific query.  Second, pipe the output to Remove-SIDHistory.  Here are some examples:
    *   <span style="font-family:Courier New">Get-SIDHistory –MemberOf AccountingDept</span>
    *   <span style="font-family:Courier New">Get-SIDHistory –MemberOf AccountingDept | Remove-SIDHistory</span>
    *   <span style="font-family:Courier New">Get-SIDHistory –DomainName alpineskihouse.com</span>
    *   <span style="font-family:Courier New">Get-SIDHistory –DomainName alpineskihouse.com | Remove-SIDHistory</span>
    *   See the help for extensive filtering capabilities of Get-SIDHistory.
*   Check your work:
    *   Make an archive copy of your first SIDReportUpdated.csv and SIDMap.csv files.
    *   <span style="font-family:Courier New">Export-SIDMapping</span>
    *   Use the SIDReport.csv file as an audit to see where SID history remains.
    *   Repeat the migration and removal processes until this report comes back empty.
*   Remediation (ie. Damage Control):
    *   Assuming that your security translation was thorough then you should not see any issues.
    *   If the help desk only gets a couple calls:
        *   Manually clean up the permissions on a case-by-case basis.
    *   If the help desk gets hammered with calls, then you have a couple options:
        *   Identify the scope of impact and remediate those servers by doing more security translation.  You may have missed a few.
        *   Do an AD authoritative restore to recover the SID history of impacted users.

The functions provided in this module will give you added visibility into the status of your SID history throughout the process and an easy way to target removal in the final phase.

### Conclusion

This SID history project has been a lot of fun, and I'm sure there's more we could do with it.  I have a few ideas of my own, but I would like to hear your feedback.  What challenges have you encountered with SID history remediation?  Where do you think PowerShell could help?  Leave a comment below and let me know.

### Additional Reading

*   [Get-Help about_Modules](http://technet.microsoft.com/en-us/library/dd819458.aspx "Get-Help about_Modules")
*   [Active Directory Migration Tool (ADMT) Guide: Migrating and Restructuring Active Directory Domains](http://www.microsoft.com/downloads/en/details.aspx?FamilyID=6D710919-1BA5-41CA-B2F3-C11BCB4857AF "Active Directory Migration Tool (ADMT) Guide: Migrating and Restructuring Active Directory Domains")

<div class="scriptcode">

<div class="pluginEditHolder" plugincommand="mceScriptCode">

<div class="title"><span>PowerShell</span></div>

<div class="pluginLinkHolder"><span class="pluginEditHolderLink">Edit</span>|<span class="pluginRemoveHolderLink">Remove</span></div>

<span class="hidden">powershell</span>

<pre class="hidden">Import-Module ActiveDirectory
Import-Module SIDHistory
</pre>

<div class="preview">

<pre class="powershell">Import<span class="powerShell__operator">-</span>Module ActiveDirectory 
Import<span class="powerShell__operator">-</span>Module SIDHistory 
</pre>

</div>

</div>

</div>

* * *

<span style="font-size:medium">**JUNE 15, 2012 UPDATE**</span>

### More SID History

I get emails frequently from folks who have read my [series of articles](http://blogs.technet.com/b/ashleymcglone/archive/tags/SID+history/ "series of articles") on Active Directory SID history, so I'm guessing that is a good theme to continue.  Working with a customer recently I was able to enhance the functionality in the **Active Directory SID history PowerShell module** that I posted last [December](http://blogs.technet.com/b/ashleymcglone/archive/2011/12/22/powershell-module-for-working-with-ad-sid-history.aspx "December").  Today's post will publish and discuss those improvements.

<span style="font-family:Courier New">Version 1.4  
June, 2012</span>

<span style="font-family:Courier New">Functions added in this release:  
Export-SIDHistoryShare  
Merge-CSV</span>

<span style="font-family:Courier New">Functions modified in this release:  
Convert-SIDHistoryNTFS  
Export-SIDMapping  
Update-SIDMapping  
Get-SIDHistory</span>

<span style="font-family:Courier New">Fixes:  
Removed Test-Path validation on NewReport parameter of Update-SIDMapping.  
Added file validation for DomainFile parameter of Get-SIDHistory.</span>

### It's All About The Customer

Imagine if…

*   your company acquired an average of 12 other companies each year.
*   your forest had over 35 domains (consolidated from 50+).
*   your forest had over 80 trusts to other domains you still need to migrate.
*   your forest had over 172,000 instances of SID history.
*   you lived in the [ADMT](http://www.microsoft.com/downloads/en/details.aspx?FamilyID=6D710919-1BA5-41CA-B2F3-C11BCB4857AF "ADMT") from sun up to sun down.
*   token bloat plagued your support engineers with mystery troubleshooting.

Obviously I can't make this stuff up.  Those points describe a customer who recently invited me to help them develop a process to identify and remediate SID history in their forest.  This also gave them a process going forward that would help them do future domain migrations in a way that would minimize the impact of SID history.

### Enter PowerShell

I knew the SID history PowerShell module could help them, but I also knew that some improvements would be necessary to help them scale to the size of data collection they would need.  Here's what I did:

*   I added a function called Export-SIDHistoryShare that will collect SID history information from share permissions.  (Note that it will not convert SID history as the NTFS function does.)
*   I modified the NTFS SID translation report CSV generated by Convert-SIDHistoryNTFS so that the columns would match the output from the new share CSV output.  This involved adding ACLType and DateTimeStamp.
*   Both NTFS and Share reports now include a date time stamp so that the CSV data can be imported into a larger database multiple times.  Different scans of the same data will be distinguished by the date time stamp.
*   I modified the Export-SIDMapping and Update-SIDMapping to include a date time stamp field as well for the same reasons.
*   I created a new function called Merge-CSV that will take all of the NTFS and Share SID history reports and roll them into a single, large CSV file for importing to a database (like Microsoft Access or Microsoft SQL).
*   <span style="background-color:#ffff00">This is huge!  I created a quick proof-of-concept Access database that would relate the forest object SID history data against the SID history discovered in shares and NTFS permissions on servers.  This is super powerful for analyzing the impact of SID history.  Now you can produce reports that tell you:</span>
    *   <span style="background-color:#ffff00">which former domain has the most SID history</span>
    *   <span style="background-color:#ffff00">which groups with SID history are most used on your file servers</span>
    *   <span style="background-color:#ffff00">which file servers need ACL translation with the ADMT</span>
    *   <span style="background-color:#ffff00">where to target your remediation efforts for the largest impact</span>
    *   <span style="background-color:#ffff00">where to begin the cleanup with the users and groups whose SID history is not in use</span>
    *   <span style="background-color:#ffff00">etc.</span>
*   I also resolved one issue with the NewReport parameter of the Update-SIDMapping function and resolved one issue with the DomainFile parameter of the Get-SIDHistory function. (Special thanks to [Andrew Hill](http://social.technet.microsoft.com/profile/andrewdhill/?ws=usercard-inline "Andrew Hill") and [Greg Jaworski](http://blogs.technet.com/b/askpfeplat/archive/2012/01/16/how-to-become-a-premier-field-engineer-pfe.aspx "Greg Jaworski") for their feedback.)

These changes added the scalability and flexibility for the customer to begin inventorying hundreds for servers for SID history and manage all the data with a full database they would implement later on their own.  I love the simplicity of CSV in PowerShell!

### The New Process

My [last post on SID history](http://blogs.technet.com/b/ashleymcglone/archive/2011/12/22/powershell-module-for-working-with-ad-sid-history.aspx "last post on SID history") has the overall steps for installing the module and completing the SID history remediation so I will not repeat that content here.  But I do want to list out the steps for you to automate the NTFS and share SID history data collection:

*   Inventory SID history in share and NTFS ACLs:
    *   Run these commands against the servers and share paths where you want to check for  
        SID history:
        *   Convert-SIDHistoryNTFS \\servername\share\path –WhatIf
        *   Export-SIDHistoryShare servername
        *   _NOTE: You will need to run this under an administrative account that has permissions to view all of the recursive subfolders._
    *   Repeat these steps for all servers where you want to collect data.  See the example code below for another way to automate mass data collection.
    *   Now merge all of the output into a single CSV file for analysis:
        *   Put all of the Share and NTFS CSV output files into a new working folder.
        *   Merge-CSV –Path "C:\Temp\WorkingFolder"
        *   This creates a merged CSV called ACL_SID_History_xxxxxxxxxxxxxxxx.csv.
*   Copy these two files to the folder with the provided Access database:
    *   SIDReportUpdated.csv
    *   ACL_SID_History_xxxxxxxxxxxxxxxx.csv
*   Rename the ACL_SID_History_xxxxxxxxxxxxxxxx.csv file to ACL_SID_History.csv.
*   Open the Access database.
*   In order for the linked tables in Access to see these new files you must repair the links and point them to the files in your working folder.
    *   Right click the table ACL_SID_History on the left.
    *   Choose “Linked Table Manager”.
    *   Check the box at the bottom “Always prompt for new location”.
    *   Check the box beside each of the two tables.
    *   Click OK.
    *   Browse to the each of the two CSV files that you just copied into the database folder. Pay special attention to the title bar of the File browser dialog box. Make sure that you choose the file that matches the name in the title bar.
    *   Close the Linked Table Manager dialog box.
*   Now you can double click any of the example queries on the left to see the data analysis.  You can also create your own queries and custom reports.

### Automating the Automation

It would be quite time consuming to run the NTFS and share scan commands one at a time against all of your servers.  Instead try these handy PowerShell routines to make the data collection go faster.  As these processes usually take hours to scan large file shares it would be a good idea to let them run over a night or weekend.

<pre><span style="color:#006400"># Sample code to scan a group of Windows servers in a text file.</span>
<span style="color:#ff4500">$Servers</span> <span style="color:#a9a9a9">=</span> <span style="color:#0000ff">Get-Content</span> <span style="color:#8b0000">".\servers.txt"</span>
<span style="color:#00008b">ForEach</span> <span style="color:#000000">(</span><span style="color:#ff4500">$ComputerName</span> <span style="color:#00008b">in</span> <span style="color:#ff4500">$Servers</span><span style="color:#000000">)</span> <span style="color:#000000">{</span>
    <span style="color:#0000ff">Export-SIDHistoryShare</span> <span style="color:#ff4500">$ComputerName</span>
    <span style="color:#006400"># Grab only file shares that were manually created</span>
    <span style="color:#ff4500">$Shares</span> <span style="color:#a9a9a9">=</span> <span style="color:#0000ff">Get-WmiObject</span> <span style="color:#8a2be2">Win32_Share</span> <span style="color:#000080">-ComputerName</span> <span style="color:#ff4500">$ComputerName</span> <span style="color:#000080">-Filter</span> <span style="color:#8b0000">"Type=0"</span>
    <span style="color:#00008b">ForEach</span> <span style="color:#000000">(</span><span style="color:#ff4500">$Share</span> <span style="color:#00008b">in</span> <span style="color:#ff4500">$Shares</span><span style="color:#000000">)</span> <span style="color:#000000">{</span>
        <span style="color:#0000ff">Convert-SIDHistoryNTFS</span> <span style="color:#8b0000">"\\$ComputerName\$($Share.Name)"</span> <span style="color:#000080">-WhatIf</span>
    <span style="color:#000000">}</span>
<span style="color:#000000">}</span>

<span style="color:#006400"># Sample code to scan a list of share paths in a text file.</span>
<span style="color:#006400"># This can work for Windows or NAS servers.</span>
<span style="color:#ff4500">$Shares</span> <span style="color:#a9a9a9">=</span> <span style="color:#0000ff">Get-Content</span> <span style="color:#8b0000">".\shares.txt"</span>
<span style="color:#00008b">ForEach</span> <span style="color:#000000">(</span><span style="color:#ff4500">$Share</span> <span style="color:#00008b">in</span> <span style="color:#ff4500">$Shares</span><span style="color:#000000">)</span> <span style="color:#000000">{</span>
    <span style="color:#0000ff">Convert-SIDHistoryNTFS</span> <span style="color:#ff4500">$Share</span> <span style="color:#000080">-WhatIf</span>
<span style="color:#000000">}</span></pre>

### Where can I get all this PowerShell goodness?

I have updated this code at the TechNet Script Gallery.  Attached to that entry you'll find the following in a single compressed file:

*   Updated PowerShell module for AD SID history
*   Sample output data files
*   Sample Access database (You must update the linked tables to point to the CSV files.  See instructions above.)
*   Sample script file for using the module

Extract all of the files into a working folder.  [Install the module](http://blogs.technet.com/b/ashleymcglone/archive/2011/12/22/powershell-module-for-working-with-ad-sid-history.aspx "Install the module").  The usual [disclaimers](http://blogs.technet.com/b/ashleymcglone/about.aspx "disclaimers") apply: this is sample code for use at your own risk.  Enjoy!

* * *

<span style="font-size:medium">**JULY 9, 2013 UPDATE**</span>

_To see all of the articles in this series visit_ [_http://aka.ms/SIDHistory_](http://aka.ms/SIDHistory "http://aka.ms/SIDHistory")_._

I would like to thank everyone who has been using the [Active Directory SIDHistory PowerShell module](http://gallery.technet.microsoft.com/PowerShell-Module-for-08769c67 "http://gallery.technet.microsoft.com/PowerShell-Module-for-08769c67") and sending me [feedback](http://blogs.technet.com/b/ashleymcglone/contact.aspx "http://blogs.technet.com/b/ashleymcglone/contact.aspx").  Your input helps guide future releases like the one I am publishing today.

I’ve been sitting on some updates for a while, because I prefer to release code that has been field-tested.  I also wanted to time this release with the upcoming [PowerShell Deep Dives](http://blogs.technet.com/b/ashleymcglone/archive/2013/07/02/microsoft-pfe-ashley-mcglone-speaking-for-mspsug-virtual-user-group-on-tuesday-july-9th-at-8-30pm-cdt.aspx "http://blogs.technet.com/b/ashleymcglone/archive/2013/07/02/microsoft-pfe-ashley-mcglone-speaking-for-mspsug-virtual-user-group-on-tuesday-july-9th-at-8-30pm-cdt.aspx") book where I have a chapter discussing the origins of this module.  The last update was version 1.4 in June of 2012.  This is update 1.5 in July of 2013.

## Summary of Changes

I am excited to announce the following key improvements in this release:

*   SID history updates in ACLs can be added instead of replaced.
*   Create SID map files for security translation without needing SID history.
*   Track down old domains after their trusts have been removed.
*   Get error logging for file server paths that fail the ACL scan.
*   Automate SID history data collection across many servers and shares.

<div style="background-color:#dddddd">

**Note:**  This module version is compatible with PowerShell v2 and any newer versions.  The next release will require PowerShell v3 as a minimum level.

</div>

## Change Details

<span style="background-color:#ffff00">This release includes some significant changes and additions, which I have highlighted below.</span> Here is a list of the functions in this release:

<pre style="margin:10px; border:10px solid #012456; color:#ffffff; font-family:monospace; background-color:#012456">PS C:\> Get-Command -Module SIDHistory

CommandType Name                     ModuleName
----------- ----                     ----------
Function    Convert-SIDHistoryNTFS   SIDHistory
Function    Export-DomainSIDs        SIDHistory
Function    Export-SIDHistoryShare   SIDHistory
Function    Export-SIDMapping        SIDHistory
Function    Export-SIDMappingCustom  SIDHistory
Function    Get-ADObjectADSI         SIDHistory
Function    Get-DomainSIDWordCount   SIDHistory
Function    Get-SIDHistory           SIDHistory
Function    Get-SIDHistoryDuplicates SIDHistory
Function    Merge-CSV                SIDHistory
Function    Remove-SIDHistory        SIDHistory
Function    Search-SIDHistoryACL     SIDHistory
Function    Update-SIDMapping        SIDHistory
Function    Watch-Job                SIDHistory
</pre>

Due to the large number of changes I am not going to include code samples for each function in this article.  Please use <span style="font-family:Courier New">Get-Help -Full</span> to see complete details and examples for each module member.

<pre style="margin:10px; border:10px solid #012456; color:#ffffff; font-family:monospace; background-color:#012456">PS C:\> Get-Help Convert-SIDHistoryNTFS -Full

PS C:\> Get-Help Export-SIDMappingCustom -Full

PS C:\> Get-Help Get-DomainSIDWordCount -Full

Etc...</pre>

## Functions Added

### <span style="background-color:#ffff00">Export-SIDMappingCustom</span>

*   I had a customer who was not able to use the Active Directory Migration Tool for a domain migration.  The newly acquired subsidiary was not allowed to create a trust for compliance reasons.  Obviously we need a trust to do a migration.  Or do we?
*   To work around the situation I wrote a function that will map SIDs between accounts in two different domains where there is no SID history.  The trick is having a common, unique attribute like samAccountName, employeeID, employeeNumber, mail, etc.
*   The customer manually exported the accounts from the old domain and imported them into the new domain.  Next they made sure that their HR system populated the same unique Employee ID in the new domain.  Now they had a common, unique key between the two domains.
*   In the old 2003 domain we used an ADSI script to create a file containing the objectSID and employeeID attributes.  (See <span style="font-family:Courier New">Get-ADObjectADSI</span> described below.)  This is all we needed to create our mapping file.  We copied this file across international borders to the local new domain.
*   Now we can use the new <span style="font-family:Courier New">Export-SIDMappingCustom</span> function to create a mapping file between the exported SID data from the old domain and the live accounts in the new domain.  This is only one possible scenario with the function.  It can use any combination of live connection or export file from the old and new domains.
*   In this particular case the customer only wanted to migrate the file server from the old domain.  With this new SID mapping file they were able to run <span style="font-family:Courier New">Convert-SIDHistoryNTFS</span> against the old server to re-ACL the resources.  This is POWERFUL.  Essentially, <span style="background-color:#ffff00">you can do a NAS ACL migration without SID history in place.</span>
*   This works for both users and groups.  At another customer they wanted to migrate several domain local groups.  The groups had been recreated with the same name in the new domain without SID history.  The <span style="font-family:Courier New">Export-SIDMappingCustom</span> function was able to create a mapping file by matching the group names between both old and new live domains and then putting both SIDs into a mapping file.

### Get-SIDHistoryDuplicates

*   There are [processes to resolve duplicate SIDs](http://social.technet.microsoft.com/wiki/contents/articles/14578.find-and-clean-up-duplicate-sid.aspx "http://social.technet.microsoft.com/wiki/contents/articles/14578.find-and-clean-up-duplicate-sid.aspx") on accounts but not for duplicate SID history.
*   This should never never never happen.  But it happened for one customer, the same customer where I discovered 100 unique old domains.  We’re not sure how the duplicate SID history entries got there, because there were years of migration history with a variety of migration tools.
*   Duplicates in SID history are a violation of everything we know to be good and true.  There can only be one.  If duplicates are found, then it would invalidate the SID mapping process.
*   To find these I wrote this function to generate a report.  Once identified, the customer chose to simply delete the accounts with the duplicates, because they were old empty groups.

### <span style="background-color:#ffff00">Search-SIDHistoryACL</span>

*   In this module two main functions do all of the work to discover SID history on shares and files:  <span style="font-family:Courier New">Convert-SIDHistoryNTFS</span> and <span style="font-family:Courier New">Export-SIDHistoryShare</span>.  In order to fully document SID history on your file servers you need to call each of these functions for each share on each server.  That’s a lot of calls.
*   This is a “meta-function” that calls these two functions for a batch of servers or shares listed in either an OU or a text file.  Using PowerShell background jobs it scans them all in parallel to reduce the discovery time required.
*   My only caution is that there is no throttling built in.  Run these in small batches of servers until you see how the performance works out with your hardware.
*   Use the following <span style="font-family:Courier New">Watch-Job</span> function to manage these background jobs.

### Watch-Job

*   This function conveniently manages receiving the output from the jobs spun up by <span style="font-family:Courier New">Search-SIDHistoryACL</span>.  It displays a PowerShell progress bar indicating how many jobs are still running.  Once they are all complete it will receive the output into a consolidated job log and report on each job’s start and end times.  All of the ACL output files are rendered separately by their respective jobs.
*   Optionally you can have the function clear the job queue with the <span style="font-family:Courier New">-Remove</span> switch.
*   This is a utility function, and it could be modified easily for many other background job scenarios.

### <span style="background-color:#ffff00">Get-DomainSIDWordCount</span>

*   The [<span style="font-family:Courier New">Export-DomainSIDs</span>](http://blogs.technet.com/b/ashleymcglone/archive/2011/10/12/powershell-sid-walker-texas-ranger-part-3-getting-domain-sids-and-trusts.aspx "http://blogs.technet.com/b/ashleymcglone/archive/2011/10/12/powershell-sid-walker-texas-ranger-part-3-getting-domain-sids-and-trusts.aspx") function crawls all trusts in the forest to identify domain names and domain SIDs.  <span style="background-color:#ffff00">When old trusts to migrated domains are gone you can no longer identify where SID history originated… until now.</span>
*   The function creates a list of word counts gleaned from popular string attributes found on accounts from each old domain SID identified in the forest.  This gives you clues about where the accounts in the unidentified SID history domain may have originated.  For example, employees migrated from the old ContosoPartner domain may have that company name string in their description, department, display name, or OU path.  By finding and counting the common strings across all migrated accounts you can usually identify the old domain.
*   This process gives you the information needed to manually update the DomainSIDs.csv file.  After updating the file re-run the <span style="font-family:Courier New">Update-SIDMapping</span> function to add these old domain names to your master SID history report.
*   Pipe the output to <span style="font-family:Courier New">Export-CSV</span> or <span style="font-family:Courier New">Out-GridView</span> for easy viewing.

### Get-ADObjectADSI

*   I wrote this utility function for a customer with legacy DCs where they were not going to install the AD web service.  They installed PowerShell, and we used this function to create the account listing for <span style="font-family:Courier New">Export-SIDMappingCustom</span>.  It uses ADSI to mimic <span style="font-family:Courier New">Get-ADObject</span>, but it was a point solution not intended for full parity with the AD module cmdlet.  This function is intentionally undocumented, because most environments will not need it.  Feel free to modify it to meet your needs.

## Functions Modified

### Export-SIDMapping

*   I added description and whenCreated attributes to the SIDReport.CSV.  These properties help identify accounts in the list, especially old accounts that are likely stale.
*   By mistake I was running the AD query twice in this function, so I corrected it to only run once.  Obviously this will greatly improve performance.

### Update-SIDMapping

*   Added description and whenCreated to SIDReportUpdated.CSV for same reasons listed above.

### <span style="background-color:#ffff00">Convert-SIDHistoryNTFS</span>

*   Added <span style="font-family:Courier New">-Add</span> switch.  The previous functionality did an ACE replace only.  <span style="background-color:#ffff00">Now you have the option of doing a replace or an add.  This way you can co-exist with both old and new SIDs temporarily until you are ready to completely remove all old SIDs from the ACLs.</span>  Running without the <span style="font-family:Courier New">-Add</span> switch gives you a replace, leaving the new SID and removing the old SID.
*   As a result of the new <span style="font-family:Courier New">-Add</span> switch I had to modify the CSV output and log files to report the status of both Old SID and New SID in the ACLs.  The “Both” column will be true if both the old and new SIDs are present in the ACL.  The “Operation” column will now say “Add” or “Replace”.  Added new column for NewDomainSID.
*   After more field testing I discovered that there were some issues scanning folders.  In prior releases you would see red text in the PowerShell console, but you didn’t know where the errors occurred. <span style="background-color:#ffff00">I added error logging so that you get a list of the reasons and the paths where the ACL scans fail down inside the folder tree.</span>  Primarily I’ve found three issues:
    *   1\. **Path too long.**  I spent a lot of time investigating this issue.  The <span style="font-family:Courier New">Get-ACL -Path</span> parameter is limited to paths of 260 characters or less.  I found this [TechNet Wiki](http://social.technet.microsoft.com/wiki/contents/articles/12179.net-powershell-path-too-long-exception-and-a-net-powershell-robocopy-clone.aspx "http://social.technet.microsoft.com/wiki/contents/articles/12179.net-powershell-path-too-long-exception-and-a-net-powershell-robocopy-clone.aspx") article and this [blog series](http://blogs.msdn.com/b/bclteam/archive/2007/02/13/long-paths-in-net-part-1-of-3-kim-hamilton.aspx "http://blogs.msdn.com/b/bclteam/archive/2007/02/13/long-paths-in-net-part-1-of-3-kim-hamilton.aspx"), but none of the proposed work-arounds were applicable.  As a temporary work-around if you run into this problem you may be able to map a drive down farther in the folder structure of longer paths and run the scan again for that newly mapped path.  This is due to an underlying .NET limitation.  Unfortunately this error only gets logged when running in PowerShell v3.  PowerShell v2 will not report this error in a way that we can trap.
    *   2\. **Invalid character in path.**  I discovered an issue with <span style="font-family:Courier New">Get-ACL</span> that does not return an object when the path contains a ‘[‘ character.  After researching this on the [Microsoft PowerShell Connect](http://connect.microsoft.com/powershell/ "http://connect.microsoft.com/powershell/") site I found that it is resolved in PowerShell v3 with the new <span style="font-family:Courier New">-LiteralPath</span> parameter.  For now I am logging the error until I update the module to use PowerShell v3 features.
    *   3\. **Access denied.**  Using this function you often find file shares where Administrator rights have been removed.  To resolve this either rescan the path in question with appropriate credentials or modify the permissions on the path.

### Export-SIDHistoryShare

*   Modified CSV columns to match the output from <span style="font-family:Courier New">Convert-SIDHistoryNTFS</span>.  This allows all results to be consolidated into a single CSV report.

## Time-Saving Tip

When using <span style="font-family:Courier New">Convert-SIDHistoryNTFS -WhatIf</span> to scan servers and shares it can take hours or days depending on the size of the environment.  Sometimes you may only find a few SIDHistory entries that need to be remediated.  Rather than rescan the entire server or share to fix these ACLs you can target the SID history cleanup this way to save time:

<pre style="margin:10px; border:10px solid #012456; color:#ffffff; font-family:monospace; background-color:#012456">PS C:\> Import-CSV ACL_SID_History.csv |
 Select-Object -Unique -ExpandProperty Folder |
 ForEach-Object {Convert-SIDHistoryNTFS $_}</pre>

In this example ACL_SID_History.csv is the NTFS permission scan output from <span style="font-family:Courier New">Convert-SIDHistoryNTFS -WhatIf</span>.  We simply get a unique list of folders and feed those into the conversion function.  Obviously this is much faster than rescanning every ACL of every folder in the share subtree.

<span style="background-color:#ffff00">Please use the comment area below to tell me what features you would like to see improved or added in the module.  I would also appreciate any feedback for how this has helped your projects.</span>

<span style="background-color:#ffff00">  
</span>

## September 2014 Update

## Version 1.6.1

## Better

In large environments I commonly ran into an issue with the “[“ character in file paths. PowerShell version 3.0 resolves this issue by using the <span style="font-family:Courier New">–LiteralPath</span> parameter instead of the <span style="font-family:Courier New">–Path</span> parameter for cmdlets working in the file system.

## Stronger

Lately I’ve been learning about external help files for PowerShell modules. With this release I have moved the help content from comment-based help inside the module to an external XML help file. I also added an _about_ topic with documentation and release notes. Let me know if you find any mistakes in the updated help.

## Faster

Last year I worked with a customer to improve the speed of the most significant function <span style="font-family:Courier New">Convert-SIDHistoryNTFS</span>. This involved two changes:

I made a new baseline requirement of PowerShell version 3.0\. This gives us the <span style="font-family:Courier New">–Directory</span> switch on <span style="font-family:Courier New">Get-ChildItem</span>, which saves a huge amount of time when you are scanning a file server with terabytes of files and folders. We only want the folder list anyway. This is a great example of “filter left” in PowerShell.

It turns out that using <span style="font-family:Courier New">Out-File –Append</span> for logging can be very expensive for performance and consumes a lot of memory. I converted this to use <span style="font-family:Courier New">System.IO.FileStream</span> for much more efficient use of resources and speed.

## Result

Now the code is faster, uses less memory, and yields better results. The trade off is that now you must run the code from [PowerShell version 3.0](http://www.microsoft.com/en-us/search/DownloadResults.aspx?q=wmf%20powershell "http://www.microsoft.com/en-us/search/DownloadResults.aspx?q=wmf%20powershell") or newer.  I don’t think that is a big deal, because we are almost to version 5.0 as of this writing. Time to level up.

<span style="background-color:#ffff00">  
</span>

### But Wait!  There's More…

If you would like me or [another Microsoft PFE](http://blogs.technet.com/b/askpfeplat "another Microsoft PFE") to visit your company and help you with the ideas discussed on this blog, please contact your Premier Technical Account Manager (TAM).  We would love to come see you.

Follow me on Twitter: [@GoateePFE](https://twitter.com/#!/GoateePFE "@GoateePFE").

</div>