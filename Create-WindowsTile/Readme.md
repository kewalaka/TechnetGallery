<div id="longDesc">

[![](http://aka.ms/onescriptsampletopbanner)](http://aka.ms/onescriptsampletopbannerlink)

****<span style="color:black; line-height:21px; letter-spacing:0.25pt; font-family:Cambria,serif; font-size:14pt">Script to create a Shutdown/Restart/Logoff Windows 8 Tile for the Start menu(PowerShell)</span>****

## **Introduction**

This PowerShell Script shows how to create a Shutdown, Restart or Logoff Windows 8 tile for the Start menu.

## **Scenarios**

Many users would like to shut down or reboot Windows 8 in just one click. This script enables users to click a tile to shut down, reboot or log off Windows on the Start menu.

## **Script**

**Step 1:** Start the PowerShell Console with administrator. To run the script in the Windows PowerShell Console, type the command< Script Path> at the Windows PowerShell Console.

**Step 2:**If you want to know how to use this script. You can type thecommand** Get-Help ****C:****\Script\CreateWindowsTile.ps1 ****-Full** to display the entire help file for this function, such as the syntax, parameters, or examples.  
![](http://i1.gallery.technet.s-msft.com/create-a-shutdownrestartlog-37c8111d/image/file/108447/1/image001.png) 

<span>Here are some code snippets for your references.  
</span>

<div class="scriptcode">

<div class="pluginEditHolder" plugincommand="mceScriptCode">

<div class="title"><span>PowerShell</span></div>

<div class="pluginLinkHolder"><span class="pluginEditHolderLink">Edit</span>|<span class="pluginRemoveHolderLink">Remove</span></div>

<span class="hidden">powershell</span>

<pre class="hidden">#create a new shortcut of shutdown
$ShutdownShortcutPath = "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Shutdown.lnk"
$ShutdownShortcut = $WshShell.CreateShortcut($ShutdownShortcutPath)
$ShutdownShortcut.TargetPath = "$env:SystemRoot\System32\shutdown.exe"
$ShutdownShortcut.Arguments = "-s -t 0"
$ShutdownShortcut.Save()

#change the default icon of shutdown shortcut
$ShutdownLnk = $Desktop.ParseName($ShutdownShortcutPath)
$ShutdownLnkPath = $ShutdownLnk.GetLink
$ShutdownLnkPath.SetIconLocation("$env:SystemRoot\System32\SHELL32.dll",27)
$ShutdownLnkPath.Save()</pre>

<div class="preview">

<pre class="powershell"><span class="powerShell__com">#create a new shortcut of shutdown</span> 
<span class="powerShell__variable">$ShutdownShortcutPath</span> = <span class="powerShell__string">"$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Shutdown.lnk"</span> 
<span class="powerShell__variable">$ShutdownShortcut</span> = <span class="powerShell__variable">$WshShell</span>.CreateShortcut(<span class="powerShell__variable">$ShutdownShortcutPath</span>) 
<span class="powerShell__variable">$ShutdownShortcut</span>.TargetPath = <span class="powerShell__string">"$env:SystemRoot\System32\shutdown.exe"</span> 
<span class="powerShell__variable">$ShutdownShortcut</span>.Arguments = <span class="powerShell__string">"-s -t 0"</span> 
<span class="powerShell__variable">$ShutdownShortcut</span>.Save() 

<span class="powerShell__com">#change the default icon of shutdown shortcut</span> 
<span class="powerShell__variable">$ShutdownLnk</span> = <span class="powerShell__variable">$Desktop</span>.ParseName(<span class="powerShell__variable">$ShutdownShortcutPath</span>) 
<span class="powerShell__variable">$ShutdownLnkPath</span> = <span class="powerShell__variable">$ShutdownLnk</span>.GetLink 
<span class="powerShell__variable">$ShutdownLnkPath</span>.SetIconLocation(<span class="powerShell__string">"$env:SystemRoot\System32\SHELL32.dll"</span>,27) 
<span class="powerShell__variable">$ShutdownLnkPath</span>.Save()</pre>

</div>

</div>

</div>

## **Example**

**Example 1: **Type**C:****\Script\CreateWindowsTile.ps1 **in the Windows PowerShell Console.

It will create a shutdown, restart and logoff Windows 8 tile to the Start menu.  
![](http://i1.gallery.technet.s-msft.com/create-a-shutdownrestartlog-37c8111d/image/file/107234/1/image004.png)

As you can see, in the following figure, the shutdown, restart and logoff Windows 8 tile has been created successfully.  
![](http://i1.gallery.technet.s-msft.com/create-a-shutdownrestartlog-37c8111d/image/file/107235/1/image006.png)

**Prerequisite**

Windows PowerShell 3.0

Windows 8

## **Additional Resources**

[New-Object](http://technet.microsoft.com/library/hh849885.aspx)

</div>