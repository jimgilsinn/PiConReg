# PiConReg - Mods to ConQR
This directory contains mods to the original ConQR code to make the PiConReg system work better.

* con_setup.py - An error in the script was fixed due to spaces vs. tabs for indenting
* qrcode_server.py - Modified the HTML output to add in meta descriptions that can be used to script a response in the PiConReg system instead of having to do more complex text processing.  Also tweaked the local server output to be more consistent with recent versions of HTML.
