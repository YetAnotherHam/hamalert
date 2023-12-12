Save all provided files to a folder, e.g. “c:\temp\hamalert”.
Export an ADIF file to this location.
Make sure, the export contains the DXCC information for each QSO.

Login at hamalert.org and open the developer tools from your browser (F12).
Locate the PHP Session cookie for hamalert.org and copy the value into your clipboard.
Open the powershell script with an editor and fill in all needed information, as described in the script.
Run the script once to test, all is working fine without errors.
If that is the case, remove the comment at the end of the script to allow the script, creating the triggers.
