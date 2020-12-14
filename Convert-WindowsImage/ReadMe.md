<div id="longDesc">## Description 

<div class="endscriptcode"><span style="font-size:small">**Convert-WindowsImage** is the new version of WIM2VHD designed specifically for Windows 10\. It also works fine with Windows 8 and Windows 8.1\. Completely rewritten in PowerShell, the **Convert-WindowsImage** command-line tool allows you to create generalized (“sysprepped”) VHD and VHDX images from any official build (ISO or WIM image) of Windows 7, Windows Server 2008 R2, Windows 8, Windows Server 2012, Windows 8.1 and Windows Server 2012 R2</span><span style="font-size:small">.</span></div>

<div class="endscriptcode"><span style="font-size:small"></span></div>

<div class="endscriptcode"><span style="font-size:small"><span style="color:#ff0000">**New**</span> in version **10** is support for **Windows 10 (and Windows Server 2016)** VMs and images. Full change log is below.</span></div>

<div class="endscriptcode"><span style="font-size:small"> </span></div>

<div class="endscriptcode"><span style="font-size:small">Images created by **Convert-WindowsImage** will boot directly to the Out Of Box Experience (OOBE), ready for your first-use customizations. So you can think of it as of replacement for your daddy's “Deploy-Sysprep-and-Capture” approach. You can also use these images for automation by supplying your own **unattend.xml** file, making the possibilities limitless. Fresh squeezed, organically grown, free-range VHDs—just like Mom used to make—that work with Virtual PC (Windows 7 only), Virtual Server (Windows 7 only), Microsoft Hyper-V, or Windows' Native VHD-Boot functionality!</span></div>

<div class="endscriptcode"><span style="font-size:small"></span></div>

<div class="endscriptcode"><span style="font-size:small">**Convert-WindowsImage** (just like its precessor, WIM2VHD tool) was originally created by **Mike Kolitz** ([http://social.technet.microsoft.com/profile/mike kolitz](http://social.technet.microsoft.com/profile/mike kolitz)) while he was a Microsoft Employee and worked on Windows. The tool is now maintained and evolved by his friends from Microsoft Consulting Services (MCS).</span></div>

## Change Log ### Version <span style="color:#ff0000">10</span> (June 2015) Note: Multiple <span style="color:#ff0000">breaking changes!</span> * <span style="font-size:small">**Works on (and with) <span style="color:#ff0000">Windows 10!</span> **(Also fully tested on Windows 8.1 with August 2014 and November 2014 updates).</span> * <span style="font-size:small"><span>The script is **now a Function!** You have to load it first (aka “dot-source”) and then call by its name, without extension.Please refer to the Examples section below for a code sample.</span></span> * <span style="font-size:small">**-Feature** parameter now supports multiple input (array of strings).</span> * <span style="font-size:small">**-Edition** parameter now supports multiple input (array of stings). Output will be multiple separate VHD(x)'es.</span> * <span style="font-size:small">**-Package. **New parameter to inject Windows packages (e.g. updates or language packs) into the image.</span> * <span style="font-size:small">**-RassThru** returns object(s) instead of a path.</span> * <span style="font-size:small">**Fix.** If the source is remote (UNC path), the script copies it locally into the user's temp directory. Previously the local copy was not removed afterwards. Now we correctly delete it when no longer needed.</span> * <span style="font-size:small">**Fix.** The function now works as expected with Powershell's Strict Mode.</span> * <span style="font-size:small">**VHDX** is the new default _(Sorry Azure!)._ Use **-VhdFormat** to explicitly specify “VHD”.</span> * <span style="font-size:small">**GPT** is the new default _(Sorry Generation 1 virtual machines!)._ Use **-VhdPartitionStyle** to explicitly specify “MBR”.</span> * <span style="font-size:small">UI is **deprecated. **This was a tough decition but I don't have enough skills and time to maintain it and support with the new features I added over time. Probably the old **-ShowUi** option still works. But I cannot commit it to work with any of the new features or at all. Sorry about this folks. If anyone has suggestions and ready to help, please reach out to me and I will be happy to include your contributions.</span> ### Version 6.3 QFE 7 (February 17, 2014) * <span style="font-size:small">**Fix.** QFE5 has introduced a bug in GTP handling.</span> ### Version 6.3 QFE 6 (February 16, 2014) * <span style="font-size:small">**New.** Option to enable Windows Features for the OS inside the VHD(x). Use the **-Feature** parameter. <span style="color:#ff0000">Note</span> that you need to specify the _internal_ names as understood by DISM and DISM CmdLets (e.g. _NetFx3),_ instead of the "friendly" names from Server Manager CmdLets (e.g. _NET-Framework-Core)._ There's no need to specify the source since we already have full sources inside the ISO.</span> ### Version 6.3 QFE 5 * <span style="font-size:small">**Fix.** VM Provisioning with VMM using the Differencing Disk feature was failing. A particular case of this scenario is provisioning a VM Role Gallery Item with Windows Azure Pack. (Note that so-called Standalone VMs were not affected since they're not using Differencing disks).</span> ### Version 6.3 for Windows 8.1 and Windows Server 2012 R2 * <span style="font-size:small">**Fix** Now works correctly on UEFI-based systems (like your modern laptop or new server, as well as inside Generation 2 VMs).</span> * <span style="font-size:small">**New** Support for GPT partitioning inside VHD(x)es. This is particularly handful for the following two scenarios. Use the new **-VHDPartitionStyle** parameter. By default we still create MBR-partitioned VHD(x)es for backward compatibility. (I.e. your older commands will produce the same effect as before).</span> * <span style="font-size:small">Native VHD(x) Boot on UEFI-based system.</span> * <span style="font-size:small">**<span style="color:#ff0000">Generation 2 Virtual Machines</span> **in Hyper-V with Windows Server 2012 R2 (more details at [http://blogs.technet.com/b/jhoward/archive/2013/10/24/hyper-v-generation-2-virtual-machines-part-1.aspx](http://blogs.technet.com/b/jhoward/archive/2013/10/24/hyper-v-generation-2-virtual-machines-part-1.aspx)).</span> * <span style="font-size:small">**New** Specific features to better support Native VHD(x) Boot scenarios.</span> * <span style="font-size:small">An option to skip BCD store creation inside the VHD(x). That’s because with Native Boot, the BCD store and the boot loader itself should be stored off the VHD(x), on the physical disk. Thus no need to pollute the root of your C:\ drive. Use the new **-BCDinVHD** parameter.</span> * <span style="font-size:small">A switch to disable automatic expansion of VHD(x) in case of Native Boot. For usage guidance, see **-ExpandOnNativeBoot** in the help section.</span> * <span style="font-size:small">An option to inject drivers into the OS inside the VHD(x). Good for OEM mass storage drivers which are required for native boot on common server-class hardware. Use the new **-Driver** parameter.</span> * <span style="font-size:small">**New** A switch to enable Remote Desktop for the OS inside the VHD(x). Use the new **-RemoteDesktopEnable** switch.</span> * <span style="font-size:small">Note that you still need to enable relevant Firewall rules (using Group Policy or manually). That might be a subject for further improvements.</span> * <span style="font-size:small">**Improvement** Added link to online help (this page). Use the **-Online** switch for Get-Help.</span> * <span style="font-size:small">**Obvious** Support for Windows 8.1 and Windows Server 2012 R2.</span> ### Version 6.2 for Windows 8 and Windows Server 2012 * <span style="font-size:small">First, we should stop calling it "WIM2VHD".  The WIM2VHD name has been discontinued with this version of the script.  Because it's been completely rewritten in PowerShell, I opted to give it a more PowerShell-esque name, that name being **"Convert-WindowsImage"**.  "WIM2VHD8" has been the working codename for the project during development.</span> * <span style="font-size:small">As mentioned earlier, Convert-WindowsImage has been **completely rewritten in PowerShell**.</span> * <span style="font-size:small">Support for the new **VHDX** file format has been added!</span> * <span style="font-size:small">Support for creating VHD and VHDX images from **.ISO** files has been added!</span> * <span style="font-size:small">A new (and completely optional) **graphical user interface** has been added, making the creation of VHD and VHDX images as simple as a few mouse clicks!</span> * <span style="font-size:small">**Closer integration with the storage stack**, so there's no more need to automate DISKPART.EXE and hope that it works!</span> * <span style="font-size:small">**Fewer binary dependencies!**</span> * <span style="font-size:small">WIM2VHD required the use of up to **8 external binaries**, some of which were only available as part of the Windows AIK/OPK, **requiring a 1.7GB download** just to get a few EXE files.</span> * <span style="font-size:small">Convert-WindowsImage requires the use of only **3 external binaries**, all of which are **included in-box with Windows 8**.</span> ## System Requirements * <span style="font-size:small">**What OSes can I run Convert-WindowsImage on? **</span><span style="font-size:small">Convert-WindowsImage supports pre-release versions of Windows 8 and higher. Windows 8.1 and Windows Server 2012 R2 is the recommended and most tested platform. Convert-WindowsImage cannot be run on Windows 7 or Windows Server 2008 R2_._</span> * <span style="font-size:small">**What OSes can Convert-WindowsImage make VHDs and VHDXs of? **Convert-WindowsImage only supports creating VHD and VHDX images from Windows 7/R2 and higher. Windows Vista/Windows Server 2008 and previous versions of Windows are not supported.</span> * <span style="font-size:small">**Which OSes can I use VHDX files with? **The new VHDX file format can only be used with Windows 8/Server 2012 and above, and the version of Hyper-V that ships with those platforms. You can create a VHDX which has Windows 7 or Windows Server 2008 R2 installed in it, but they will only run on Windows 8/Server 2012 Hyper-V and above.</span> ## FAQ ### Are there any changes from the way WIM2VHD worked?

<div><span style="font-size:small">Yes.  Here's a list of WIM2VHD features that have not been implemented in Convert-WindowsImage.ps1. </span></div>

* <span style="font-size:small">/QFE*  _Provided support for hotfix installation into the VHD during creation. _</span> * <span style="font-size:small">/REF  _Provided support for multi-part WIM files. _</span> * <span style="font-size:small">/MergeFolder*  _Merged a specified folder structure into the root of the VHD. _</span> * <span style="font-size:small">/SignDisk  _Created a file with the creation date, time, and Convert-WindowsImage version used to create the VHD in the root of the VHD file system.  This is now the default behavior, so the switch has been removed. _</span> * <span style="font-size:small">/Trace _Displayed verbose output.  This is now handled by the -Verbose switch. _</span> * <span style="font-size:small">FastFixed is no longer a valid value for the -DiskType parameter.</span> * <span style="font-size:small">/CopyLocal _Copied all necessary EXEs to a single directory.  No longer needed in Convert-WindowsImage. _</span> * <span style="font-size:small">/Metadata</span> * <span style="font-size:small">/HyperV</span> * <span style="font-size:small">/ClassicMount _Specified that WIM2VHD should use drive letters instead of the NTFS mount points.  This is now the default behavior, so the switch has been removed._</span>

<div>_<span style="font-size:small">* These features may be implemented in a later release.</span>_</div>

### Are there any known issues?

<div><span style="font-size:small">In the initial release of Convert-WindowsImage.ps1, there was a bug which prevented the creation of Hyper-V Server VHD and VHDX files.  This bug has since been fixed in the .1 revision which was released on 6/12/2012.  If you are not affected by this issue, there is no need for you to upgrade to the current release. <span style="font-size:small">There are currently no known issues with this build of Convert-WindowsImage.ps1.</span></span></div>

### How do I use this thing? <span>Use the function (New in version 10). Also highlights some of the new features.</span>

<div class="scriptcode">

<div class="pluginEditHolder" plugincommand="mceScriptCode">

<div class="title"><span>PowerShell</span></div>

<div class="pluginLinkHolder"><span class="pluginEditHolderLink">Edit</span>|<span class="pluginRemoveHolderLink">Remove</span></div>

<span class="hidden">powershell</span>

<pre class="hidden"># Load (aka "dot-source) the Function
. .\Convert-WindowsImage.ps1
# Prepare all the variables in advance (optional)
$ConvertWindowsImageParam = @{ 
    SourcePath          = "9600.17053.WINBLUE_REFRESH.141120-0031_X64FRE_SERVER_EN-US_VL-IR5_SSS_X64FREV_EN-US_DV9.ISO" 
    RemoteDesktopEnable = $True 
    Passthru            = $True 
    Edition    = @( 
        "ServerDataCenter" 
        "ServerDataCenterCore" 
    ) 
    Package = @( 
        "C:\Users\artemp\Downloads\November\Windows8.1-KB3012997-x64-en-us-server.cab" 
        "C:\Users\artemp\Downloads\VMguest\windows6.2-hypervintegrationservices-x64.cab" 
    ) 
} 
# Produce the images
$VHDx = Convert-WindowsImage @ConvertWindowsImageParam</pre>

<div class="preview">

<pre class="powershell"><span class="powerShell__com"># Load (aka "dot-source) the Function</span> 

. .\Convert<span class="powerShell__operator">-</span>WindowsImage.ps1 

<span class="powerShell__com"># Prepare all the variables in advance (optional)</span> 

<span class="powerShell__variable">$ConvertWindowsImageParam</span> = @{  

    SourcePath          = <span class="powerShell__string">"9600.17053.WINBLUE_REFRESH.141120-0031_X64FRE_SERVER_EN-US_VL-IR5_SSS_X64FREV_EN-US_DV9.ISO"</span>  
    RemoteDesktopEnable = <span class="powerShell__variable">$True</span>  
    Passthru            = <span class="powerShell__variable">$True</span>  

    Edition    = @(  

        <span class="powerShell__string">"ServerDataCenter"</span>  
        <span class="powerShell__string">"ServerDataCenterCore"</span>  
    )  

    Package = @(  

        <span class="powerShell__string">"C:\Users\artemp\Downloads\November\Windows8.1-KB3012997-x64-en-us-server.cab"</span>  
        <span class="powerShell__string">"C:\Users\artemp\Downloads\VMguest\windows6.2-hypervintegrationservices-x64.cab"</span>  

    )  
}  

<span class="powerShell__com"># Produce the images</span> 

<span class="powerShell__variable">$VHDx</span> = Convert<span class="powerShell__operator">-</span>WindowsImage @ConvertWindowsImageParam</pre>

</div>

</div>

</div>

<div class="endscriptcode">Create a VHDX using GPT partition layout (for UEFI boot and Hyper-V Generation 2 VMs).</div>

<div class="scriptcode">

<div class="pluginEditHolder" plugincommand="mceScriptCode">

<div class="title"><span>PowerShell</span></div>

<div class="pluginLinkHolder"><span class="pluginEditHolderLink">Edit</span>|<span class="pluginRemoveHolderLink">Remove</span></div>

<span class="hidden">powershell</span>

<pre class="hidden">.\Convert-WindowsImage.ps1 -SourcePath "9477.0.FBL_PARTNER_OUT31.130803-0736_X64FRE_SERVER_EN-US-IRM_SSS_X64FRE_EN-US_DV5.ISO" -VHDFormat VHDX -Edition ServerDataCenterCore -VHDPartitionStyle GPT -Verbose</pre>

<div class="preview">

<pre class="windowsshell">.\<span class="windowsshell__command">Convert</span><span class="windowsshell__commandext">-WindowsImage</span>.ps1 <span class="windowsshell__commandext">-SourcePath</span> <span class="windowsshell__string">"9477.0.FBL_PARTNER_OUT31.130803-0736_X64FRE_SERVER_EN-US-IRM_SSS_X64FRE_EN-US_DV5.ISO"</span> <span class="windowsshell__commandext">-VHDFormat</span> VHDX <span class="windowsshell__commandext">-Edition</span> ServerDataCenterCore <span class="windowsshell__commandext">-VHDPartitionStyle</span> GPT <span class="windowsshell__commandext">-Verbose</span></pre>

</div>

</div>

</div>

<div class="endscriptcode">Create a VHDX using MBR (old school) partition layout (which is still the default). Prepare the VHDX for Native Boot on BIOS-based computer: skip BCD creation, disable VHDX expansion on Native Boot, enable Remote Desktop and add a custom driver.</div>

<div class="endscriptcode">

<div class="scriptcode">

<div class="pluginEditHolder" plugincommand="mceScriptCode">

<div class="title"><span>PowerShell</span></div>

<div class="pluginLinkHolder"><span class="pluginEditHolderLink">Edit</span>|<span class="pluginRemoveHolderLink">Remove</span></div>

<span class="hidden">powershell</span>

<pre class="hidden">.\Convert-WindowsImage.ps1 -SourcePath "9600.16384.WINBLUE_RTM.130821-1623_X64FRE_SERVER_EN-US-IRM_SSS_X64FRE_EN-US_DV5.ISO" -VHDFormat VHDX -Edition "ServerDataCenterCore" -SizeBytes 8GB -VHDPartitionStyle MBR -BCDinVHD NativeBoot -ExpandOnNativeBoot:$false -RemoteDesktopEnable -Driver "F:\Custom Driver" -Verbose</pre>

<div class="preview">

<pre class="windowsshell">.\<span class="windowsshell__command">Convert</span><span class="windowsshell__commandext">-WindowsImage</span>.ps1 <span class="windowsshell__commandext">-SourcePath</span> <span class="windowsshell__string">"9600.16384.WINBLUE_RTM.130821-1623_X64FRE_SERVER_EN-US-IRM_SSS_X64FRE_EN-US_DV5.ISO"</span> <span class="windowsshell__commandext">-VHDFormat</span> VHDX <span class="windowsshell__commandext">-Edition</span> <span class="windowsshell__string">"ServerDataCenterCore"</span> <span class="windowsshell__commandext">-SizeBytes</span> 8GB <span class="windowsshell__commandext">-VHDPartitionStyle</span> MBR <span class="windowsshell__commandext">-BCDinVHD</span> NativeBoot <span class="windowsshell__commandext">-ExpandOnNativeBoot</span><span class="windowsshell__commandext">:</span><span class="windowsshell__number">$false</span> <span class="windowsshell__commandext">-RemoteDesktopEnable</span> <span class="windowsshell__commandext">-Driver</span> <span class="windowsshell__string">"F:\Custom Driver"</span> <span class="windowsshell__commandext">-Verbose</span></pre>

</div>

</div>

</div>

<div class="endscriptcode">Show the graphical user interface. Note that this feature does not support all of the options that present in command-line interface:</div>

</div>

<div class="scriptcode">

<div class="pluginEditHolder" plugincommand="mceScriptCode">

<div class="title"><span>PowerShell</span></div>

<div class="pluginLinkHolder"><span class="pluginEditHolderLink">Edit</span>|<span class="pluginRemoveHolderLink">Remove</span></div>

<span class="hidden">powershell</span>

<pre class="hidden">.\Convert-WindowsImage.ps1 -ShowUI</pre>

<div class="preview">

<pre class="powershell">.\Convert<span class="powerShell__operator">-</span>WindowsImage.ps1 <span class="powerShell__operator">-</span>ShowUI</pre>

</div>

</div>

</div>

<div class="endscriptcode">Create a VHD using all default settings from D:\sources\install.wim.</div>

<div class="endscriptcode">

<div class="scriptcode">

<div class="pluginEditHolder" plugincommand="mceScriptCode">

<div class="title"><span>PowerShell</span></div>

<div class="pluginLinkHolder"><span class="pluginEditHolderLink">Edit</span>|<span class="pluginRemoveHolderLink">Remove</span></div>

<span class="hidden">powershell</span>

<pre class="hidden">.\Convert-WindowsImage.ps1 -SourcePath D:\sources\install.wim
# Since no edition is being specified, the command will succeed if there is only one image in the specified WIM file.  If there are multiple images, the command will fail and it will list the possible editions.</pre>

<div class="preview">

<pre class="powershell">.\Convert<span class="powerShell__operator">-</span>WindowsImage.ps1 <span class="powerShell__operator">-</span>SourcePath D:\sources\install.wim 

<span class="powerShell__com"># Since no edition is being specified, the command will succeed if there is only one image in the specified WIM file.  If there are multiple images, the command will fail and it will list the possible editions.</span></pre>

</div>

</div>

</div>

<div class="endscriptcode">Create a VHD using all default settings from D:\sources\install.wim while specifying an edition.</div>

<div class="endscriptcode">

<div class="scriptcode">

<div class="pluginEditHolder" plugincommand="mceScriptCode">

<div class="title"><span>PowerShell</span></div>

<div class="pluginLinkHolder"><span class="pluginEditHolderLink">Edit</span>|<span class="pluginRemoveHolderLink">Remove</span></div>

<span class="hidden">powershell</span>

<pre class="hidden">.\Convert-WindowsImage.ps1 -SourcePath D:\sources\install.wim -Edition Professional</pre>

<div class="preview">

<pre class="powershell">.\Convert<span class="powerShell__operator">-</span>WindowsImage.ps1 <span class="powerShell__operator">-</span>SourcePath D:\sources\install.wim <span class="powerShell__operator">-</span>Edition Professional</pre>

</div>

</div>

</div>

<div class="endscriptcode">Create a 60GB VHDX, using all default settings, from D:\Windows8RPx64.iso.</div>

<div class="endscriptcode">

<div class="scriptcode">

<div class="pluginEditHolder" plugincommand="mceScriptCode">

<div class="title"><span>PowerShell</span></div>

<div class="pluginLinkHolder"><span class="pluginEditHolderLink">Edit</span>|<span class="pluginRemoveHolderLink">Remove</span></div>

<span class="hidden">powershell</span>

<pre class="hidden">.\Convert-WindowsImage.ps1 -SourcePath D:\Windows8RPx64.iso -VHDFormat VHDX -SizeBytes 60GB</pre>

<div class="preview">

<pre class="powershell">.\Convert<span class="powerShell__operator">-</span>WindowsImage.ps1 <span class="powerShell__operator">-</span>SourcePath D:\Windows8RPx64.iso <span class="powerShell__operator">-</span>VHDFormat VHDX <span class="powerShell__operator">-</span>SizeBytes 60GB</pre>

</div>

</div>

</div>

<div class="endscriptcode">Create a 48TB VHDX from D:\WindowsRPx64.iso with a custom file name.</div>

<div class="endscriptcode">

<div class="scriptcode">

<div class="pluginEditHolder" plugincommand="mceScriptCode">

<div class="title"><span>PowerShell</span></div>

<div class="pluginLinkHolder"><span class="pluginEditHolderLink">Edit</span>|<span class="pluginRemoveHolderLink">Remove</span></div>

<span class="hidden">powershell</span>

<pre class="hidden">.\Convert-WindowsImage.ps1 -SourcePath D:\Windows8RPx64.iso -VHDFormat VHDX -SizeBytes 48TB -VHDPath .\MyCustomName.vhdx</pre>

<div class="preview">

<pre class="powershell">.\Convert<span class="powerShell__operator">-</span>WindowsImage.ps1 <span class="powerShell__operator">-</span>SourcePath D:\Windows8RPx64.iso <span class="powerShell__operator">-</span>VHDFormat VHDX <span class="powerShell__operator">-</span>SizeBytes 48TB <span class="powerShell__operator">-</span>VHDPath .\MyCustomName.vhdx</pre>

</div>

</div>

</div>

<div class="endscriptcode">Use WIM2VHD-style argument names to create a 20GB fixed VHDX with a custom name and an unattend file from D:\foo.wim, and return the path to the created VHDX on the pipeline.</div>

<div class="endscriptcode">

<div class="scriptcode">

<div class="pluginEditHolder" plugincommand="mceScriptCode">

<div class="title"><span>PowerShell</span></div>

<div class="pluginLinkHolder"><span class="pluginEditHolderLink">Edit</span>|<span class="pluginRemoveHolderLink">Remove</span></div>

<span class="hidden">powershell</span>

<pre class="hidden">.\Convert-WindowsImage.ps1 -WIM D:\foo.wim -Size 20GB -DiskType Fixed -VHDFormat VHDX -Unattend D:\myUnattend.xml -VHD D:\scratch\foo.vhdx -passthru</pre>

<div class="preview">

<pre class="powershell">.\Convert<span class="powerShell__operator">-</span>WindowsImage.ps1 <span class="powerShell__operator">-</span>WIM D:\foo.wim <span class="powerShell__operator">-</span>Size 20GB <span class="powerShell__operator">-</span>DiskType Fixed <span class="powerShell__operator">-</span>VHDFormat VHDX <span class="powerShell__operator">-</span>Unattend D:\myUnattend.xml <span class="powerShell__operator">-</span>VHD D:\scratch\foo.vhdx <span class="powerShell__operator">-</span>passthru</pre>

</div>

</div>

</div>

<div class="endscriptcode">Enable serial debugging in the VHD, using COM2 at 19200bps.</div>

<div class="endscriptcode">

<div class="scriptcode">

<div class="pluginEditHolder" plugincommand="mceScriptCode">

<div class="title"><span>PowerShell</span></div>

<div class="pluginLinkHolder"><span class="pluginEditHolderLink">Edit</span>|<span class="pluginRemoveHolderLink">Remove</span></div>

<span class="hidden">powershell</span>

<pre class="hidden">"D:\foo.wim" | .\Convert-WindowsImage.ps1 -Edition Professional -EnableDebugger Serial -ComPort 2 -BaudRate 19200</pre>

<div class="preview">

<pre class="powershell"><span class="powerShell__string">"D:\foo.wim"</span> <span class="powerShell__operator">|</span> .\Convert<span class="powerShell__operator">-</span>WindowsImage.ps1 <span class="powerShell__operator">-</span>Edition Professional <span class="powerShell__operator">-</span>EnableDebugger Serial <span class="powerShell__operator">-</span>ComPort 2 <span class="powerShell__operator">-</span>BaudRate 19200</pre>

</div>

</div>

</div>

</div>

</div>

</div>

</div>

</div>

</div>

</div>