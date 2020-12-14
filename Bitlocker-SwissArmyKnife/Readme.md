<div id="longDesc">

![](http://i1.gallery.technet.s-msft.com/bitlocker-powershell-swiss-a4777303/image/file/125011/1/swiss.army.knife.png)

This bitlocker function offers the the automation possibilities for the bitlocker encryption and TPM operations on Microsoft Windows (R) machines through PowerShell.

This function is a real powershell swiss army knife! A lot of the bitlocker or TPM tasks are covered, and more is frequently added !

## version 1.5 is Out!:

--> Add to possiblity to return the Key Volume Protector numerical password given a specefic ID.  
--> Updated Help.  
--> Minor code updates. 

## version 1.4.1:

Minor updates added.

## Version 1.4 is released:

New features added:

--> Encrypt drive

--> Decrypt a selected drive using Decrypt Drive

--> Identifiy the current  encryption Method using GetEncryptionMethod

--> Pause your current encryption using PauseEncryption

--> Pause your current Decryption using PauseDecryption

--> Delete current key protectors using DeleteKeyProtectors

## <span style="text-decoration:underline">**Main actions that the BitlockerSAK can deliver:**</span>

Generate a complete Bitlocker status of the machine in an object (Which can be resused logically integrated into powershell scripts). 

*   Identify if the TPM is activated.
*   Identify if the TPM is enabled.
*   Identify it the TPM is owned.
*   Identify if the TPM ownership is allowed.
*   how to check the Identify if the current bitlocker encryption state.
*   How to check the status of bitlocker encryption on a client.
*   Get the current bitlocker protection status.
*   Start the bitlocker drive encryption. (with Pin).
*   Resume a bitlocker encryption that is in paused state.
*   Return the current bitlocker encryption percentage of the drive.
*   Return the bitlocker key protector id's of the machine.
*   Possibility to return the current protector type(s).
*   Possibility to return the current encryption method that is used.

The actions are easily triggered through easy to use switches that you call after calling the function. (See example section below).

Help and examples can be easily found by using the integrated help system.

More information and detailed help can be found on the author's blog right here: [http://powershelldistrict.com/bitlocker-encryption-function/](http://powershelldistrict.com/bitlocker-encryption-function/)

## <span style="text-decoration:underline">**A few examples:**</span>

If no parameters are specified, then the the bitlockerSAK will return an object with the current encryption status of the machine.

<div class="scriptcode">

<div class="pluginEditHolder" plugincommand="mceScriptCode">

<div class="title"><span>PowerShell</span></div>

<div class="pluginLinkHolder"><span class="pluginEditHolderLink">Edit</span>|<span class="pluginRemoveHolderLink">Remove</span></div>

<span class="hidden">powershell</span>

<pre class="hidden">BitlockerSAK</pre>

<div class="preview">

<pre class="powershell">BitlockerSAK</pre>

</div>

</div>

</div>

![](http://i1.gallery.technet.s-msft.com/bitlocker-powershell-swiss-a4777303/image/file/125008/1/bitlockersak%20no%20parameters.png)

<span style="text-decoration:underline"></span>

Retrieve the current encryption status.

<div class="scriptcode">

<div class="pluginEditHolder" plugincommand="mceScriptCode">

<div class="title"><span>PowerShell</span></div>

<div class="pluginLinkHolder"><span class="pluginEditHolderLink">Edit</span>|<span class="pluginRemoveHolderLink">Remove</span></div>

<span class="hidden">powershell</span>

<pre class="hidden">BitlockerSAK -GetEncryptionstatus</pre>

<div class="preview">

<pre class="powershell">BitlockerSAK <span class="powerShell__operator">-</span>GetEncryptionstatus</pre>

</div>

</div>

</div>

Will return the current encryption state (Fully encrypted, encryption paused, fully unencrypted, Encryption currently in progress, decryption currently in progress)

<div class="scriptcode">

<div class="pluginEditHolder" plugincommand="mceScriptCode">

<div class="title"><span>PowerShell</span></div>

<div class="pluginLinkHolder"><span class="pluginEditHolderLink">Edit</span>|<span class="pluginRemoveHolderLink">Remove</span></div>

<span class="hidden">powershell</span>

<pre class="hidden">BitlockerSAK -IsOwnerShipAllowed</pre>

<div class="preview">

<pre class="powershell">BitlockerSAK <span class="powerShell__operator">-</span>IsOwnerShipAllowed</pre>

</div>

</div>

</div>

Returns if the ownership of the TPM is allowed.

It is also possible to automate bitlocker encryption tasks such as follow:

<div class="scriptcode">

<div class="pluginEditHolder" plugincommand="mceScriptCode">

<div class="title"><span>PowerShell</span></div>

<div class="pluginLinkHolder"><span class="pluginEditHolderLink">Edit</span>|<span class="pluginRemoveHolderLink">Remove</span></div>

<span class="hidden">powershell</span>

<pre class="hidden">$EncryptionState = (BitlockerSAK -Getencryptionstatus).encryptionstate 
if ($EncryptionState -eq "Fullydecrypted"){ 
BitlockerSAK -Encrypt 
}else{ 
write-host "Bitlocker is currently in $($EncryptionState) state." 
}</pre>

<div class="preview">

<pre class="powershell"><span class="powerShell__variable">$EncryptionState</span> = (BitlockerSAK <span class="powerShell__operator">-</span>Getencryptionstatus).encryptionstate  
<span class="powerShell__keyword">if</span> (<span class="powerShell__variable">$EncryptionState</span> <span class="powerShell__operator">-</span>eq <span class="powerShell__string">"Fullydecrypted"</span>){  
BitlockerSAK <span class="powerShell__operator">-</span>Encrypt  
}<span class="powerShell__keyword">else</span>{  
write<span class="powerShell__operator">-</span>host <span class="powerShell__string">"Bitlocker is currently in $($EncryptionState) state."</span>  
}</pre>

</div>

</div>

</div>

<div class="endscriptcode">Return the numerical password of a given volume key protector ID</div>

<div class="endscriptcode">

<div class="scriptcode">

<div class="pluginEditHolder" plugincommand="mceScriptCode">

<div class="title"><span>PowerShell</span></div>

<div class="pluginLinkHolder"><span class="pluginEditHolderLink">Edit</span>|<span class="pluginRemoveHolderLink">Remove</span></div>

<span class="hidden">powershell</span>

<pre class="hidden">bitlockersak -GetKeyProtectorNumericalPassword -VolumeKeyProtectorID "{AB1535D4-ECB3-49D6-8AB1-E334A4F60579}"</pre>

<div class="preview">

<pre class="powershell">bitlockersak <span class="powerShell__operator">-</span>GetKeyProtectorNumericalPassword <span class="powerShell__operator">-</span>VolumeKeyProtectorID <span class="powerShell__string">"{AB1535D4-ECB3-49D6-8AB1-E334A4F60579}"</span></pre>

</div>

</div>

</div>

<div class="endscriptcode"> Will return something similar to this.</div>

</div>

<div class="endscriptcode">![](https://i1.gallery.technet.s-msft.com/scriptcenter/bitlocker-powershell-swiss-a4777303/image/file/138826/1/getkeyprotectornumericalpassword.png)</div>

## <span style="text-decoration:underline">**Detailed help:**</span>

Detailed help can be found on my blog at [http://powershelldistrict.com/powershell-bitlocker-encryption-tool-sak/](http://powershelldistrict.com/powershell-bitlocker-encryption-tool-sak/ "BitlockerSAK Detailed help")

</div>