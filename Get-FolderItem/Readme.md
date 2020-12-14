<div id="longDesc">

<span style="font-size:small">A common dissapointment when scanning for files (Get-ChildItem for example) is when you hit the 260 character path limit. By combining robocopy and PowerShell, you now have a powerful tool that can perform a scan for files regardless of the max path limitation of 260 characters. The Get-FolderData function will output the Fullname, size in bytes, parent folder and the lastwritetime of all files as an object that can then be exported to a logfile or you can use measure-object to get the count of all files and total size, if needed.</span>

<span style="font-size:small">Blog post about this function: [http://learn-powershell.net/2013/04/01/list-all-files-regardless-of-260-character-path-restriction-using-powershell-and-robocopy/](http://learn-powershell.net/2013/04/01/list-all-files-regardless-of-260-character-path-restriction-using-powershell-and-robocopy/)</span>

<address>**<span style="font-size:small">Updated 9 Jan 2014:</span> **<span style="font-size:small">Fixed bug in -ExcludeFile parameter and fixed issue where running function against large folders would not generate output until robocopy run finished. Now the output is more streaming allowing you to see the data right away.</span></address>

<address>**<span style="font-size:small">﻿﻿Updated 8 Nov 2013:</span>** <span style="font-size:small">Added -ExcludeFiles parameter to allow exclusion of files.</span></address>

<address>**<span style="font-size:small">Update 29 July 2013:</span> **<span style="font-size:small">Added -Filter parameter to allow for filtering of files by name or type as well as a bug with the ParentFolder property not displaying the propery folder.</span></address>

<span style="font-size:small">Remember to dot source the script file to load the function into the current session.</span>

<span style="font-size:small"> </span>

<div class="scriptcode">

<div class="pluginEditHolder" plugincommand="mceScriptCode">

<div class="title"><span>PowerShell</span></div>

<div class="pluginLinkHolder"><span class="pluginEditHolderLink">Edit</span>|<span class="pluginRemoveHolderLink">Remove</span></div>

<span class="hidden">powershell</span>

<pre class="hidden">. .\Get-FolderItem.ps1</pre>

<div class="preview">

<pre class="powershell">. .\Get<span class="powerShell__operator">-</span>FolderItem.ps1</pre>

</div>

</div>

</div>

<div class="endscriptcode">

<div class="scriptcode">

<div class="pluginEditHolder" plugincommand="mceScriptCode">

<div class="title"><span>PowerShell</span></div>

<div class="pluginLinkHolder"><span class="pluginEditHolderLink">Edit</span>|<span class="pluginRemoveHolderLink">Remove</span></div>

<span class="hidden">powershell</span>

<pre class="hidden">Get-FolderItem -Path .\PowerShellScripts</pre>

<div class="preview">

<pre class="powershell">Get<span class="powerShell__operator">-</span>FolderItem <span class="powerShell__operator">-</span>Path .\PowerShellScripts</pre>

</div>

</div>

</div>

<div class="scriptcode">

<div class="pluginEditHolder" plugincommand="mceScriptCode">

<div class="title"><span>PowerShell</span></div>

<div class="pluginLinkHolder"><span class="pluginEditHolderLink">Edit</span>|<span class="pluginRemoveHolderLink">Remove</span></div>

<span class="hidden">powershell</span>

<pre class="hidden">Get-ChildItem | Get-FolderItem</pre>

<div class="preview">

<pre class="powershell"><span class="powerShell__cmdlets">Get-ChildItem</span> <span class="powerShell__operator">|</span> Get<span class="powerShell__operator">-</span>FolderItem</pre>

</div>

</div>

</div>

</div>

<div class="scriptcode">

<div class="pluginEditHolder" plugincommand="mceScriptCode">

<div class="title"><span>PowerShell</span></div>

<div class="pluginLinkHolder"><span class="pluginEditHolderLink">Edit</span>|<span class="pluginRemoveHolderLink">Remove</span></div>

<span class="hidden">powershell</span>

<pre class="hidden">Get-FolderItem -Path .\PowerShellScripts -MaxAge 186</pre>

<div class="preview">

<pre class="powershell">Get<span class="powerShell__operator">-</span>FolderItem <span class="powerShell__operator">-</span>Path .\PowerShellScripts <span class="powerShell__operator">-</span>MaxAge 186</pre>

</div>

</div>

</div>

</div>