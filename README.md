# SynEdit highlighter for Markdown


## Overview

A Markdown highlighter component for SynEdit.


## Requirement

- Delphi 12.1
- [SynEdit](https://github.com/pyscripter/SynEdit)


## Usage

### Using Source

Add SynHighlighterMarkdown.pas to your project.

```pascal
uses
  SynHighlighterMarkdown;

...

var
  HL: TSynMarkdownSyn;

...

HL := TSynMarkdownSyn.Create(Self);
SynEdit1.Highlighter := HL;

```

### Componentization

1. Open SynEditHighlighterMarkdown.dproj
2. Install SynEditHighlighterMarkdown.bpl
3. Place the TSynMarkdownSyn component from the Tool Palette on the form
4. In the Object Inspector, assign the TSynMarkdownSyn component to the Highlighter
   property of the SynEdit


## Author

MASUDA Takashi <https://mas3lab.net/>
