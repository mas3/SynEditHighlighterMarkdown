﻿{-------------------------------------------------------------------------------
The contents of this file are subject to the Mozilla Public License
Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at
https://www.mozilla.org/MPL/

Software distributed under the License is distributed on an "AS IS"
basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations
under the License.

The Original Code is SynHighlighterMarkdownReg.pas, released 2025-04-26.

The Initial Developer of the Original Code is MASUDA Takshi.
Portions created by the Initial Developer are Copyright (C) 2025
the Initial Developer. All Rights Reserved.

Contributor(s):

Alternatively, the contents of this file may be used under the terms of
the GNU General Public License Version 2 or later (the  "GPL"),
in which case the provisions of GPL are applicable instead of those
above.  If you wish to allow use of your version of this file only
under the terms of the GPL and not to allow others to use your version of
this file under the MPL, indicate your decision by deleting the provisions
above and replace  them with the notice and other provisions required
by the GPL. If you do not delete the provisions above, a recipient may use
your version of this file under either the MPL or the GPL.
-------------------------------------------------------------------------------}
unit SynHighlighterMarkdownReg;

interface

uses
  System.Classes, SynHighlighterMarkdown;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('SynEdit Highlighters', [TSynMarkdownSyn]);
end;

end.
