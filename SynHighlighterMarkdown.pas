{ -------------------------------------------------------------------------------
  The contents of this file are subject to the Mozilla Public License
  Version 1.1 (the "License"); you may not use this file except in
  compliance with the License. You may obtain a copy of the License at
  https://www.mozilla.org/MPL/

  Software distributed under the License is distributed on an "AS IS"
  basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
  License for the specific language governing rights and limitations
  under the License.

  The Original Code is SynHighlighterMarkdown.pas, released 2025-04-26.

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
  ------------------------------------------------------------------------------- }

unit SynHighlighterMarkdown;

interface

uses
  System.Classes, System.StrUtils, Vcl.Graphics, System.RegularExpressions,
  SynEditHighlighter;

type
  TtkTokenKind = (tkUnknown, tkBlockQuote, tkCode, tkDelete, tkEmphasis,
    tkHeader, tkLink, tkList, tkSpace);

  TRangeState = (rsUnKnown, rsBacktickFencedCodeBlock, rsTildeFencedCodeBlock);

  TRangeInfo = packed record
    case Boolean of
      False:
        (p: Pointer);
      True:
        (State: Word; Length: Word);
  end;

  TSynMarkdownSyn = class(TSynCustomHighlighter)
  private
    FBlockQuoteAttri: TSynHighlighterAttributes;
    FCodeAttri: TSynHighlighterAttributes;
    FDeleteAttri: TSynHighlighterAttributes;
    FEmphasisAttri: TSynHighlighterAttributes;
    FHeadingAttri: TSynHighlighterAttributes;
    FLinkAttri: TSynHighlighterAttributes;
    FListAttri: TSynHighlighterAttributes;
    FSpaceAttri: TSynHighlighterAttributes;
    FTextAttri: TSynHighlighterAttributes;

    FRange: TRangeInfo;
    FTokenID: TtkTokenKind;

    function AtxHeadingProc: Boolean;
    function BlockQuoteProc: Boolean;
    function CodeSpanProc: Boolean;
    function DeleteProc: Boolean;
    function EmphasisProc: Boolean;
    function FencedCodeBlockBeginProc: Boolean;
    function FencedCodeBlockEndProc: Boolean;
    function IndentedCodeBlockProc: Boolean;
    function ListProc: Boolean;
    function PageLinkProc: Boolean;
    function SetextHeadingProc: Boolean;
    function UrlLinkProc: Boolean;

    function GetFencedCodeBlockType(const Ch: Char): TRangeState;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    function GetDefaultAttribute(Index: Integer)
      : TSynHighlighterAttributes; override;
    class function GetFriendlyLanguageName: String; override;
    function GetEol: Boolean; override;
    class function GetLanguageName: String; override;
    function GetRange: Pointer; override;
    function GetTokenAttribute: TSynHighlighterAttributes; override;
    function GetTokenKind: Integer; override;
    procedure Next; override;
    procedure ResetRange; override;
    procedure SetRange(Value: Pointer); override;
  published
    property BlockQuoteAttri: TSynHighlighterAttributes read FBlockQuoteAttri
      write FBlockQuoteAttri;
    property CodeAttri: TSynHighlighterAttributes read FCodeAttri
      write FCodeAttri;
    property DeleteAttri: TSynHighlighterAttributes read FDeleteAttri
      write FDeleteAttri;
    property EmphasisAttri: TSynHighlighterAttributes read FEmphasisAttri
      write FEmphasisAttri;
    property HeadingAttri: TSynHighlighterAttributes read FHeadingAttri
      write FHeadingAttri;
    property LinkAttri: TSynHighlighterAttributes read FLinkAttri
      write FLinkAttri;
    property ListAttri: TSynHighlighterAttributes read FListAttri
      write FListAttri;
    property SpaceAttri: TSynHighlighterAttributes read FSpaceAttri
      write FSpaceAttri;
  end;

implementation

var
  RegexAtxHeading: TRegEx;
  RegexBlockQuote: TRegEx;
  RegexCodeSpan: TRegEx;
  RegexDelete: TRegEx;
  RegexEmpasis1: TRegEx;
  RegexEmpasis2: TRegEx;
  RegexFencedCodeBlockBegin: TRegEx;
  RegexFencedCodeBlockEnd: TRegEx;
  RegexIndentedCodeBlock: TRegEx;
  RegexList: TRegEx;
  RegexUrlLink: TRegEx;
  RegexPageLink: TRegEx;
  RegexSetextHeading: TRegEx;

{ TSynMarkdownSyn }

function TSynMarkdownSyn.AtxHeadingProc: Boolean;
var
  Ret: TMatch;
begin
  if Run > 0 then
    Exit(False);

  Ret := RegexAtxHeading.Match(FLine);
  if Ret.Success then
  begin
    FTokenID := tkHeader;
    Run := Run + Ret.Length;
    Exit(True);
  end;
  Result := False;
end;

function TSynMarkdownSyn.BlockQuoteProc: Boolean;
var
  Ret: TMatch;
begin
  if Run > 0 then
    Exit(False);

  Ret := RegexBlockQuote.Match(FLine);
  if Ret.Success then
  begin
    FTokenID := tkBlockQuote;
    Run := Run + Ret.Length;
    Exit(True);
  end;
  Result := False;
end;

function TSynMarkdownSyn.CodeSpanProc: Boolean;
var
  Ret: TMatch;
begin
  Ret := RegexCodeSpan.Match(FLine, Run + 1);
  if Ret.Success and (Run = (Ret.Index - 1)) then
  begin
    FTokenID := tkCode;
    Run := Run + Ret.Length;
    Exit(True);
  end;
  Result := False;
end;

constructor TSynMarkdownSyn.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  FBlockQuoteAttri := TSynHighlighterAttributes.Create('BlockQuote',
    'Block Quote');
  FBlockQuoteAttri.Foreground := clWebDimGray;
  AddAttribute(FBlockQuoteAttri);

  FCodeAttri := TSynHighlighterAttributes.Create('Code', 'Code');
  FCodeAttri.Foreground := clWebFirebrick;
  AddAttribute(FCodeAttri);

  FDeleteAttri := TSynHighlighterAttributes.Create('Delete', 'Delete');
  FDeleteAttri.Foreground := clWebDimGray;
  AddAttribute(FDeleteAttri);

  FEmphasisAttri := TSynHighlighterAttributes.Create('Emphasis', 'Emphasis');
  FEmphasisAttri.Foreground := clWebDeepPink;
  AddAttribute(FEmphasisAttri);

  FHeadingAttri := TSynHighlighterAttributes.Create('Heading', 'Heading');
  FHeadingAttri.Foreground := clWebMediumBlue;
  AddAttribute(FHeadingAttri);

  FLinkAttri := TSynHighlighterAttributes.Create('Link', 'Link');
  FLinkAttri.Foreground := clBlue;
  AddAttribute(FLinkAttri);

  FListAttri := TSynHighlighterAttributes.Create('List', 'List');
  FListAttri.Foreground := clWebDeepPink;
  AddAttribute(FListAttri);

  FSpaceAttri := TSynHighlighterAttributes.Create('Space', 'Space');
  FSpaceAttri.Foreground := clWebCornFlowerBlue;
  AddAttribute(FSpaceAttri);

  FTextAttri := TSynHighlighterAttributes.Create('Text', 'Text');
  AddAttribute(FTextAttri);

  FBrackets := '<>()[]{}';
end;

function TSynMarkdownSyn.DeleteProc: Boolean;
var
  Ret: TMatch;
begin
  Ret := RegexDelete.Match(FLine, Run + 1);
  if Ret.Success and (Run = (Ret.Index - 1)) then
  begin
    FTokenID := tkDelete;
    Run := Run + Ret.Length;
    Exit(True);
  end;
  Result := False;
end;

destructor TSynMarkdownSyn.Destroy;
begin

  inherited;
end;

function TSynMarkdownSyn.EmphasisProc: Boolean;
var
  Ret: TMatch;
begin
  Ret := RegexEmpasis1.Match(FLine, Run + 1);
  if Ret.Success and (Run = (Ret.Index - 1)) then
  begin
    FTokenID := tkEmphasis;
    Run := Run + Ret.Length;
    Exit(True);
  end;

  Ret := RegexEmpasis2.Match(FLine, Run + 1);
  if Ret.Success and (Run = (Ret.Index - 1)) then
  begin
    FTokenID := tkEmphasis;
    Run := Run + Ret.Length;
    Exit(True);
  end;
  Result := False;
end;

function TSynMarkdownSyn.FencedCodeBlockBeginProc: Boolean;
var
  Ret: TMatch;
begin
  if Run > 0 then
    Exit(False);

  Ret := RegexFencedCodeBlockBegin.Match(FLine);
  if Ret.Success then
  begin
    var
      Fence: String := Ret.Groups[1].Value;
    FRange.State := Ord(GetFencedCodeBlockType(Fence[1]));
    FRange.Length := Length(Fence);
    FTokenID := tkCode;
    Run := Run + Ret.Length;
    Exit(True);
  end;
  Result := False;
end;

function TSynMarkdownSyn.FencedCodeBlockEndProc: Boolean;
var
  Ret: TMatch;
begin
  if Run > 0 then
    Exit(False);

  Ret := RegexFencedCodeBlockEnd.Match(FLine);
  if Ret.Success then
  begin
    var
      Fence: String := Ret.Groups[1].Value;
    if (TRangeState(FRange.State) = GetFencedCodeBlockType(Fence[1])) and
      (FRange.Length <= Length(Fence)) then
    begin
      ResetRange;
      Run := Run + Ret.Length;
      Exit(True);
    end;
  end;
  Result := False;
end;

function TSynMarkdownSyn.GetDefaultAttribute(Index: Integer)
  : TSynHighlighterAttributes;
begin
  case Index of
    SYN_ATTR_WHITESPACE:
      Result := FSpaceAttri;
  else
    Result := nil;
  end;
end;

function TSynMarkdownSyn.GetEol: Boolean;
begin
  Result := Run = FLineLen + 1;
end;

function TSynMarkdownSyn.GetFencedCodeBlockType(const Ch: Char): TRangeState;
begin
  if Ch = '`' then
    Result := rsBacktickFencedCodeBlock
  else
    Result := rsTildeFencedCodeBlock;
end;

class function TSynMarkdownSyn.GetFriendlyLanguageName: String;
begin
  Result := 'Markdown';
end;

class function TSynMarkdownSyn.GetLanguageName: String;
begin
  Result := 'Markdown';
end;

function TSynMarkdownSyn.GetRange: Pointer;
begin
  Result := FRange.p;
end;

function TSynMarkdownSyn.GetTokenAttribute: TSynHighlighterAttributes;
begin
  case FTokenID of
    tkUnknown:
      Result := FTextAttri;
    tkBlockQuote:
      Result := FBlockQuoteAttri;
    tkCode:
      Result := FCodeAttri;
    tkDelete:
      Result := FDeleteAttri;
    tkEmphasis:
      Result := FEmphasisAttri;
    tkHeader:
      Result := FHeadingAttri;
    tkLink:
      Result := FLinkAttri;
    tkList:
      Result := FListAttri;
    tkSpace:
      Result := FSpaceAttri
  else
    Result := nil;
  end;
end;

function TSynMarkdownSyn.GetTokenKind: Integer;
begin
  Result := Ord(FTokenID);
end;

function TSynMarkdownSyn.IndentedCodeBlockProc: Boolean;
var
  Ret: TMatch;
begin
  if Run > 0 then
    Exit(False);

  Ret := RegexIndentedCodeBlock.Match(FLine);
  if Ret.Success then
  begin
    FTokenID := tkCode;
    Run := Run + Ret.Length;
    Exit(True);
  end;
  Result := False;
end;

function TSynMarkdownSyn.ListProc: Boolean;
var
  Ret: TMatch;
begin
  if Run > 0 then
    Exit(False);

  Ret := RegexList.Match(FLine);
  if Ret.Success then
  begin
    FTokenID := tkList;
    Run := Run + Ret.Length;
    Exit(True);
  end;
  Result := False;
end;

procedure TSynMarkdownSyn.Next;
begin
  FTokenPos := Run;

  case TRangeState(FRange.State) of
    rsBacktickFencedCodeBlock, rsTildeFencedCodeBlock:
      begin
        FTokenID := tkCode;
        FencedCodeBlockEndProc;
        Run := FLineLen;
      end;
  else
    begin
      if not(AtxHeadingProc or BlockQuoteProc or ListProc or
        SetextHeadingProc or IndentedCodeBlockProc or
        FencedCodeBlockBeginProc or CodeSpanProc or DeleteProc or
        EmphasisProc or UrlLinkProc or PageLinkProc) then
      begin
        FTokenID := tkUnknown;
        Inc(Run);
      end;
    end;
  end;

  if FTokenPos = Run then
  begin
    FTokenID := tkUnknown;
    Inc(Run);
  end;

  inherited;
end;

function TSynMarkdownSyn.PageLinkProc: Boolean;
var
  Ret: TMatch;
begin
  Ret := RegexPageLink.Match(FLine, Run + 1);
  if Ret.Success and (Run = (Ret.Index - 1)) then
  begin
    FTokenID := tkLink;
    Run := Run + Ret.Length;
    Exit(True);
  end;
  Result := False;
end;

procedure TSynMarkdownSyn.ResetRange;
begin
  FRange.p := nil;
end;

function TSynMarkdownSyn.SetextHeadingProc: Boolean;
var
  Ret: TMatch;
begin
  if Run > 0 then
    Exit(False);

  Ret := RegexSetextHeading.Match(FLine);
  if Ret.Success then
  begin
    FTokenID := tkHeader;
    Run := Run + Ret.Length;
    Exit(True);
  end;
  Result := False;
end;

procedure TSynMarkdownSyn.SetRange(Value: Pointer);
begin
  FRange.p := Value;
end;

function TSynMarkdownSyn.UrlLinkProc: Boolean;
var
  Ret: TMatch;

  function CountChar(const Text: String; const Ch: Char): Integer;
  begin
    Result := 0;
    for var I := 1 to Length(Text) do
    begin
      if Text[I] = Ch then
        Inc(Result);
    end;
  end;

begin
  Ret := RegexUrlLink.Match(FLine, Run + 1);
  if Ret.Success and (Run = (Ret.Index - 1)) then
  begin
    var
      NewRun: Integer := Run + Ret.Length;

    if FLine[NewRun - 1] = ')' then
    begin
      var
        Open: Integer := CountChar(Ret.Value, '(');
      var
        Close: Integer := CountChar(Ret.Value, ')');
      while (Open < Close) and (FLine[NewRun - 1] = ')') do
      begin
        Dec(NewRun);
        Dec(Close);
      end;
    end;

    FTokenID := tkLink;
    Run := NewRun;
    Exit(True);
  end;
  Result := False;
end;

initialization

RegisterPlaceableHighlighter(TSynMarkdownSyn);

RegexAtxHeading := TRegEx.Create('^ {0,3}#{1,6} .+$', [roCompiled]);
RegexBlockQuote := TRegEx.Create('^ *>.+$', [roCompiled]);
RegexCodeSpan := TRegEx.Create('`[^`]+`', [roCompiled]);
RegexDelete := TRegEx.Create('(~{1,2})[^~]+\1', [roCompiled]);
RegexEmpasis1 := TRegEx.Create('(\*{1,3})[^*]+?\1', [roCompiled]);
RegexEmpasis2 := TRegEx.Create('(\b_{1,3})[^_].*?\1\b', [roCompiled]);
RegexFencedCodeBlockBegin := TRegEx.Create('^ {0,3}(([`~])\2{2,})(?: *)([^ ]*)(.*)$', [roCompiled]);
RegexFencedCodeBlockEnd := TRegEx.Create('^ {0,3}(([`~])\2{2,})$', [roCompiled]);
RegexIndentedCodeBlock := TRegEx.Create('^( {0,3}\t| {4,}).*', [roCompiled]);
RegexList := TRegEx.Create('^ *([-+*]|[0-9]{1,9}\.)(?= )', [roCompiled]);
RegexUrlLink := TRegEx.Create('https?://[\w!?/+\-_~=;.,*&@#$%()'']+', [roCompiled]);
RegexPageLink := TRegEx.Create('\[\[.+?\]\]', [roCompiled]);
RegexSetextHeading := TRegEx.Create('^ {0,3}([=-])\1* *$', [roCompiled]);

end.
