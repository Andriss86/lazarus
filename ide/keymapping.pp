{
 ***************************************************************************
 *                                                                         *
 *   This source is free software; you can redistribute it and/or modify   *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 *   This code is distributed in the hope that it will be useful, but      *
 *   WITHOUT ANY WARRANTY; without even the implied warranty of            *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU     *
 *   General Public License for more details.                              *
 *                                                                         *
 *   A copy of the GNU General Public License is available on the World    *
 *   Wide Web at <http://www.gnu.org/copyleft/gpl.html>. You can also      *
 *   obtain it by writing to the Free Software Foundation,                 *
 *   Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.        *
 *                                                                         *
 ***************************************************************************

  Author: Mattias Gaertner

  Abstract:
    Contains classes to store key-command relationships, can update
    TSynEditKeyStrokes and provides a dialog for editing a single
    commandkey.
}
unit KeyMapping;

{$mode objfpc}{$H+}

interface

uses
  LCLIntf, LCLType,
  Forms, Classes, SysUtils, Buttons, LResources, StdCtrls, Controls,
  SynEdit, SynEditKeyCmds, Laz_XMLCfg, Dialogs, StringHashList,
  LazarusIDEStrConsts, IDECommands;

const
  { editor commands constants. see syneditkeycmds.pp for more
  
   These values can change from version to version, so DO NOT save them to file!
  
   To add one static key do the following:
     1. Add a constant with a unique value in the list below.
     2. Add it to GetDefaultKeyForCommand to define the default keys+shiftstates
     3. Add it to EditorCommandToDescriptionString to define the description
     4. Add it to TKeyCommandRelationList.CreateDefaultMapping to define the
        category.
        
   IDE experts: They are handled in the IDE interface units.
             
  }
  ecNone                 = 0;
  
  // search
  ecFind                 = ecUserFirst + 1;
  ecFindAgain            = ecUserFirst + 2;
  ecFindNext             = ecFindAgain;
  ecReplace              = ecUserFirst + 3;
  ecIncrementalFind      = ecUserFirst + 4;
  ecFindProcedureDefinition = ecUserFirst + 5;
  ecFindProcedureMethod  = ecUserFirst + 6;
  ecGotoLineNumber       = ecUserFirst + 7;
  ecFindPrevious         = ecUserFirst + 8;
  ecFindInFiles          = ecUserFirst + 9;
  ecJumpBack             = ecUserFirst + 10;
  ecJumpForward          = ecUserFirst + 11;
  ecAddJumpPoint         = ecUserFirst + 12;
  ecViewJumpHistory      = ecUserFirst + 13;

  // search code
  ecFindDeclaration      = ecUserFirst + 20;
  ecFindBlockOtherEnd    = ecUserFirst + 21;
  ecFindBlockStart       = ecUserFirst + 22;
  ecOpenFileAtCursor     = ecUserFirst + 23;
  ecGotoIncludeDirective = ecUserFirst + 24;

  // source notebook
  ecNextEditor           = ecUserFirst + 30;
  ecPrevEditor           = ecUserFirst + 31;
  ecMoveEditorLeft       = ecUserFirst + 32;
  ecMoveEditorRight      = ecUserFirst + 33;

  ecPeriod               = ecUserFirst + 40;

  // edit selection
  ecSelectionUpperCase   = ecUserFirst + 50;
  ecSelectionLowerCase   = ecUserFirst + 51;
  ecSelectionTabs2Spaces = ecUserFirst + 52;
  ecSelectionEnclose     = ecUserFirst + 53;
  ecSelectionComment     = ecUserFirst + 54;
  ecSelectionUncomment   = ecUserFirst + 55;
  ecSelectionSort        = ecUserFirst + 56;
  ecSelectionBreakLines  = ecUserFirst + 57;
  ecSelectToBrace        = ecUserFirst + 58;
  ecSelectCodeBlock      = ecUserFirst + 59;
  ecSelectLine           = ecUserFirst + 60;
  ecSelectParagraph      = ecUserFirst + 61;

  // insert text
  ecInsertCharacter      = ecUserFirst + 80;
  ecInsertGPLNotice      = ecUserFirst + 81;
  ecInsertLGPLNotice     = ecUserFirst + 82;
  ecInsertUserName       = ecUserFirst + 83;
  ecInsertDateTime       = ecUserFirst + 84;
  ecInsertChangeLogEntry = ecUserFirst + 85;
  ecInsertCVSAuthor      = ecUserFirst + 86;
  ecInsertCVSDate        = ecUserFirst + 87;
  ecInsertCVSHeader      = ecUserFirst + 88;
  ecInsertCVSID          = ecUserFirst + 89;
  ecInsertCVSLog         = ecUserFirst + 90;
  ecInsertCVSName        = ecUserFirst + 91;
  ecInsertCVSRevision    = ecUserFirst + 92;
  ecInsertCVSSource      = ecUserFirst + 93;

  // source tools
  ecWordCompletion       = ecUserFirst + 100;
  ecCompleteCode         = ecUserFirst + 101;
  ecIdentCompletion      = ecUserFirst + 102;
  ecSyntaxCheck          = ecUserFirst + 103;
  ecGuessUnclosedBlock   = ecUserFirst + 104;
  ecGuessMisplacedIFDEF  = ecUserFirst + 105;
  ecConvertDFM2LFM       = ecUserFirst + 106;
  ecCheckLFM             = ecUserFirst + 107;
  ecConvertDelphiUnit    = ecUserFirst + 108;
  ecMakeResourceString   = ecUserFirst + 109;
  ecDiff                 = ecUserFirst + 110;
  ecExtractProc          = ecUserFirst + 111;

  // file menu
  ecNew                  = ecUserFirst + 201;
  ecNewUnit              = ecUserFirst + 202;
  ecNewForm              = ecUserFirst + 203;
  ecOpen                 = ecUserFirst + 205;
  ecRevert               = ecUserFirst + 206;
  ecSave                 = ecUserFirst + 207;
  ecSaveAs               = ecUserFirst + 208;
  ecSaveAll              = ecUserFirst + 209;
  ecClose                = ecUserFirst + 210;
  ecCloseAll             = ecUserFirst + 211;
  ecCleanDirectory       = ecUserFirst + 212;
  ecQuit                 = ecUserFirst + 213;

  // IDE navigation
  ecJumpToEditor         = ecUserFirst + 300;
  ecToggleFormUnit       = ecUserFirst + 301;
  ecToggleObjectInsp     = ecUserFirst + 302;
  ecToggleSourceEditor   = ecUserFirst + 303;
  ecToggleCodeExpl       = ecUserFirst + 304;
  ecToggleMessages       = ecUserFirst + 305;
  ecToggleWatches        = ecUserFirst + 306;
  ecToggleBreakPoints    = ecUserFirst + 307;
  ecToggleDebuggerOut    = ecUserFirst + 308;
  ecViewUnits            = ecUserFirst + 309;
  ecViewForms            = ecUserFirst + 310;
  ecViewUnitDependencies = ecUserFirst + 311;
  ecToggleLocals         = ecUserFirst + 312;
  ecToggleCallStack      = ecUserFirst + 313;
  ecToggleSearchResults  = ecUserFirst + 314;

  // sourcenotebook commands
  ecGotoEditor1          = ecUserFirst + 350;
  ecGotoEditor2          = ecGotoEditor1 + 1;
  ecGotoEditor3          = ecGotoEditor2 + 1;
  ecGotoEditor4          = ecGotoEditor3 + 1;
  ecGotoEditor5          = ecGotoEditor4 + 1;
  ecGotoEditor6          = ecGotoEditor5 + 1;
  ecGotoEditor7          = ecGotoEditor6 + 1;
  ecGotoEditor8          = ecGotoEditor7 + 1;
  ecGotoEditor9          = ecGotoEditor8 + 1;
  ecGotoEditor0          = ecGotoEditor9 + 1;

  // compile menu
  ecBuild                = ecUserFirst + 400;
  ecBuildAll             = ecUserFirst + 401;
  ecAbortBuild           = ecUserFirst + 402;
  ecRun                  = ecUserFirst + 403;
  ecPause                = ecUserFirst + 404;
  ecStepInto             = ecUserFirst + 405;
  ecStepOver             = ecUserFirst + 406;
  ecRunToCursor          = ecUserFirst + 407;
  ecStopProgram          = ecUserFirst + 408;
  ecResetDebugger        = ecUserFirst + 409;
  ecBuildLazarus         = ecUserFirst + 410;
  ecBuildFile            = ecUserFirst + 411;
  ecRunFile              = ecUserFirst + 412;
  ecConfigBuildFile      = ecUserFirst + 413;

  // project menu
  ecNewProject           = ecUserFirst + 500;
  ecNewProjectFromFile   = ecUserFirst + 501;
  ecOpenProject          = ecUserFirst + 502;
  ecSaveProject          = ecUserFirst + 503;
  ecSaveProjectAs        = ecUserFirst + 504;
  ecPublishProject       = ecUserFirst + 505;
  ecProjectInspector     = ecUserFirst + 506;
  ecAddCurUnitToProj     = ecUserFirst + 507;
  ecRemoveFromProj       = ecUserFirst + 508;
  ecViewProjectSource    = ecUserFirst + 509;
  ecViewProjectTodos     = ecUserFirst + 510;
  ecProjectOptions       = ecUserFirst + 511;

  // components menu
  ecOpenPackage          = ecUserFirst + 600;
  ecOpenPackageFile      = ecUserFirst + 601;
  ecAddCurUnitToPkg      = ecUserFirst + 603;
  ecPackageGraph         = ecUserFirst + 604;
  ecConfigCustomComps    = ecUserFirst + 605;

  // custom tools menu
  ecExtToolFirst         = ecUserFirst + 700;
  ecExtToolLast          = ecUserFirst + 799;

  // option commmands
  ecRunParameters        = ecUserFirst + 800;
  ecCompilerOptions      = ecUserFirst + 801;
  ecExtToolSettings      = ecUserFirst + 802;
  ecConfigBuildLazarus   = ecUserFirst + 803;
  ecEnvironmentOptions   = ecUserFirst + 804;
  ecEditorOptions        = ecUserFirst + 805;
  ecCodeToolsOptions     = ecUserFirst + 806;
  ecCodeToolsDefinesEd   = ecUserFirst + 807;
  ecRescanFPCSrcDir      = ecUserFirst + 808;

  // help menu
  ecAboutLazarus         = ecUserFirst + 900;
  
  // designer
  ecCopyComponents       = ecUserFirst + 1000;
  ecCutComponents        = ecUserFirst + 1001;
  ecPasteComponents      = ecUserFirst + 1002;
  ecSelectParentComponent= ecUserFirst + 1003;

  // custom tools
  ecCustomToolFirst      = ecUserFirst + 2000;
  ecCustomToolLast       = ecUserFirst + 2999;


const
  caAll = [caSourceEditor, caDesigner];
  caSrcEditOnly = [caSourceEditor];
  caDesignOnly = [caDesigner];
  
type
  TKeyMapScheme = (
    kmsLazarus,
    kmsClassic,
    kmsCustom
    );

  //---------------------------------------------------------------------------
  // TKeyCommandCategory is used to divide the key commands in handy packets
  TKeyCommandCategory = class(TIDECommandCategory)
  public
    procedure Clear; override;
    procedure Delete(Index: Integer); override;
    constructor Create(const AName, ADescription: string;
      TheAreas: TCommandAreas);
  end;
  
  //---------------------------------------------------------------------------
  // class for storing the keys of a single command (key-command relationship)
  TKeyCommandRelation = class(TIDECommandKeys)
  public
    function GetLocalizedName: string; override;
  end;

  //---------------------------------------------------------------------------
  // class for a list of key - command relations
  TKeyCommandRelationList = class
  private
    FCustomKeyCount: integer;
    fRelations: TList; // list of TKeyCommandRelation, sorted with Command
    fCategories: TList;// list of TKeyCommandCategory
    fExtToolCount: integer;
    function GetCategory(Index: integer): TKeyCommandCategory;
    function GetRelation(Index:integer):TKeyCommandRelation;
    function AddCategory(const Name, Description: string;
       TheAreas: TCommandAreas): integer;
    function Add(Category: TKeyCommandCategory; const Name: string;
       Command:word;  const TheKeyA, TheKeyB: TIDEShortCut):integer;
    function AddDefault(Category: TKeyCommandCategory; const Name: string;
       Command:word):integer;
    procedure SetCustomKeyCount(const NewCount: integer);
    procedure SetExtToolCount(NewCount: integer);
  public
    constructor Create;
    destructor Destroy; override;
    procedure CreateDefaultMapping;
    procedure Clear;
    function Count: integer;
    function CategoryCount: integer;
    function Find(AKey:Word; AShiftState:TShiftState;
                  Areas: TCommandAreas): TKeyCommandRelation;
    function FindByCommand(ACommand:word): TKeyCommandRelation;
    function FindCategoryByName(const CategoryName: string): TKeyCommandCategory;
    function TranslateKey(AKey:Word; AShiftState:TShiftState;
                          Areas: TCommandAreas): word;
    function IndexOf(ARelation: TKeyCommandRelation): integer;
    function CommandToShortCut(ACommand: word): TShortCut;
    function LoadFromXMLConfig(XMLConfig:TXMLConfig; const Prefix: String):boolean;
    function SaveToXMLConfig(XMLConfig:TXMLConfig; const Prefix: String):boolean;
    procedure AssignTo(ASynEditKeyStrokes:TSynEditKeyStrokes;
                       Areas: TCommandAreas);
    procedure Assign(List: TKeyCommandRelationList);
    procedure LoadScheme(const SchemeName: string);
  public
    property ExtToolCount: integer read fExtToolCount write SetExtToolCount;
    property CustomKeyCount: integer read FCustomKeyCount write SetCustomKeyCount;
    property Relations[Index:integer]:TKeyCommandRelation read GetRelation;
    property Categories[Index: integer]: TKeyCommandCategory read GetCategory;
  end;

  //---------------------------------------------------------------------------
  // form for editing one command - key relationship
  TKeyMappingEditForm = class(TForm)
    OkButton: TButton;
    CancelButton: TButton;
    CommandLabel: TLabel;
    Key1GroupBox: TGroupBox;
    Key1CtrlCheckBox: TCheckBox;
    Key1AltCheckBox: TCheckBox;
    Key1ShiftCheckBox: TCheckBox;
    Key1KeyComboBox: TComboBox;
    Key1GrabButton: TButton;
    Key2GroupBox: TGroupBox;
    Key2CtrlCheckBox: TCheckBox;
    Key2AltCheckBox: TCheckBox;
    Key2ShiftCheckBox: TCheckBox;
    Key2KeyComboBox: TComboBox;
    Key2GrabButton: TButton;
    procedure OkButtonClick(Sender: TObject);
    procedure CancelButtonClick(Sender: TObject);
    procedure Key1GrabButtonClick(Sender: TObject);
    procedure Key2GrabButtonClick(Sender: TObject);
    procedure FormKeyUp(Sender: TObject; var Key: Word; Shift:TShiftState);
  private
    GrabbingKey: integer; // 0=none, 1=Default key, 2=Alternative key
    procedure ActivateGrabbing(AGrabbingKey: integer);
    procedure DeactivateGrabbing;
    procedure SetComboBox(AComboBox: TComboBox; AValue: string);
  public
    constructor Create(TheOwner:TComponent); override;
    KeyCommandRelationList:TKeyCommandRelationList;
    KeyIndex:integer;
  end;

function KeyAndShiftStateToEditorKeyString(Key:Word;
   ShiftState:TShiftState):AnsiString;
function ShowKeyMappingEditForm(Index:integer;
   AKeyCommandRelationList:TKeyCommandRelationList):TModalResult;
function KeyStrokesConsistencyErrors(ASynEditKeyStrokes:TSynEditKeyStrokes;
   Protocol: TStrings; var Index1,Index2:integer):integer;
function EditorCommandToDescriptionString(cmd: word): String;
function EditorCommandLocalizedName(cmd: word;
  const DefaultName: string): string;
function EditorKeyStringToVKCode(const s: string): word;

procedure GetDefaultKeyForCommand(Command: word;
  var TheKeyA, TheKeyB: TIDEShortCut);
procedure GetDefaultKeyForClassicScheme(Command: word;
  var TheKeyA, TheKeyB: TIDEShortCut);
function KeySchemeNameToSchemeType(const SchemeName: string): TKeyMapScheme;

function ShiftStateToStr(Shift:TShiftState):AnsiString;
function KeyValuesToStr(const KeyA, KeyB: TIDEShortCut): string;
function EditorKeyStringIsIrregular(const s: string): boolean;

var KeyMappingEditForm: TKeyMappingEditForm;

const
  KeyCategoryToolMenuName = 'ToolMenu';
  KeyCategoryCustomName = 'Custom';
  UnknownVKPrefix = 'Word(''';
  UnknownVKPostfix = ''')';

implementation


const
  KeyMappingFormatVersion = 2;

  VirtualKeyStrings: TStringHashList = nil;
  
function EditorCommandLocalizedName(cmd: word;
  const DefaultName: string): string;
begin
  Result:=EditorCommandToDescriptionString(cmd);
  if Result=srkmecunknown then
    Result:=DefaultName;
end;

function EditorKeyStringToVKCode(const s: string): word;
var
  i: integer;
  Data: Pointer;
begin
  Result:=VK_UNKNOWN;
  if EditorKeyStringIsIrregular(s) then begin
    Result:=word(StrToIntDef(copy(s,7,length(s)-8),VK_UNKNOWN));
    exit;
  end;
  if (s<>'none') and (s<>'') then begin
    if VirtualKeyStrings=nil then begin
      VirtualKeyStrings:=TStringHashList.Create(true);
      for i:=1 to 300 do
        VirtualKeyStrings.Add(KeyAndShiftStateToEditorKeyString(word(i),[]),
                              Pointer(i));
    end;
  end else
    exit;
  Data:=VirtualKeyStrings.Data[s];
  if Data<>nil then
    Result:=integer(Data);
end;

procedure GetDefaultKeyForCommand(Command: word;
  var TheKeyA, TheKeyB: TIDEShortCut);

  procedure SetResult(NewKeyA: word; NewShiftA: TShiftState;
    NewKeyB: word; NewShiftB: TShiftState);
  begin
    TheKeyA:=IDEShortCut(NewKeyA,NewShiftA,VK_UNKNOWN,[]);
    TheKeyB:=IDEShortCut(NewKeyB,NewShiftB,VK_UNKNOWN,[]);
  end;

  procedure SetResult(NewKeyA: word; NewShiftA: TShiftState);
  begin
    SetResult(NewKeyA,NewShiftA,VK_UNKNOWN,[]);
  end;

begin
  case Command of
  // moving
  ecWordLeft: SetResult(VK_LEFT, [ssCtrl],VK_UNKNOWN,[]);
  ecWordRight: SetResult(VK_RIGHT, [ssCtrl],VK_UNKNOWN,[]);
  ecLineStart: SetResult(VK_HOME, [],VK_UNKNOWN,[]);
  ecLineEnd: SetResult(VK_END, [],VK_UNKNOWN,[]);
  ecPageUp: SetResult(VK_PRIOR, [],VK_UNKNOWN,[]);
  ecPageDown: SetResult(VK_NEXT, [],VK_UNKNOWN,[]);
  ecPageLeft: SetResult(VK_UNKNOWN,[],VK_UNKNOWN,[]);
  ecPageRight: SetResult(VK_UNKNOWN,[],VK_UNKNOWN,[]);
  ecPageTop: SetResult(VK_PRIOR, [ssCtrl],VK_UNKNOWN,[]);
  ecPageBottom: SetResult(VK_NEXT, [ssCtrl],VK_UNKNOWN,[]);
  ecEditorTop: SetResult(VK_HOME,[ssCtrl],VK_UNKNOWN,[]);
  ecEditorBottom: SetResult(VK_END,[ssCtrl],VK_UNKNOWN,[]);
  ecScrollUp: SetResult(VK_UP, [ssCtrl],VK_UNKNOWN,[]);
  ecScrollDown: SetResult(VK_DOWN, [ssCtrl],VK_UNKNOWN,[]);
  ecScrollLeft: SetResult(VK_UNKNOWN, [],VK_UNKNOWN,[]);
  ecScrollRight: SetResult(VK_UNKNOWN, [],VK_UNKNOWN,[]);

  // selection
  ecCopy: SetResult(VK_C,[ssCtrl],VK_Insert,[ssCtrl]);
  ecCut: SetResult(VK_X,[ssCtrl],VK_Delete,[ssShift]);
  ecPaste: SetResult(VK_V,[ssCtrl],VK_Insert,[ssShift]);
  ecNormalSelect: SetResult(VK_UNKNOWN,[],VK_UNKNOWN,[]);
  ecColumnSelect: SetResult(VK_UNKNOWN,[],VK_UNKNOWN,[]);
  ecLineSelect: SetResult(VK_UNKNOWN,[],VK_UNKNOWN,[]);
  ecSelWordLeft: SetResult(VK_LEFT,[ssCtrl,ssShift],VK_UNKNOWN,[]);
  ecSelWordRight: SetResult(VK_RIGHT,[ssCtrl,ssShift],VK_UNKNOWN,[]);
  ecSelLineStart: SetResult(VK_HOME,[ssShift],VK_UNKNOWN,[]);
  ecSelLineEnd: SetResult(VK_END,[ssShift],VK_UNKNOWN,[]);
  ecSelPageTop: SetResult(VK_PRIOR, [ssShift,ssCtrl],VK_UNKNOWN,[]);
  ecSelPageBottom: SetResult(VK_NEXT, [ssShift,ssCtrl],VK_UNKNOWN,[]);
  ecSelEditorTop: SetResult(VK_HOME, [ssShift,ssCtrl],VK_UNKNOWN,[]);
  ecSelEditorBottom: SetResult(VK_END, [ssShift,ssCtrl],VK_UNKNOWN,[]);
  ecSelectAll: SetResult(VK_UNKNOWN,[],VK_UNKNOWN,[]);
  ecSelectToBrace: SetResult(VK_UNKNOWN,[],VK_UNKNOWN,[]);
  ecSelectCodeBlock: SetResult(VK_UNKNOWN,[],VK_UNKNOWN,[]);
  ecSelectLine: SetResult(VK_UNKNOWN,[],VK_UNKNOWN,[]);
  ecSelectParagraph: SetResult(VK_UNKNOWN,[],VK_UNKNOWN,[]);
  ecSelectionUpperCase: SetResult(VK_UNKNOWN, [],VK_UNKNOWN,[]);
  ecSelectionLowerCase: SetResult(VK_UNKNOWN, [],VK_UNKNOWN,[]);
  ecSelectionTabs2Spaces: SetResult(VK_UNKNOWN, [],VK_UNKNOWN,[]);
  ecSelectionEnclose: SetResult(VK_UNKNOWN, [],VK_UNKNOWN,[]);
  ecSelectionComment: SetResult(VK_UNKNOWN, [],VK_UNKNOWN,[]);
  ecSelectionUncomment: SetResult(VK_UNKNOWN, [],VK_UNKNOWN,[]);
  ecSelectionSort: SetResult(VK_UNKNOWN, [],VK_UNKNOWN,[]);
  ecSelectionBreakLines: SetResult(VK_UNKNOWN, [],VK_UNKNOWN,[]);

  // editing
  ecBlockIndent: SetResult(VK_I,[ssCtrl],VK_UNKNOWN,[]);
  ecBlockUnindent: SetResult(VK_U,[ssCtrl],VK_UNKNOWN,[]);
  ecDeleteLastChar: SetResult(VK_BACK, [],VK_BACK, [ssShift]);
  ecDeleteChar: SetResult(VK_DELETE,[],VK_UNKNOWN,[]);
  ecDeleteWord: SetResult(VK_T,[ssCtrl],VK_UNKNOWN,[]);
  ecDeleteLastWord: SetResult(VK_BACK,[ssCtrl],VK_UNKNOWN,[]);
  ecDeleteBOL: SetResult(VK_UNKNOWN,[],VK_UNKNOWN,[]);
  ecDeleteEOL: SetResult(VK_Y,[ssCtrl,ssShift],VK_UNKNOWN,[]);
  ecDeleteLine: SetResult(VK_Y,[ssCtrl],VK_UNKNOWN,[]);
  ecClearAll: SetResult(VK_UNKNOWN,[],VK_UNKNOWN,[]);
  ecLineBreak: SetResult(VK_RETURN,[],VK_UNKNOWN,[]);
  ecInsertLine: SetResult(VK_N,[ssCtrl],VK_UNKNOWN,[]);
  ecInsertCharacter: SetResult(VK_UNKNOWN,[],VK_UNKNOWN,[]);
  ecInsertGPLNotice: SetResult(VK_UNKNOWN,[],VK_UNKNOWN,[]);
  ecInsertLGPLNotice: SetResult(VK_UNKNOWN,[],VK_UNKNOWN,[]);
  ecInsertUserName: SetResult(VK_UNKNOWN,[],VK_UNKNOWN,[]);
  ecInsertDateTime: SetResult(VK_UNKNOWN,[],VK_UNKNOWN,[]);
  ecInsertChangeLogEntry: SetResult(VK_UNKNOWN,[],VK_UNKNOWN,[]);
  ecInsertCVSAuthor: SetResult(VK_UNKNOWN,[],VK_UNKNOWN,[]);
  ecInsertCVSDate: SetResult(VK_UNKNOWN,[],VK_UNKNOWN,[]);
  ecInsertCVSHeader: SetResult(VK_UNKNOWN,[],VK_UNKNOWN,[]);
  ecInsertCVSID: SetResult(VK_UNKNOWN,[],VK_UNKNOWN,[]);
  ecInsertCVSLog: SetResult(VK_UNKNOWN,[],VK_UNKNOWN,[]);
  ecInsertCVSName: SetResult(VK_UNKNOWN,[],VK_UNKNOWN,[]);
  ecInsertCVSRevision: SetResult(VK_UNKNOWN,[],VK_UNKNOWN,[]);
  ecInsertCVSSource: SetResult(VK_UNKNOWN,[],VK_UNKNOWN,[]);

  // command commands
  ecUndo: SetResult(VK_Z,[ssCtrl],VK_UNKNOWN,[]);
  ecRedo: SetResult(VK_Z,[ssCtrl,ssShift],VK_UNKNOWN,[]);

  // search & replace
  ecMatchBracket: SetResult(VK_UNKNOWN,[],VK_UNKNOWN,[]);
  ecFind: SetResult(VK_F,[SSCtrl],VK_UNKNOWN,[]);
  ecFindNext: SetResult(VK_F3,[],VK_UNKNOWN,[]);
  ecFindPrevious: SetResult(VK_UNKNOWN,[],VK_UNKNOWN,[]);
  ecFindInFiles: SetResult(VK_UNKNOWN,[],VK_UNKNOWN,[]);
  ecReplace: SetResult(VK_R,[SSCtrl],VK_UNKNOWN,[]);
  ecIncrementalFind: SetResult(VK_E,[SSCtrl],VK_UNKNOWN,[]);
  ecGotoLineNumber: SetResult(VK_G,[ssCtrl],VK_UNKNOWN,[]);
  ecJumpBack: SetResult(VK_H,[ssCtrl],VK_UNKNOWN,[]);
  ecJumpForward: SetResult(VK_H,[ssCtrl,ssShift],VK_UNKNOWN,[]);
  ecAddJumpPoint: SetResult(VK_UNKNOWN,[],VK_UNKNOWN,[]);
  ecViewJumpHistory: SetResult(VK_UNKNOWN,[],VK_UNKNOWN,[]);
  ecOpenFileAtCursor: SetResult(VK_RETURN,[ssCtrl],VK_UNKNOWN,[]);

  // marker
  ecGotoMarker0: SetResult(VK_0,[ssCtrl],VK_UNKNOWN,[]);
  ecGotoMarker1: SetResult(VK_1,[ssCtrl],VK_UNKNOWN,[]);
  ecGotoMarker2: SetResult(VK_2,[ssCtrl],VK_UNKNOWN,[]);
  ecGotoMarker3: SetResult(VK_3,[ssCtrl],VK_UNKNOWN,[]);
  ecGotoMarker4: SetResult(VK_4,[ssCtrl],VK_UNKNOWN,[]);
  ecGotoMarker5: SetResult(VK_5,[ssCtrl],VK_UNKNOWN,[]);
  ecGotoMarker6: SetResult(VK_6,[ssCtrl],VK_UNKNOWN,[]);
  ecGotoMarker7: SetResult(VK_7,[ssCtrl],VK_UNKNOWN,[]);
  ecGotoMarker8: SetResult(VK_8,[ssCtrl],VK_UNKNOWN,[]);
  ecGotoMarker9: SetResult(VK_9,[ssCtrl],VK_UNKNOWN,[]);
  ecSetMarker0: SetResult(VK_0,[ssShift,ssCtrl],VK_UNKNOWN,[]);
  ecSetMarker1: SetResult(VK_1,[ssShift,ssCtrl],VK_UNKNOWN,[]);
  ecSetMarker2: SetResult(VK_2,[ssShift,ssCtrl],VK_UNKNOWN,[]);
  ecSetMarker3: SetResult(VK_3,[ssShift,ssCtrl],VK_UNKNOWN,[]);
  ecSetMarker4: SetResult(VK_4,[ssShift,ssCtrl],VK_UNKNOWN,[]);
  ecSetMarker5: SetResult(VK_5,[ssShift,ssCtrl],VK_UNKNOWN,[]);
  ecSetMarker6: SetResult(VK_6,[ssShift,ssCtrl],VK_UNKNOWN,[]);
  ecSetMarker7: SetResult(VK_7,[ssShift,ssCtrl],VK_UNKNOWN,[]);
  ecSetMarker8: SetResult(VK_8,[ssShift,ssCtrl],VK_UNKNOWN,[]);
  ecSetMarker9: SetResult(VK_9,[ssShift,ssCtrl],VK_UNKNOWN,[]);

  // codetools
  ecAutoCompletion: SetResult(VK_J,[ssCtrl],VK_UNKNOWN,[]);
  ecWordCompletion: SetResult(VK_W,[ssCtrl],VK_UNKNOWN,[]);
  ecCompleteCode: SetResult(VK_C,[ssCtrl,ssShift],VK_UNKNOWN,[]);
  ecIdentCompletion: SetResult(VK_SPACE,[ssCtrl],VK_UNKNOWN,[]);
  ecExtractProc: SetResult(VK_UNKNOWN,[],VK_UNKNOWN,[]);
  ecSyntaxCheck: SetResult(VK_UNKNOWN,[],VK_UNKNOWN,[]);
  ecGuessUnclosedBlock: SetResult(VK_UNKNOWN,[],VK_UNKNOWN,[]);
  ecGuessMisplacedIFDEF: SetResult(VK_UNKNOWN,[],VK_UNKNOWN,[]);
  ecConvertDFM2LFM: SetResult(VK_UNKNOWN,[],VK_UNKNOWN,[]);
  ecCheckLFM: SetResult(VK_UNKNOWN,[],VK_UNKNOWN,[]);
  ecConvertDelphiUnit: SetResult(VK_UNKNOWN,[],VK_UNKNOWN,[]);
  ecFindProcedureDefinition: SetResult(
                                 VK_UP,[ssShift,SSCtrl],VK_UNKNOWN,[]);
  ecFindProcedureMethod: SetResult(
                                 VK_DOWN,[ssShift,SSCtrl],VK_UNKNOWN,[]);
  ecFindDeclaration: SetResult(VK_UNKNOWN,[],VK_UNKNOWN,[]);
  ecFindBlockOtherEnd: SetResult(VK_UNKNOWN,[],VK_UNKNOWN,[]);
  ecFindBlockStart: SetResult(VK_UNKNOWN,[],VK_UNKNOWN,[]);
  ecGotoIncludeDirective: SetResult(VK_UNKNOWN,[],VK_UNKNOWN,[]);

  // source notebook
  ecNextEditor: SetResult(VK_TAB, [ssCtrl], VK_UNKNOWN, []);
  ecPrevEditor: SetResult(VK_TAB, [ssShift,ssCtrl], VK_UNKNOWN, []);
  ecGotoEditor1: SetResult(VK_1,[ssAlt],VK_UNKNOWN,[]);
  ecGotoEditor2: SetResult(VK_2,[ssAlt],VK_UNKNOWN,[]);
  ecGotoEditor3: SetResult(VK_3,[ssAlt],VK_UNKNOWN,[]);
  ecGotoEditor4: SetResult(VK_4,[ssAlt],VK_UNKNOWN,[]);
  ecGotoEditor5: SetResult(VK_5,[ssAlt],VK_UNKNOWN,[]);
  ecGotoEditor6: SetResult(VK_6,[ssAlt],VK_UNKNOWN,[]);
  ecGotoEditor7: SetResult(VK_7,[ssAlt],VK_UNKNOWN,[]);
  ecGotoEditor8: SetResult(VK_8,[ssAlt],VK_UNKNOWN,[]);
  ecGotoEditor9: SetResult(VK_9,[ssAlt],VK_UNKNOWN,[]);
  ecGotoEditor0: SetResult(VK_0,[ssAlt],VK_UNKNOWN,[]);
  ecMoveEditorLeft: SetResult(VK_UNKNOWN, [], VK_UNKNOWN, []);
  ecMoveEditorRight: SetResult(VK_UNKNOWN, [], VK_UNKNOWN, []);

  // file menu
  ecNew: SetResult(VK_UNKNOWN,[],VK_UNKNOWN,[]);
  ecNewUnit: SetResult(VK_UNKNOWN,[],VK_UNKNOWN,[]);
  ecNewForm: SetResult(VK_UNKNOWN,[],VK_UNKNOWN,[]);
  ecOpen: SetResult(VK_O,[ssCtrl],VK_UNKNOWN,[]);
  ecRevert: SetResult(VK_UNKNOWN,[],VK_UNKNOWN,[]);
  ecSave: SetResult(VK_S,[ssCtrl],VK_UNKNOWN,[]);
  ecSaveAs: SetResult(VK_UNKNOWN,[],VK_UNKNOWN,[]);
  ecSaveAll: SetResult(VK_S,[ssCtrl,ssShift],VK_UNKNOWN,[]);
  ecClose: SetResult(VK_F4,[ssCtrl],VK_UNKNOWN,[]);
  ecCloseAll: SetResult(VK_UNKNOWN,[],VK_UNKNOWN,[]);
  ecCleanDirectory: SetResult(VK_UNKNOWN,[],VK_UNKNOWN,[]);
  ecQuit: SetResult(VK_UNKNOWN,[],VK_UNKNOWN,[]);

  // view menu
  ecToggleObjectInsp: SetResult(VK_F11,[],VK_UNKNOWN,[]);
  ecToggleSourceEditor: SetResult(VK_UNKNOWN,[],VK_UNKNOWN,[]);
  ecToggleCodeExpl: SetResult(VK_UNKNOWN,[],VK_UNKNOWN,[]);
  ecToggleMessages: SetResult(VK_UNKNOWN,[],VK_UNKNOWN,[]);
  ecToggleSearchResults: SetResult(VK_UNKNOWN,[],VK_UNKNOWN,[]);
  ecToggleWatches: SetResult(VK_W,[ssCtrl,ssAlt],VK_UNKNOWN,[]);
  ecToggleBreakPoints: SetResult(VK_B,[ssCtrl,ssAlt],VK_UNKNOWN,[]);
  ecToggleLocals: SetResult(VK_L,[ssCtrl,ssAlt],VK_UNKNOWN,[]);
  ecToggleCallStack: SetResult(VK_S,[ssCtrl,ssAlt],VK_UNKNOWN,[]);
  ecToggleDebuggerOut: SetResult(VK_UNKNOWN,[],VK_UNKNOWN,[]);
  ecViewUnits: SetResult(VK_F12,[ssCtrl],VK_UNKNOWN,[]);
  ecViewForms: SetResult(VK_F12,[ssShift],VK_UNKNOWN,[]);
  ecViewUnitDependencies: SetResult(VK_UNKNOWN,[],VK_UNKNOWN,[]);
  ecJumpToEditor: SetResult(VK_UNKNOWN,[],VK_UNKNOWN,[]);
  ecToggleFormUnit: SetResult(VK_F12,[],VK_UNKNOWN,[]);

  // project menu
  ecNewProject: SetResult(VK_UNKNOWN,[],VK_UNKNOWN,[]);
  ecNewProjectFromFile: SetResult(VK_UNKNOWN,[],VK_UNKNOWN,[]);
  ecOpenProject: SetResult(VK_F11,[ssCtrl],VK_UNKNOWN,[]);
  ecSaveProject: SetResult(VK_UNKNOWN,[],VK_UNKNOWN,[]);
  ecSaveProjectAs: SetResult(VK_UNKNOWN,[],VK_UNKNOWN,[]);
  ecPublishProject: SetResult(VK_UNKNOWN,[],VK_UNKNOWN,[]);
  ecProjectInspector: SetResult(VK_UNKNOWN,[],VK_UNKNOWN,[]);
  ecAddCurUnitToProj: SetResult(VK_F11,[ssShift],VK_UNKNOWN,[]);
  ecRemoveFromProj: SetResult(VK_UNKNOWN,[],VK_UNKNOWN,[]);
  ecViewProjectSource: SetResult(VK_UNKNOWN,[],VK_UNKNOWN,[]);
  ecViewProjectTodos: SetResult(VK_UNKNOWN,[],VK_UNKNOWN,[]);
  ecProjectOptions: SetResult(VK_F11,[ssShift,ssCtrl],VK_UNKNOWN,[]);

  // run menu
  ecBuild: SetResult(VK_F9,[ssCtrl],VK_UNKNOWN,[]);
  ecBuildAll: SetResult(VK_UNKNOWN,[],VK_UNKNOWN,[]);
  ecAbortBuild: SetResult(VK_UNKNOWN,[],VK_UNKNOWN,[]);
  ecRun: SetResult(VK_F9,[],VK_UNKNOWN,[]);
  ecPause: SetResult(VK_UNKNOWN,[],VK_UNKNOWN,[]);
  ecStepInto: SetResult(VK_F7,[],VK_UNKNOWN,[]);
  ecStepOver: SetResult(VK_F8,[],VK_UNKNOWN,[]);
  ecRunToCursor: SetResult(VK_F4,[],VK_UNKNOWN,[]);
  ecStopProgram: SetResult(VK_F2,[SSCtrl],VK_UNKNOWN,[]);
  ecResetDebugger: SetResult(VK_UNKNOWN,[],VK_UNKNOWN,[]);
  ecCompilerOptions: SetResult(VK_UNKNOWN,[],VK_UNKNOWN,[]);
  ecRunParameters: SetResult(VK_UNKNOWN,[],VK_UNKNOWN,[]);
  ecBuildFile: SetResult(VK_UNKNOWN,[],VK_UNKNOWN,[]);
  ecRunFile: SetResult(VK_UNKNOWN,[],VK_UNKNOWN,[]);
  ecConfigBuildFile: SetResult(VK_UNKNOWN,[],VK_UNKNOWN,[]);

  // components menu
  ecOpenPackage: SetResult(VK_UNKNOWN,[],VK_UNKNOWN,[]);
  ecOpenPackageFile: SetResult(VK_UNKNOWN,[],VK_UNKNOWN,[]);
  ecAddCurUnitToPkg: SetResult(VK_UNKNOWN,[],VK_UNKNOWN,[]);
  ecPackageGraph: SetResult(VK_UNKNOWN,[],VK_UNKNOWN,[]);
  ecConfigCustomComps: SetResult(VK_UNKNOWN,[],VK_UNKNOWN,[]);

  // tools menu
  ecExtToolSettings: SetResult(VK_UNKNOWN,[],VK_UNKNOWN,[]);
  ecBuildLazarus: SetResult(VK_UNKNOWN,[],VK_UNKNOWN,[]);
  ecConfigBuildLazarus: SetResult(VK_UNKNOWN,[],VK_UNKNOWN,[]);
  ecMakeResourceString: SetResult(VK_UNKNOWN,[],VK_UNKNOWN,[]);
  ecDiff: SetResult(VK_UNKNOWN,[],VK_UNKNOWN,[]);

  // environment menu
  ecEnvironmentOptions: SetResult(VK_UNKNOWN,[],VK_UNKNOWN,[]);
  ecEditorOptions: SetResult(VK_UNKNOWN,[],VK_UNKNOWN,[]);
  ecCodeToolsOptions: SetResult(VK_UNKNOWN,[],VK_UNKNOWN,[]);
  ecCodeToolsDefinesEd: SetResult(VK_UNKNOWN,[],VK_UNKNOWN,[]);
  ecRescanFPCSrcDir: SetResult(VK_UNKNOWN,[],VK_UNKNOWN,[]);

  // help menu
  ecAboutLazarus: SetResult(VK_UNKNOWN,[],VK_UNKNOWN,[]);

  // designer
  ecCopyComponents: SetResult(VK_C,[ssCtrl],VK_Insert,[ssCtrl]);
  ecCutComponents: SetResult(VK_X,[ssCtrl],VK_Delete,[ssShift]);
  ecPasteComponents: SetResult(VK_V,[ssCtrl],VK_Insert,[ssShift]);
  ecSelectParentComponent: SetResult(VK_ESCAPE,[],VK_UNKNOWN,[]);

  else
    SetResult(VK_UNKNOWN,[]);
  end;
end;

procedure GetDefaultKeyForClassicScheme(Command: word;
  var TheKeyA, TheKeyB: TIDEShortCut);
  
  procedure SetResult(NewKeyA: word; NewShiftA: TShiftState;
    NewKeyB: word; NewShiftB: TShiftState);
  begin
    TheKeyA:=IDEShortCut(NewKeyA,NewShiftA,VK_UNKNOWN,[]);
    TheKeyB:=IDEShortCut(NewKeyB,NewShiftB,VK_UNKNOWN,[]);
  end;

  procedure SetResult(NewKeyA: word; NewShiftA: TShiftState);
  begin
    SetResult(NewKeyA,NewShiftA,VK_UNKNOWN,[]);
  end;

begin
  SetResult(VK_UNKNOWN,[]);

  case Command of
//F1                      Topic Search
//Ctrl+F1                Topic Search
  ecNextEditor: SetResult(VK_F6,[]);
  ecPrevEditor: SetResult(VK_F6,[ssShift]);
  ecWordLeft:   SetResult(VK_A,[ssCtrl],VK_LEFT,[ssCtrl]);
  ecPageDown:   SetResult(VK_C,[ssCtrl],VK_NEXT,[]);
//Ctrl+D                 Moves the cursor right one column, accounting for the
//autoindent setting
//Ctrl+E                 Moves the cursor up one line
//Ctrl+F                 Moves one word right
//Ctrl+G                 Deletes the character to the right of the cursor
//Ctrl+H                 Deletes the character to the left of the cursor
//Ctrl+I                  Inserts a tab
//Ctrl+L                 Search|Search Again
//Ctrl+N                 Inserts a new line
//Ctrl+P                 Causes next character to be interpreted as an ASCII
//sequence
//Ctrl+R                 Moves up one screen
//Ctrl+S                 Moves the cursor left one column, accounting for the
//autoindent setting
//Ctrl+T                 Deletes a word
//Ctrl+V                 Turns insert mode on/off
//Ctrl+W                Moves down one screen
//Ctrl+X                 Moves the cursor down one line
//Ctrl+Y                 Deletes a line
//Ctrl+Z                 Moves the cursor up one line
//Ctrl+Shift+S          Performs an incremental search

//Block commands:
//---------------
//Ctrl+K+B      Marks the beginning of a block
//Ctrl+K+C      Copies a selected block
//Ctrl+K+H      Hides/shows a selected block
//Ctrl+K+I       Indents a block by the amount specified in the Block Indent
//combo box on the General page of the Editor Options dialog box.
//Ctrl+K+K      Marks the end of a block
//Ctrl+K+L       Marks the current line as a block
//Ctrl+K+N      Changes a block to uppercase
//Ctrl+K+O      Changes a block to lowercase
//Ctrl+K+P      Prints selected block
//Ctrl+K+R      Reads a block from a file
//Ctrl+K+T       Marks a word as a block
//Ctrl+K+U      Outdents a block by the amount specified in the Block Indent
//combo box on the General page of the Editor Options dialog box.
//Ctrl+K+V      Moves a selected block
//Ctrl+K+W      Writes a selected block to a file
//Ctrl+K+Y      Deletes a selected block
//Ctrl+O+C      Turns on column blocking
//Ctrl+O+I       Marks an inclusive block
//Ctrl+O+K      Turns off column blocking
//Ctrl+O+L      Marks a line as a block
//Shift+Alt+arrow Selects column-oriented blocks
//Click+Alt+mousemv Selects column-oriented blocks
//Ctrl+Q+B      Moves to the beginning of a block
//Ctrl+Q+K      Moves to the end of a block

//Miscellaneous commands:
//-----------------------
//Ctrl+K+D      Accesses the menu bar
//Ctrl+K+E       Changes a word to lowercase
//Ctrl+K+F       Changes a word to uppercase
//Ctrl+K+S      File|Save (Default and IDE Classic only)
//Ctrl+Q+A      Search|Replace
//Ctrl+Q+F      Search|Find
//Ctrl+Q+Y      Deletes to the end of a line
//Ctrl+Q+[       Finds the matching delimiter (forward)
//Ctrl+Q+Ctrl+[ Finds the matching delimiter (forward)
//Ctrl+Q+]       Finds the matching delimiter (backward)
//Ctrl+Q+Ctrl+] Finds the matching delimiter (backward)
//Ctrl+O+A      Open file at cursor
//Ctrl+O+B      Browse symbol at cursor (Delphi only)
//Alt+right arrow  For code browsing
//Alt +left arrow For code browsing
//Ctrl+O+G      Search|Go to line number
//Ctrl+O+O      Inserts compiler options and directives
//Ctrl+O+U      Toggles case
//Bookmark commands:
//------------------
//Shortcut       Action
//Ctrl+K+0       Sets bookmark 0
//Ctrl+K+1       Sets bookmark 1
//Ctrl+K+2       Sets bookmark 2
//Ctrl+K+3       Sets bookmark 3
//Ctrl+K+4       Sets bookmark 4
//Ctrl+K+5       Sets bookmark 5
//Ctrl+K+6       Sets bookmark 6
//Ctrl+K+7       Sets bookmark 7
//Ctrl+K+8       Sets bookmark 8
//Ctrl+K+9       Sets bookmark 9
//Ctrl+K+Ctrl+0 Sets bookmark 0
//Ctrl+K+Ctrl+1 Sets bookmark 1
//Ctrl+K+Ctrl+2 Sets bookmark 2
//Ctrl+K+Ctrl+3 Sets bookmark 3
//Ctrl+K+Ctrl+4 Sets bookmark 4
//Ctrl+K+Ctrl+5 Sets bookmark 5
//Ctrl+K+Ctrl+6 Sets bookmark 6
//Ctrl+K+Ctrl+7 Sets bookmark 7
//Ctrl+K+Ctrl+8 Sets bookmark 8
//Ctrl+K+Ctrl+9 Sets bookmark 9
//Ctrl+Q+0       Goes to bookmark 0
//Ctrl+Q+1       Goes to bookmark 1
//Ctrl+Q+2       Goes to bookmark 2
//Ctrl+Q+3       Goes to bookmark 3
//Ctrl+Q+4       Goes to bookmark 4
//Ctrl+Q+5       Goes to bookmark 5
//Ctrl+Q+6       Goes to bookmark 6
//Ctrl+Q+7       Goes to bookmark 7
//Ctrl+Q+8       Goes to bookmark 8
//Ctrl+Q+9       Goes to bookmark 9
//Ctrl+Q+Ctrl+0 Goes to bookmark 0
//Ctrl+Q+Ctrl+1 Goes to bookmark 1
//Ctrl+Q+Ctrl+2 Goes to bookmark 2
//Ctrl+Q+Ctrl+3 Goes to bookmark 3
//Ctrl+Q+Ctrl+4 Goes to bookmark 4
//Ctrl+Q+Ctrl+5 Goes to bookmark 5
//Ctrl+Q+Ctrl+6 Goes to bookmark 6
//Ctrl+Q+Ctrl+7 Goes to bookmark 7
//Ctrl+Q+Ctrl+8 Goes to bookmark 8
//Ctrl+Q+Ctrl+9 Goes to bookmark 9
//Cursor movement:
//----------------
//Ctrl+Q+B      Moves to the beginning of a block
//Ctrl+Q+C      Moves to end of a file
//Ctrl+Q+D      Moves to the end of a line
//Ctrl+Q+E      Moves the cursor to the top of the window
//Ctrl+Q+K      Moves to the end of a block
//Ctrl+Q+P      Moves to previous position
//Ctrl+Q+R      Moves to the beginning of a file
//Ctrl+Q+S      Moves to the beginning of a line
//Ctrl+Q+T      Moves the viewing editor so that the current line is placed at
//the top of the window
//Ctrl+Q+U      Moves the viewing editor so that the current line is placed at
//the bottom of the window, if possible
//Ctrl+Q+X      Moves the cursor to the bottom of the window
//System keys:
//------------

//F1              Displays context-sensitive Help
//F2              File|Save
//F3              File|Open
//F4              Run to Cursor
//F5              Zooms window
//F6              Displays the next page
//F7              Run|Trace Into
//F8              Run|Step Over
//F9              Run|Run
//F11             View|Object Inspector
//F12             View|Toggle Form/Unit
//Alt+0           View|Window List
//Alt+F2          View|CPU
//Alt+F3          File|Close
//Alt+F7          Displays previous error in Message view
//Alt+F8          Displays next error in Message view
//Alt+F11        File|Use Unit (Delphi)
//Alt+F11        File|Include Unit Hdr (C++)
//Alt+F12        Displays the Code editor
//Alt+X           File|Exit
//Alt+right arrow  For code browsing forward
//Alt +left arrow For code browsing backward
//Alt +up arrow  For code browsing Ctrl-click on identifier
//Alt+Page Down Goes to the next tab
//Alt+Page Up   Goes to the previous tab
//Ctrl+F1        Topic Search
//Ctrl+F2        Run|Program Reset
//Ctrl+F3        View|Call Stack
//Ctrl+F6        Open Source/Header file (C++)
//Ctrl+F7        Add Watch at Cursor
//Ctrl+F8        Toggle Breakpoint
//Ctrl+F9        Project|Compile project (Delphi)
//Ctrl+F9        Project|Make project (C++)
//Ctrl+F11       File|Open Project
//Ctrl+F12       View|Units
//Shift+F7       Run|Trace To Next Source Line
//Shift+F11      Project|Add To Project
//Shift+F12      View|Forms
//Ctrl+D         Descends item (replaces Inspector window)
//Ctrl+N         Opens a new Inspector window
//Ctrl+S          Incremental search
//Ctrl+T          Displays the Type Cast dialog
  else
    GetDefaultKeyForCommand(Command,TheKeyA,TheKeyB);
  end;
end;

function KeySchemeNameToSchemeType(const SchemeName: string): TKeyMapScheme;
begin
  if (SchemeName='') or (AnsiCompareText(SchemeName,'Default')=0) then
    Result:=kmsLazarus
  else if (AnsiCompareText(SchemeName,'Classic')=0) then
    Result:=kmsClassic
  else
    Result:=kmsCustom;
end;

function ShiftStateToStr(Shift:TShiftState):AnsiString;
var i:integer;
begin
  i:=0;
  if ssCtrl in Shift then inc(i,1);
  if ssShift in Shift then inc(i,2);
  if ssAlt in Shift then inc(i,4);
  Result:=IntToStr(i);
end;

function KeyValuesToStr(const KeyA, KeyB: TIDEShortCut): string;
begin
  Result:=IntToStr(KeyA.Key1)+','+ShiftStateToStr(KeyA.Shift1)
        +','+IntToStr(KeyB.Key1)+','+ShiftStateToStr(KeyB.Shift1);
end;

function EditorKeyStringIsIrregular(const s: string): boolean;
begin
  if (length(UnknownVKPrefix)<length(s))
  and (AnsiStrLComp(PChar(s),PChar(UnknownVKPrefix),length(UnknownVKPrefix))=0)
  then
    Result:=true
  else
    Result:=false;
end;

function ShowKeyMappingEditForm(Index:integer;
  AKeyCommandRelationList: TKeyCommandRelationList):TModalResult;
   
  procedure InitComboBox(AComboBox: TComboBox; AKey: word);
  var s: string;
    i: integer;
  begin
    s:=KeyAndShiftStateToEditorKeyString(AKey,[]);
    i:=AComboBox.Items.IndexOf(s);
    if i>=0 then
      AComboBox.ItemIndex:=i
    else if EditorKeyStringIsIrregular(s) then begin
      AComboBox.Items.Add(s);
      AComboBox.ItemIndex:=AComboBox.Items.IndexOf(s);
    end else
      AComboBox.ItemIndex:=0;
  end;
   
begin
  Result:=mrCancel;
  if KeyMappingEditForm<>nil then exit;
  KeyMappingEditForm:=TKeyMappingEditForm.Create(Application);
  with KeyMappingEditForm do
    try
      KeyCommandRelationList:=AKeyCommandRelationList;
      KeyIndex:=Index;
      Caption:=srkmEditKeys;

      with KeyCommandRelationList.Relations[Index] do
      begin
        CommandLabel.Caption:=srkmCommand+LocalizedName;
        if (KeyA.Key1<>VK_UNKNOWN) then
        begin
          Key1CtrlCheckBox.Checked:=ssCtrl in KeyA.Shift1;
          Key1AltCheckBox.Checked:=ssAlt in KeyA.Shift1;
          Key1ShiftCheckBox.Checked:=ssShift in KeyA.Shift1;
          InitComboBox(Key1KeyComboBox,KeyA.Key1);
        end;
        if (KeyB.Key1<>VK_UNKNOWN) then
        begin
          Key2CtrlCheckBox.Checked:=ssCtrl in KeyB.Shift1;
          Key2AltCheckBox.Checked:=ssAlt in KeyB.Shift1;
          Key2ShiftCheckBox.Checked:=ssShift in KeyB.Shift1;
          InitComboBox(Key2KeyComboBox,KeyB.Key1);
        end;
      end;
      Result:=ShowModal;
    finally
      Free;
      KeyMappingEditForm:=nil;
    end;
end;

function EditorCommandToDescriptionString(cmd: word): String;
begin
  case cmd of
    ecNone                  : Result:= dlgEnvNone;
    ecLeft                  : Result:= srvk_left;
    ecRight                 : Result:= srvk_right;
    ecUp                    : Result:= dlgUpWord;
    ecDown                  : Result:= dlgDownWord;
    ecWordLeft              : Result:= srkmecWordLeft;
    ecWordRight             : Result:= srkmecWordRight;
    ecLineStart             : Result:= srkmecLineStart;
    ecLineEnd               : Result:= srkmecLineEnd;
    ecPageUp                : Result:= srkmecPageUp;
    ecPageDown              : Result:= srkmecPageDown;
    ecPageLeft              : Result:= srkmecPageLeft;
    ecPageRight             : Result:= srkmecPageRight;
    ecPageTop               : Result:= srkmecPageTop;
    ecPageBottom            : Result:= srkmecPageBottom;
    ecEditorTop             : Result:= srkmecEditorTop;
    ecEditorBottom          : Result:= srkmecEditorBottom;
    ecGotoXY                : Result:= srkmecGotoXY;
    ecSelLeft               : Result:= srkmecSelLeft;
    ecSelRight              : Result:= srkmecSelRight;
    ecSelUp                 : Result:= srkmecSelUp;
    ecSelDown               : Result:= srkmecSelDown;
    ecSelWordLeft           : Result:= srkmecSelWordLeft;
    ecSelWordRight          : Result:= srkmecSelWordRight;
    ecSelLineStart          : Result:= srkmecSelLineStart;
    ecSelLineEnd            : Result:= srkmecSelLineEnd;
    ecSelPageUp             : Result:= srkmecSelPageUp;
    ecSelPageDown           : Result:= srkmecSelPageDown;
    ecSelPageLeft           : Result:= srkmecSelPageLeft;
    ecSelPageRight          : Result:= srkmecSelPageRight;
    ecSelPageTop            : Result:= srkmecSelPageTop;
    ecSelPageBottom         : Result:= srkmecSelPageBottom;
    ecSelEditorTop          : Result:= srkmecSelEditorTop;
    ecSelEditorBottom       : Result:= srkmecSelEditorBottom;
    ecSelGotoXY             : Result:= srkmecSelGotoXY;
    ecSelectAll             : Result:= srkmecSelectAll;
    ecDeleteLastChar        : Result:= srkmecDeleteLastChar;
    ecDeleteChar            : Result:= srkmecDeleteChar;
    ecDeleteWord            : Result:= srkmecDeleteWord;
    ecDeleteLastWord        : Result:= srkmecDeleteLastWord;
    ecDeleteBOL             : Result:= srkmecDeleteBOL;
    ecDeleteEOL             : Result:= srkmecDeleteEOL;
    ecDeleteLine            : Result:= srkmecDeleteLine;
    ecClearAll              : Result:= srkmecClearAll;
    ecLineBreak             : Result:= srkmecLineBreak;
    ecInsertLine            : Result:= srkmecInsertLine;
    ecChar                  : Result:= srkmecChar;
    ecImeStr                : Result:= srkmecImeStr;
    ecUndo                  : Result:= lisMenuUndo;
    ecRedo                  : Result:= lisMenuRedo;
    ecCut                   : Result:= srkmecCut;
    ecCopy                  : Result:= srkmecCopy;
    ecPaste                 : Result:= srkmecPaste;
    ecScrollUp              : Result:= srkmecScrollUp;
    ecScrollDown            : Result:= srkmecScrollDown;
    ecScrollLeft            : Result:= srkmecScrollLeft;
    ecScrollRight           : Result:= srkmecScrollRight;
    ecInsertMode            : Result:= srkmecInsertMode;
    ecOverwriteMode         : Result:= srkmecOverwriteMode;
    ecToggleMode            : Result:= srkmecToggleMode;
    ecBlockIndent           : Result:= srkmecBlockIndent;
    ecBlockUnindent         : Result:= srkmecBlockUnindent;
    ecTab                   : Result:= srVK_TAB;
    ecShiftTab              : Result:= srkmecShiftTab;
    ecMatchBracket          : Result:= srkmecMatchBracket;
    ecNormalSelect          : Result:= srkmecNormalSelect;
    ecColumnSelect          : Result:= srkmecColumnSelect;
    ecLineSelect            : Result:= srkmecLineSelect;
    ecAutoCompletion        : Result:= srkmecAutoCompletion;
    ecUserFirst             : Result:= srkmecUserFirst;
    ecGotoMarker0 ..
    ecGotoMarker9           : Result:= Format(srkmecGotoMarker,[cmd-ecGotoMarker0]);
    ecSetMarker0 ..
    ecSetMarker9            : Result:= Format(srkmecSetMarker,[cmd-ecSetMarker0]);
    ecPeriod                : Result:= srkmecPeriod;

    // sourcenotebook
    ecJumpToEditor          : Result:= srkmecJumpToEditor;
    ecNextEditor            : Result:= srkmecNextEditor;
    ecPrevEditor            : Result:= srkmecPrevEditor;
    ecMoveEditorLeft        : Result:= srkmecMoveEditorLeft;
    ecMoveEditorRight       : Result:= srkmecMoveEditorRight;
    ecGotoEditor1..
    ecGotoEditor0           : Result:= Format(srkmecGotoEditor,[cmd-ecGotoEditor1]);

    // file menu
    ecNew                   : Result:= srkmecNew;
    ecNewUnit               : Result:= srkmecNewUnit;
    ecNewForm               : Result:= srkmecNewForm;
    ecOpen                  : Result:= lisMenuOpen;
    ecRevert                : Result:= lisMenuRevert;
    ecSave                  : Result:= lisMenuSave;
    ecSaveAs                : Result:= srkmecSaveAs;
    ecSaveAll               : Result:= srkmecSaveAll;
    ecClose                 : Result:= lismenuclose;
    ecCloseAll              : Result:= srkmecCloseAll;
    ecCleanDirectory        : Result:= lisMenuCleanDirectory;
    ecQuit                  : Result:= lismenuquit;
    
    // edit menu
    ecSelectionUpperCase    : Result:= lismenuuppercaseselection;
    ecSelectionLowerCase    : Result:= lismenulowercaseselection;
    ecSelectionTabs2Spaces  : Result:= srkmecSelectionTabs2Spaces;
    ecSelectionEnclose      : Result:= lismenucommentselection;
    ecSelectionComment      : Result:= lismenucommentselection;
    ecSelectionUncomment    : Result:= lismenuuncommentselection;
    ecSelectionSort         : Result:= lismenusortselection;
    ecSelectionBreakLines   : Result:= lismenusortselection;
    ecSelectToBrace         : Result:= lismenuselecttobrace;
    ecSelectCodeBlock       : Result:= lismenuselectcodeblock;
    ecSelectLine            : Result:= lismenuselectline;
    ecSelectParagraph       : Result:= lismenuselectparagraph;
    ecInsertCharacter       : Result:= srkmecInsertCharacter;
    ecInsertGPLNotice       : Result:= srkmecInsertGPLNotice;
    ecInsertLGPLNotice      : Result:= srkmecInsertLGPLNotice;
    ecInsertUserName        : Result:= srkmecInsertUserName;
    ecInsertDateTime        : Result:= srkmecInsertDateTime;
    ecInsertChangeLogEntry  : Result:= srkmecInsertChangeLogEntry;
    ecInsertCVSAuthor       : Result:= srkmecInsertCVSAuthor;
    ecInsertCVSDate         : Result:= srkmecInsertCVSDate;
    ecInsertCVSHeader       : Result:= srkmecInsertCVSHeader;
    ecInsertCVSID           : Result:= srkmecInsertCVSID;
    ecInsertCVSLog          : Result:= srkmecInsertCVSLog;
    ecInsertCVSName         : Result:= srkmecInsertCVSName;
    ecInsertCVSRevision     : Result:= srkmecInsertCVSRevision;
    ecInsertCVSSource       : Result:= srkmecInsertCVSSource;

    // search menu
    ecFind                  : Result:= srkmecFind;
    ecFindNext              : Result:= srkmecFindNext;
    ecFindPrevious          : Result:= srkmecFindPrevious;
    ecFindInFiles           : Result:= srkmecFindInFiles;
    ecReplace               : Result:= srkmecReplace;
    ecIncrementalFind       : Result:= lismenuincrementalfind;
    ecFindProcedureDefinition:Result:= srkmecFindProcedureDefinition;
    ecFindProcedureMethod   : Result:= srkmecFindProcedureMethod;
    ecGotoLineNumber        : Result:= srkmecGotoLineNumber;
    ecJumpBack              : Result:= lismenujumpback;
    ecJumpForward           : Result:= lismenujumpforward;
    ecAddJumpPoint          : Result:= srkmecAddJumpPoint;
    ecViewJumpHistory       : Result:= lismenuviewjumphistory;
    ecOpenFileAtCursor      : Result:= srkmecOpenFileAtCursor;
    ecGotoIncludeDirective  : Result:= srkmecGotoIncludeDirective;

    // view menu
    ecToggleFormUnit        : Result:= srkmecToggleFormUnit;
    ecToggleObjectInsp      : Result:= srkmecToggleObjectInsp;
    ecToggleSourceEditor    : Result:= srkmecToggleSourceEditor;
    ecToggleCodeExpl        : Result:= srkmecToggleCodeExpl;
    ecToggleMessages        : Result:= srkmecToggleMessages;
    ecToggleSearchResults   : Result:= srkmecToggleSearchResults;
    ecToggleWatches         : Result:= srkmecToggleWatches;
    ecToggleBreakPoints     : Result:= srkmecToggleBreakPoints;
    ecToggleDebuggerOut     : Result:= srkmecToggleDebuggerOut;
    ecToggleLocals          : Result:= srkmecToggleLocals;
    ecToggleCallStack       : Result:= srkmecToggleCallStack;
    ecViewUnits             : Result:= srkmecViewUnits;
    ecViewForms             : Result:= srkmecViewForms;
    ecViewUnitDependencies  : Result:= srkmecViewUnitDependencies;

    // codetools
    ecWordCompletion        : Result:= srkmecWordCompletion;
    ecCompleteCode          : Result:= srkmecCompleteCode;
    ecIdentCompletion       : Result:= dlgedidcomlet;
    ecExtractProc           : Result:= srkmecExtractProc;
    ecSyntaxCheck           : Result:= srkmecSyntaxCheck;
    ecGuessUnclosedBlock    : Result:= lismenuguessunclosedblock;
    ecGuessMisplacedIFDEF   : Result:= srkmecGuessMisplacedIFDEF;
    ecConvertDFM2LFM        : Result:= lismenuConvertDFMToLFM;
    ecCheckLFM              : Result:= lisMenuCheckLFM;
    ecConvertDelphiUnit     : Result:= lisMenuConvertDelphiUnit;
    ecFindDeclaration       : Result:= srkmecFindDeclaration;
    ecFindBlockOtherEnd     : Result:= srkmecFindBlockOtherEnd;
    ecFindBlockStart        : Result:= srkmecFindBlockStart;

    // project (menu string resource)
    ecNewProject            : Result:= lisMenuNewProject;
    ecNewProjectFromFile    : Result:= lisMenuNewProjectFromFile;
    ecOpenProject           : Result:= lisMenuOpenProject;
    ecSaveProject           : Result:= lisMenuSaveProject;
    ecSaveProjectAs         : Result:= lisMenuSaveProjectAs;
    ecPublishProject        : Result:= lisMenuPublishProject;
    ecProjectInspector      : Result:= lisMenuProjectInspector;
    ecAddCurUnitToProj      : Result:= lisMenuAddToProject;
    ecRemoveFromProj        : Result:= lisMenuRemoveFromProject;
    ecViewProjectSource     : Result:= lisMenuViewSource;
    ecViewProjectTodos      : Result:= lisMenuViewProjectTodos;
    ecProjectOptions        : Result:= lisMenuProjectOptions;

    // run menu (menu string resource)
    ecBuild                 : Result:= srkmecBuild;
    ecBuildAll              : Result:= srkmecBuildAll;
    ecAbortBuild            : Result:= srkmecAbortBuild;
    ecRun                   : Result:= srkmecRun;
    ecPause                 : Result:= srkmecPause;
    ecStepInto              : Result:= lisMenuStepInto;
    ecStepOver              : Result:= lisMenuStepOver;
    ecRunToCursor           : Result:= lisMenuRunToCursor;
    ecStopProgram           : Result:= srkmecStopProgram;
    ecResetDebugger         : Result:= srkmecResetDebugger;
    ecRunParameters         : Result:= srkmecRunParameters;
    ecCompilerOptions       : Result:= srkmecCompilerOptions;
    ecBuildFile             : Result:= srkmecBuildFile;
    ecRunFile               : Result:= srkmecRunFile;
    ecConfigBuildFile       : Result:= srkmecConfigBuildFile;

    // components menu
    ecOpenPackage           : Result:= lisMenuOpenPackage;
    ecOpenPackageFile       : Result:= lisMenuOpenPackageFile;
    ecAddCurUnitToPkg       : Result:= lisMenuAddCurUnitToPkg;
    ecPackageGraph          : Result:= lisMenuPackageGraph;
    ecConfigCustomComps     : Result:= lisMenuConfigCustomComps;

    // tools menu
    ecExtToolSettings       : Result:= srkmecExtToolSettings;
    ecConfigBuildLazarus    : Result:= lismenuconfigurebuildlazarus;
    ecBuildLazarus          : Result:= srkmecBuildLazarus;
    ecExtToolFirst
    ..ecExtToolLast         : Result:= Format(srkmecExtTool,[cmd-ecExtToolFirst+1]);
    ecMakeResourceString    : Result:= srkmecMakeResourceString;
    ecDiff                  : Result:= srkmecDiff;
    ecCustomToolFirst
    ..ecCustomToolLast      : Result:= Format(srkmecCustomTool,[cmd-ecCustomToolFirst+1]);

    // environment menu
    ecEnvironmentOptions    : Result:= srkmecEnvironmentOptions;
    ecEditorOptions         : Result:= lismenueditoroptions;
    ecCodeToolsOptions      : Result:= srkmecCodeToolsOptions;
    ecCodeToolsDefinesEd    : Result:= srkmecCodeToolsDefinesEd;
    ecRescanFPCSrcDir       : Result:= lisMenuRescanFPCSourceDirectory;

    // help menu
    ecAboutLazarus          : Result:= lisMenuAboutLazarus;
    
    // desginer
    ecCopyComponents        : Result:= lisDsgCopyComponents;
    ecCutComponents         : Result:= lisDsgCutComponents;
    ecPasteComponents       : Result:= lisDsgPasteComponents;
    ecSelectParentComponent : Result:= lisDsgSelectParentComponent;

    else
      Result:= srkmecunknown;
  end;
end;

function KeyStrokesConsistencyErrors(ASynEditKeyStrokes:TSynEditKeyStrokes;
   Protocol: TStrings; var Index1,Index2:integer):integer;
// 0 = ok, no errors
// >0 number of errors found
var a,b:integer;
  Key1,Key2:TSynEditKeyStroke;
begin
  Result:=0;
  for a:=0 to ASynEditKeyStrokes.Count-1 do begin
    Key1:=ASynEditKeyStrokes[a];
    for b:=a+1 to ASynEditKeyStrokes.Count-1 do begin
      Key2:=ASynEditKeyStrokes[b];
      if (Key1.Key=VK_UNKNOWN)
      or (Key1.Command=Key2.Command)
      then
        continue;
      if ((Key1.Key=Key2.Key) and (Key1.Shift=Key2.Shift))
      and ((Key1.Key2=Key2.Key2) and (Key1.Shift2=Key2.Shift2))
      then begin
        // consistency error
        if Result=0 then begin
          Index1:=a;
          Index2:=b;
        end;
        inc(Result);
        if Protocol<>nil then
        begin
          Protocol.Add(srkmConflic+IntToStr(Result));
          Protocol.Add(srkmCommand1
            +EditorCommandToDescriptionString(Key1.Command)+'"'
            +'->'+KeyAndShiftStateToEditorKeyString(Key1.Key,Key1.Shift));
          Protocol.Add(srkmConflicW);
          Protocol.Add(srkmCommand2
            +EditorCommandToDescriptionString(Key2.Command)+'"'
            +'->'+KeyAndShiftStateToEditorKeyString(Key2.Key,Key2.Shift)
           );
          Protocol.Add('');
        end;
      end;
    end;
  end;
end;

function KeyAndShiftStateToEditorKeyString(Key:Word; ShiftState:TShiftState):AnsiString;
var
  p, ResultLen: integer;

  procedure AddStr(const s: string);
  var
    OldP: integer;
  begin
    if s<>'' then begin
      OldP:=p;
      inc(p,length(s));
      if p<=ResultLen then
        Move(s[1],Result[OldP+1],length(s));
    end;
  end;

  procedure AddAttribute(const s: string);
  begin
    if p>0 then
      AddStr('+');
    AddStr(s);
  end;
  
  procedure AddAttributes;
  begin
    if ssCtrl in ShiftState then AddAttribute('Ctrl');
    if ssAlt in ShiftState then AddAttribute('Alt');
    if ssShift in ShiftState then AddAttribute('Shift');
  end;
  
  // Tricky routine. This only works for western languages
  // TODO: This should be replaces by the winapi VKtoChar functions
  //
  procedure AddKey;
  begin
    if p>0 then  AddStr(' ');
    
    case Key of
      VK_UNKNOWN    :AddStr(srVK_UNKNOWN);
      VK_LBUTTON    :AddStr(srVK_LBUTTON);
      VK_RBUTTON    :AddStr(srVK_RBUTTON);
      VK_CANCEL     :AddStr(dlgCancel);
      VK_MBUTTON    :AddStr(srVK_MBUTTON);
      VK_BACK       :AddStr(srVK_BACK);
      VK_TAB        :AddStr(srVK_TAB);
      VK_CLEAR      :AddStr(srVK_CLEAR);
      VK_RETURN     :AddStr(srVK_RETURN);
      VK_SHIFT      :AddStr(srVK_SHIFT);
      VK_CONTROL    :AddStr(srVK_CONTROL);
      VK_MENU       :AddStr(srVK_MENU);
      VK_PAUSE      :AddStr(srVK_PAUSE);
      VK_CAPITAL    :AddStr(srVK_CAPITAL);
      VK_KANA       :AddStr(srVK_KANA);
    //  VK_HANGUL     :AddStr('Hangul');
      VK_JUNJA      :AddStr(srVK_JUNJA);
      VK_FINAL      :AddStr(srVK_FINAL);
      VK_HANJA      :AddStr(srVK_HANJA );
    //  VK_KANJI      :AddStr('Kanji');
      VK_ESCAPE     :AddStr(srVK_ESCAPE);
      VK_CONVERT    :AddStr(srVK_CONVERT);
      VK_NONCONVERT :AddStr(srVK_NONCONVERT);
      VK_ACCEPT     :AddStr(srVK_ACCEPT);
      VK_MODECHANGE :AddStr(srVK_MODECHANGE);
      VK_SPACE      :AddStr(srVK_SPACE);
      VK_PRIOR      :AddStr(srVK_PRIOR);
      VK_NEXT       :AddStr(srVK_NEXT);
      VK_END        :AddStr(srVK_END);
      VK_HOME       :AddStr(srVK_HOME);
      VK_LEFT       :AddStr(srVK_LEFT);
      VK_UP         :AddStr(srVK_UP);
      VK_RIGHT      :AddStr(srVK_RIGHT);
      VK_DOWN       :AddStr(dlgdownword);
      VK_SELECT     :AddStr(lismenuselect);
      VK_PRINT      :AddStr(srVK_PRINT);
      VK_EXECUTE    :AddStr(srVK_EXECUTE);
      VK_SNAPSHOT   :AddStr(srVK_SNAPSHOT);
      VK_INSERT     :AddStr(srVK_INSERT);
      VK_DELETE     :AddStr(dlgeddelete);
      VK_HELP       :AddStr(srVK_HELP);
      VK_0..VK_9    :AddStr(IntToStr(Key-VK_0));
      VK_A..VK_Z    :AddStr(chr(ord('A')+Key-VK_A));
      VK_LWIN       :AddStr(srVK_LWIN);
      VK_RWIN       :AddStr(srVK_RWIN);
      VK_APPS       :AddStr(srVK_APPS);
      VK_NUMPAD0..VK_NUMPAD9:  AddStr(Format(srVK_NUMPAD,[Key-VK_NUMPAD0]));
      VK_MULTIPLY   :AddStr('*');
      VK_ADD        :AddStr('+');
      VK_SEPARATOR  :AddStr('|');
      VK_SUBTRACT   :AddStr('-');
      VK_DECIMAL    :AddStr('.');
      VK_DIVIDE     :AddStr('/');
      VK_F1..VK_F24 : AddStr('F'+IntToStr(Key-VK_F1+1));
      VK_NUMLOCK    :AddStr(srVK_NUMLOCK);
      VK_SCROLL     :AddStr(srVK_SCROLL);
//    VK_EQUAL      :AddStr('=');
//    VK_COMMA      :AddStr(',');
//    VK_POINT      :AddStr('.');
//    VK_SLASH      :AddStr('/');
//    VK_AT         :AddStr('@');
    else
      AddStr(UnknownVKPrefix);
      AddStr(IntToStr(Key));
      AddStr(UnknownVKPostfix);
    end;
  end;
  
  procedure AddAttributesAndKey;
  begin
    AddAttributes;
    AddKey;
  end;

begin
  ResultLen:=0;
  p:=0;
  AddAttributesAndKey;
  ResultLen:=p;
  SetLength(Result,ResultLen);
  p:=0;
  AddAttributesAndKey;
end;

{ TKeyMappingEditForm }

constructor TKeyMappingEditForm.Create(TheOwner:TComponent);
var a: word;
  s:AnsiString;
begin
  inherited Create(TheOwner);
  if LazarusResources.Find(ClassName)=nil then
  begin
    SetBounds((Screen.Width-200) div 2,(Screen.Height-270) div 2,216,310);
    Caption:=srkmEditForCmd;
    OnKeyUp:=@FormKeyUp;

    OkButton:=TButton.Create(Self);
    with OkButton do begin
      Name:='OkButton';
      Parent:=Self;
      Caption:='Ok';
      Left:=15;
      Top:=Self.ClientHeight-Height-15;
      Width:=80;
      OnClick:=@OkButtonClick;
    end;

    CancelButton:=TButton.Create(Self);
    with CancelButton do begin
      Name:='CancelButton';
      Parent:=Self;
      Caption:=dlgCancel;
      Left:=125;
      Top:=OkButton.Top;
      Width:=OkButton.Width;
      OnClick:=@CancelButtonClick;
    end;

    CommandLabel:=TLabel.Create(Self);
    with CommandLabel do begin
      Name:='CommandLabel';
      Parent:=Self;
      Caption:=srkmCommand;
      Left:=5;
      Top:=5;
      Width:=Self.ClientWidth-Left-Left;
      Height:=20;
    end;

    Key1GroupBox:=TGroupBox.Create(Self);
    with Key1GroupBox do begin
      Name:='Key1GroupBox';
      Parent:=Self;
      Caption:=srkmKey;
      Left:=5;
      Top:=CommandLabel.Top+CommandLabel.Height+8;
      Width:=Self.ClientWidth-Left-Left;
      Height:=110;
    end;

    Key1CtrlCheckBox:=TCheckBox.Create(Self);
    with Key1CtrlCheckBox do begin
      Name:='Key1CtrlCheckBox';
      Parent:=Key1GroupBox;
      Caption:='Ctrl';
      Left:=5;
      Top:=2;
      Width:=55;
      Height:=20;
    end;

    Key1AltCheckBox:=TCheckBox.Create(Self);
    with Key1AltCheckBox do begin
      Name:='Key1AltCheckBox';
      Parent:=Key1GroupBox;
      Caption:='Alt';
      Left:=Key1CtrlCheckBox.Left+Key1CtrlCheckBox.Width+10;
      Top:=Key1CtrlCheckBox.Top;
      Height:=20;
      Width:=Key1CtrlCheckBox.Width;
    end;

    Key1ShiftCheckBox:=TCheckBox.Create(Self);
    with Key1ShiftCheckBox do begin
      Name:='Key1ShiftCheckBox';
      Parent:=Key1GroupBox;
      Caption:='Shift';
      Left:=Key1AltCheckBox.Left+Key1AltCheckBox.Width+10;
      Top:=Key1CtrlCheckBox.Top;
      Height:=20;
      Width:=Key1CtrlCheckBox.Width;
    end;

    Key1KeyComboBox:=TComboBox.Create(Self);
    with Key1KeyComboBox do begin
      Name:='Key1KeyComboBox';
      Parent:=Key1GroupBox;
      Left:=5;
      Top:=Key1CtrlCheckBox.Top+Key1CtrlCheckBox.Height+5;
      Width:=190;
      Items.BeginUpdate;
      Items.Add('none');
      for a:=1 to 145 do begin
        s:=KeyAndShiftStateToEditorKeyString(a,[]);
        if not EditorKeyStringIsIrregular(s) then
          Items.Add(s);
      end;
      Items.EndUpdate;
      ItemIndex:=0;
    end;
    
    Key1GrabButton:=TButton.Create(Self);
    with Key1GrabButton do begin
      Parent:=Key1GroupBox;
      Left:=5;
      Top:=Key1KeyComboBox.Top+Key1KeyComboBox.Height+5;
      Width:=Key1KeyComboBox.Width;
      Height:=25;
      Caption:=srkmGrabKey;
      Name:='Key1GrabButton';
      OnClick:=@Key1GrabButtonClick;
    end;

    Key2GroupBox:=TGroupBox.Create(Self);
    with Key2GroupBox do begin
      Name:='Key2GroupBox';
      Parent:=Self;
      Caption:=srkmAlternKey;
      Left:=5;
      Top:=Key1GroupBox.Top+Key1GroupBox.Height+8;
      Width:=Key1GroupBox.Width;
      Height:=110;
    end;

    Key2CtrlCheckBox:=TCheckBox.Create(Self);
    with Key2CtrlCheckBox do begin
      Name:='Key2CtrlCheckBox';
      Parent:=Key2GroupBox;
      Caption:='Ctrl';
      Left:=5;
      Top:=2;
      Width:=55;
      Height:=20;
    end;

    Key2AltCheckBox:=TCheckBox.Create(Self);
    with Key2AltCheckBox do begin
      Name:='Key2AltCheckBox';
      Parent:=Key2GroupBox;
      Caption:='Alt';
      Left:=Key2CtrlCheckBox.Left+Key2CtrlCheckBox.Width+10;
      Top:=Key2CtrlCheckBox.Top;
      Height:=20;
      Width:=Key2CtrlCheckBox.Width;
    end;

    Key2ShiftCheckBox:=TCheckBox.Create(Self);
    with Key2ShiftCheckBox do begin
      Name:='Key2ShiftCheckBox';
      Parent:=Key2GroupBox;
      Caption:='Shift';
      Left:=Key2AltCheckBox.Left+Key2AltCheckBox.Width+10;
      Top:=Key2CtrlCheckBox.Top;
      Height:=20;
      Width:=Key2CtrlCheckBox.Width;
    end;

    Key2KeyComboBox:=TComboBox.Create(Self);
    with Key2KeyComboBox do begin
      Name:='Key2KeyComboBox';
      Parent:=Key2GroupBox;
      Left:=5;
      Top:=Key2CtrlCheckBox.Top+Key2CtrlCheckBox.Height+5;
      Width:=190;
      Items.BeginUpdate;
      Items.Add('none');
      for a:=1 to 145 do begin
        s:=KeyAndShiftStateToEditorKeyString(a,[]);
        if not EditorKeyStringIsIrregular(s) then
          Items.Add(s);
      end;
      Items.EndUpdate;
      ItemIndex:=0;
    end;
    
    Key2GrabButton:=TButton.Create(Self);
    with Key2GrabButton do begin
      Parent:=Key2GroupBox;
      Left:=5;
      Top:=Key2KeyComboBox.Top+Key2KeyComboBox.Height+5;
      Width:=Key2KeyComboBox.Width;
      Height:=25;
      Caption:=srkmGrabKey;
      Name:='Key2GrabButton';
      OnClick:=@Key2GrabButtonClick;
    end;

  end;
  GrabbingKey:=0;
end;

procedure TKeyMappingEditForm.OkButtonClick(Sender:TObject);
var NewKey1,NewKey2:word;
  NewShiftState1,NewShiftState2:TShiftState;
  AText:AnsiString;
  DummyRelation, CurRelation:TKeyCommandRelation;
begin
  // set defaults
  NewKey1:=VK_UNKNOWN;
  NewShiftState1:=[];
  NewKey2:=VK_UNKNOWN;
  NewShiftState2:=[];
  
  // get settings for key1
  NewKey1:=EditorKeyStringToVKCode(Key1KeyComboBox.Text);
  if NewKey1<>VK_UNKNOWN then
  begin
    if Key1CtrlCheckBox.Checked then include(NewShiftState1,ssCtrl);
    if Key1AltCheckBox.Checked then include(NewShiftState1,ssAlt);
    if Key1ShiftCheckBox.Checked then include(NewShiftState1,ssShift);
  end;

  // get old relation
  CurRelation:=KeyCommandRelationList.Relations[KeyIndex];
  
  // search for conflict
  DummyRelation:=KeyCommandRelationList.Find(NewKey1,NewShiftState1,
                                                    CurRelation.Category.Areas);
  if (DummyRelation<>nil) 
  and (DummyRelation<>KeyCommandRelationList.Relations[KeyIndex]) then
  begin
    AText:=Format(srkmAlreadyConnected,
            [KeyAndShiftStateToEditorKeyString(NewKey1,NewShiftState1),
            DummyRelation.Name]);
    MessageDlg(AText,mtError,[mbok],0);
    exit;
  end;

  NewKey2:=EditorKeyStringToVKCode(Key2KeyComboBox.Text);
  if (NewKey1=NewKey2) and (NewShiftState1=NewShiftState2) then
    NewKey2:=VK_UNKNOWN;
  if NewKey2<>VK_UNKNOWN then
  begin
    if Key2CtrlCheckBox.Checked then include(NewShiftState2,ssCtrl);
    if Key2AltCheckBox.Checked then include(NewShiftState2,ssAlt);
    if Key2ShiftCheckBox.Checked then include(NewShiftState2,ssShift);
  end;
  DummyRelation:=KeyCommandRelationList.Find(NewKey2,NewShiftState2,
                                             CurRelation.Category.Areas);
  
  if (DummyRelation<>nil)
  and (DummyRelation<>KeyCommandRelationList.Relations[KeyIndex]) then
  begin
    AText:=Format(srkmAlreadyConnected,
            [KeyAndShiftStateToEditorKeyString(NewKey2,NewShiftState2),
            DummyRelation.Name]);
    MessageDlg(AText,mterror,[mbok],0);
    exit;
  end;

  if NewKey1=VK_UNKNOWN then
  begin
    NewKey1:=NewKey2;
    NewShiftState1:=NewShiftState2;
    NewKey2:=VK_UNKNOWN;
  end;

  CurRelation.KeyA:=IDEShortCut(NewKey1,NewShiftState1,VK_UNKNOWN,[]);
  CurRelation.KeyB:=IDEShortCut(NewKey2,NewShiftState2,VK_UNKNOWN,[]);
  ModalResult:=mrOk;
end;

procedure TKeyMappingEditForm.CancelButtonClick(Sender:TObject);
begin
  ModalResult:=mrCancel;
end;

procedure TKeyMappingEditForm.Key1GrabButtonClick(Sender: TObject);
begin
  ActivateGrabbing(1);
end;

procedure TKeyMappingEditForm.Key2GrabButtonClick(Sender: TObject);
begin
  ActivateGrabbing(2);
end;

procedure TKeyMappingEditForm.DeactivateGrabbing;
var i: integer;
begin
  if GrabbingKey=0 then exit;
  // enable all components
  for i:=0 to ComponentCount-1 do
  begin
    if (Components[i] is TWinControl) then
      TWinControl(Components[i]).Enabled:=true;
  end;
  
  if GrabbingKey=1 then
    Key1GrabButton.Caption:=srkmGrabKey
  else if GrabbingKey=2 then
           Key2GrabButton.Caption:=srkmGrabKey;
  GrabbingKey:=0;
end;

procedure TKeyMappingEditForm.SetComboBox(AComboBox: TComboBox; AValue: string);
var i: integer;
begin
  i:=AComboBox.Items.IndexOf(AValue);
  if i>=0 then
    AComboBox.ItemIndex:=i
  else
  begin
    AComboBox.Items.Add(AValue);
    AComboBox.ItemIndex:=AComboBox.Items.IndexOf(AValue);
  end;
end;

procedure TKeyMappingEditForm.ActivateGrabbing(AGrabbingKey: integer);
var i: integer;
begin
  if GrabbingKey>0 then exit;
  GrabbingKey:=AGrabbingKey;
  if GrabbingKey=0 then exit;
  // disable all components
  for i:=0 to ComponentCount-1 do
  begin
    if (Components[i] is TWinControl) then
    begin
      if ((GrabbingKey=1) and (Components[i]<>Key1GrabButton)
         and (Components[i]<>Key1GroupBox))
         or ((GrabbingKey=2) and (Components[i]<>Key2GrabButton)
         and (Components[i]<>Key2GroupBox)) then
                   TWinControl(Components[i]).Enabled:=false;
    end;
  end;
  if GrabbingKey=1 then
    Key1GrabButton.Caption:=srkmPressKey
  else if GrabbingKey=2 then
           Key2GrabButton.Caption:=srkmPressKey;
end;

procedure TKeyMappingEditForm.FormKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  {writeln('TKeyMappingEditForm.FormKeyUp Sender=',Classname
     ,' Key=',Key,' Ctrl=',ssCtrl in Shift,' Shift=',ssShift in Shift
     ,' Alt=',ssAlt in Shift,' AsString=',KeyAndShiftStateToEditorKeyString(Key,Shift),
     ' LCL-Name=',ShortCutToText(ShortCut(Key,Shift))
     );}
  if Key in [VK_CONTROL, VK_SHIFT, VK_LCONTROL, VK_RCONTROl,
             VK_LSHIFT, VK_RSHIFT] then exit;
  if (GrabbingKey in [1,2]) then
  begin
    if GrabbingKey=1 then
    begin
      Key1CtrlCheckBox.Checked:=(ssCtrl in Shift);
      Key1ShiftCheckBox.Checked:=(ssShift in Shift);
      Key1AltCheckBox.Checked:=(ssAlt in Shift);
      SetComboBox(Key1KeyComboBox,KeyAndShiftStateToEditorKeyString(Key,[]));
    end
    else if GrabbingKey=2 then
    begin
      Key2CtrlCheckBox.Checked:=(ssCtrl in Shift);
      Key2ShiftCheckBox.Checked:=(ssShift in Shift);
      Key2AltCheckBox.Checked:=(ssAlt in Shift);
      SetComboBox(Key2KeyComboBox,KeyAndShiftStateToEditorKeyString(Key,[]));
    end;
    Key:=0;
    DeactivateGrabbing;
  end;
end;


{ TKeyCommandRelation }

function TKeyCommandRelation.GetLocalizedName: string;
begin
  Result:=EditorCommandLocalizedName(Command,Name);
end;

{ TKeyCommandRelationList }

constructor TKeyCommandRelationList.Create;
begin
  inherited Create;
  FRelations:=TList.Create;
  fCategories:=TList.Create;
  fExtToolCount:=0;
end;

destructor TKeyCommandRelationList.Destroy;
begin
  Clear;
  FRelations.Free;
  fCategories.Free;
  inherited Destroy;
end;

procedure TKeyCommandRelationList.CreateDefaultMapping;
var
  C: TKeyCommandCategory;
begin
  Clear;
  
  // create default keymapping

  // moving
  C:=Categories[AddCategory('CursorMoving',srkmCatCursorMoving,caSrcEditOnly)];
  AddDefault(C,'Move cursor word left',ecWordLeft);
  AddDefault(C,'Move cursor word right',ecWordRight);
  AddDefault(C,'Move cursor to line start',ecLineStart);
  AddDefault(C,'Move cursor to line end',ecLineEnd);
  AddDefault(C,'Move cursor up one page',ecPageUp);
  AddDefault(C,'Move cursor down one page',ecPageDown);
  AddDefault(C,'Move cursor left one page',ecPageLeft);
  AddDefault(C,'Move cursor right one page',ecPageRight);
  AddDefault(C,'Move cursor to top of page',ecPageTop);
  AddDefault(C,'Move cursor to bottom of page',ecPageBottom);
  AddDefault(C,'Move cursor to absolute beginning',ecEditorTop);
  AddDefault(C,'Move cursor to absolute end',ecEditorBottom);
  AddDefault(C,'Scroll up one line',ecScrollUp);
  AddDefault(C,'Scroll down one line',ecScrollDown);
  AddDefault(C,'Scroll left one char',ecScrollLeft);
  AddDefault(C,'Scroll right one char',ecScrollRight);

  // selection
  C:=Categories[AddCategory('Selection',srkmCatSelection,caSrcEditOnly)];
  AddDefault(C,'Copy selection to clipboard',ecCopy);
  AddDefault(C,'Cut selection to clipboard',ecCut);
  AddDefault(C,'Paste clipboard to current position',ecPaste);
  AddDefault(C,'Normal selection mode',ecNormalSelect);
  AddDefault(C,'Column selection mode',ecColumnSelect);
  AddDefault(C,'Line selection mode',ecLineSelect);
  AddDefault(C,'Select word left',ecSelWordLeft);
  AddDefault(C,'Select word right',ecSelWordRight);
  AddDefault(C,'Select line start',ecSelLineStart);
  AddDefault(C,'Select line end',ecSelLineEnd);
  AddDefault(C,'Select page top',ecSelPageTop);
  AddDefault(C,'Select page bottom',ecSelPageBottom);
  AddDefault(C,'Select to absolute beginning',ecSelEditorTop);
  AddDefault(C,'Select to absolute end',ecSelEditorBottom);
  AddDefault(C,'Select all',ecSelectAll);
  AddDefault(C,'Select to brace',ecSelectToBrace);
  AddDefault(C,'Select code block',ecSelectCodeBlock);
  AddDefault(C,'Select line',ecSelectLine);
  AddDefault(C,'Select paragraph',ecSelectParagraph);
  AddDefault(C,'Uppercase selection',ecSelectionUpperCase);
  AddDefault(C,'Lowercase selection',ecSelectionLowerCase);
  AddDefault(C,'Convert tabs to spaces in selection',ecSelectionTabs2Spaces);
  AddDefault(C,'Enclose selection',ecSelectionEnclose);
  AddDefault(C,'Comment selection',ecSelectionComment);
  AddDefault(C,'Uncomment selection',ecSelectionUncomment);
  AddDefault(C,'Sort selection',ecSelectionSort);
  AddDefault(C,'Break Lines in selection',ecSelectionBreakLines);

  // editing
  C:=Categories[AddCategory('editing commands',srkmCatEditing,caSrcEditOnly)];
  AddDefault(C,'Indent block',ecBlockIndent);
  AddDefault(C,'Unindent block',ecBlockUnindent);
  AddDefault(C,'Delete last char',ecDeleteLastChar);
  AddDefault(C,'Delete char at cursor',ecDeleteChar);
  AddDefault(C,'Delete to end of word',ecDeleteWord);
  AddDefault(C,'Delete to start of word',ecDeleteLastWord);
  AddDefault(C,'Delete to beginning of line',ecDeleteBOL);
  AddDefault(C,'Delete to end of line',ecDeleteEOL);
  AddDefault(C,'Delete current line',ecDeleteLine);
  AddDefault(C,'Delete whole text',ecClearAll);
  AddDefault(C,'Break line and move cursor',ecLineBreak);
  AddDefault(C,'Break line, leave cursor',ecInsertLine);
  AddDefault(C,'Insert from Character Map',ecInsertCharacter);
  AddDefault(C,'Insert GPL notice',ecInsertGPLNotice);
  AddDefault(C,'Insert LGPL notice',ecInsertLGPLNotice);
  AddDefault(C,'Insert username',ecInsertUserName);
  AddDefault(C,'Insert date and time',ecInsertDateTime);
  AddDefault(C,'Insert ChangeLog entry',ecInsertChangeLogEntry);
  AddDefault(C,'Insert CVS keyword Author',ecInsertCVSAuthor);
  AddDefault(C,'Insert CVS keyword Date',ecInsertCVSDate);
  AddDefault(C,'Insert CVS keyword Header',ecInsertCVSHeader);
  AddDefault(C,'Insert CVS keyword ID',ecInsertCVSID);
  AddDefault(C,'Insert CVS keyword Log',ecInsertCVSLog);
  AddDefault(C,'Insert CVS keyword Name',ecInsertCVSName);
  AddDefault(C,'Insert CVS keyword Revision',ecInsertCVSRevision);;
  AddDefault(C,'Insert CVS keyword Source',ecInsertCVSSource);

  // command commands
  C:=Categories[AddCategory('CommandCommands',srkmCatCmdCmd,caAll)];
  AddDefault(C,'Undo',ecUndo);
  AddDefault(C,'Redo',ecRedo);

  // search & replace
  C:=Categories[AddCategory('SearchReplace',srkmCatSearchReplace,caSrcEditOnly)];
  AddDefault(C,'Go to matching bracket',ecMatchBracket);
  AddDefault(C,'Find text',ecFind);
  AddDefault(C,'Find next',ecFindNext);
  AddDefault(C,'Find previous',ecFindPrevious);
  AddDefault(C,'Find in files',ecFindInFiles);
  AddDefault(C,'Replace text',ecReplace);
  AddDefault(C,'Find incremental',ecIncrementalFind);
  AddDefault(C,'Go to line number',ecGotoLineNumber);
  AddDefault(C,'Jump back',ecJumpBack);
  AddDefault(C,'Jump forward',ecJumpForward);
  AddDefault(C,'Add jump point',ecAddJumpPoint);
  AddDefault(C,'View jump history',ecViewJumpHistory);
  AddDefault(C,'Open file at cursor',ecOpenFileAtCursor);

  // marker
  C:=Categories[AddCategory('Marker',srkmCatMarker,caSrcEditOnly)];
  AddDefault(C,'Go to marker 0',ecGotoMarker0);
  AddDefault(C,'Go to marker 1',ecGotoMarker1);
  AddDefault(C,'Go to marker 2',ecGotoMarker2);
  AddDefault(C,'Go to marker 3',ecGotoMarker3);
  AddDefault(C,'Go to marker 4',ecGotoMarker4);
  AddDefault(C,'Go to marker 5',ecGotoMarker5);
  AddDefault(C,'Go to marker 6',ecGotoMarker6);
  AddDefault(C,'Go to marker 7',ecGotoMarker7);
  AddDefault(C,'Go to marker 8',ecGotoMarker8);
  AddDefault(C,'Go to marker 9',ecGotoMarker9);
  AddDefault(C,'Set marker 0',ecSetMarker0);
  AddDefault(C,'Set marker 1',ecSetMarker1);
  AddDefault(C,'Set marker 2',ecSetMarker2);
  AddDefault(C,'Set marker 3',ecSetMarker3);
  AddDefault(C,'Set marker 4',ecSetMarker4);
  AddDefault(C,'Set marker 5',ecSetMarker5);
  AddDefault(C,'Set marker 6',ecSetMarker6);
  AddDefault(C,'Set marker 7',ecSetMarker7);
  AddDefault(C,'Set marker 8',ecSetMarker8);
  AddDefault(C,'Set marker 9',ecSetMarker9);

  // codetools
  C:=Categories[AddCategory('CodeTools',srkmCatCodeTools,caSrcEditOnly)];
  AddDefault(C,'Code template completion',ecAutoCompletion);
  AddDefault(C,'Word completion',ecWordCompletion);
  AddDefault(C,'Complete code',ecCompleteCode);
  AddDefault(C,'Identifier completion',ecIdentCompletion);
  AddDefault(C,'Extract proc',ecExtractProc);
  AddDefault(C,'Syntax check',ecSyntaxCheck);
  AddDefault(C,'Guess unclosed block',ecGuessUnclosedBlock);
  AddDefault(C,'Guess misplaced $IFDEF',ecGuessMisplacedIFDEF);
  AddDefault(C,'Check LFM file in editor',ecCheckLFM);
  AddDefault(C,'Find procedure definiton',ecFindProcedureDefinition);
  AddDefault(C,'Find procedure method',ecFindProcedureMethod);
  AddDefault(C,'Find declaration',ecFindDeclaration);
  AddDefault(C,'Find block other end',ecFindBlockOtherEnd);
  AddDefault(C,'Find block start',ecFindBlockStart);
  AddDefault(C,'Goto include directive',ecGotoIncludeDirective);

  // source notebook
  C:=Categories[AddCategory('SourceNotebook',srkmCatSrcNoteBook,caAll)];
  AddDefault(C,'Go to next editor',ecNextEditor);
  AddDefault(C,'Go to prior editor',ecPrevEditor);
  AddDefault(C,'Go to source editor 1',ecGotoEditor1);
  AddDefault(C,'Go to source editor 2',ecGotoEditor2);
  AddDefault(C,'Go to source editor 3',ecGotoEditor3);
  AddDefault(C,'Go to source editor 4',ecGotoEditor4);
  AddDefault(C,'Go to source editor 5',ecGotoEditor5);
  AddDefault(C,'Go to source editor 6',ecGotoEditor6);
  AddDefault(C,'Go to source editor 7',ecGotoEditor7);
  AddDefault(C,'Go to source editor 8',ecGotoEditor8);
  AddDefault(C,'Go to source editor 9',ecGotoEditor9);
  AddDefault(C,'Go to source editor 10',ecGotoEditor0);
  AddDefault(C,'Move editor left',ecMoveEditorLeft);
  AddDefault(C,'Move editor right',ecMoveEditorRight);

  // file menu
  C:=Categories[AddCategory('FileMenu',srkmCatFileMenu,caAll)];
  AddDefault(C,'New',ecNew);
  AddDefault(C,'NewUnit',ecNewUnit);
  AddDefault(C,'NewForm',ecNewForm);
  AddDefault(C,'Open',ecOpen);
  AddDefault(C,'Revert',ecRevert);
  AddDefault(C,'Save',ecSave);
  AddDefault(C,'SaveAs',ecSaveAs);
  AddDefault(C,'SaveAll',ecSaveAll);
  AddDefault(C,'Close',ecClose);
  AddDefault(C,'CloseAll',ecCloseAll);
  AddDefault(C,'Clean Directory',ecCleanDirectory);
  AddDefault(C,'Quit',ecQuit);

  // view menu
  C:=Categories[AddCategory('ViewMenu',srkmCatViewMenu,caAll)];
  AddDefault(C,'Toggle view Object Inspector',ecToggleObjectInsp);
  AddDefault(C,'Toggle view Source Editor',ecToggleSourceEditor);
  AddDefault(C,'Toggle view Code Explorer',ecToggleCodeExpl);
  AddDefault(C,'Toggle view Messages',ecToggleMessages);
  AddDefault(C,'Toggle view Search Results',ecToggleSearchResults);
  AddDefault(C,'Toggle view Watches',ecToggleWatches);
  AddDefault(C,'Toggle view Breakpoints',ecToggleBreakPoints);
  AddDefault(C,'Toggle view Local Variables',ecToggleLocals);
  AddDefault(C,'Toggle view Call Stack',ecToggleCallStack);
  AddDefault(C,'Toggle view Debugger Output',ecToggleDebuggerOut);
  AddDefault(C,'View Units',ecViewUnits);
  AddDefault(C,'View Forms',ecViewForms);
  AddDefault(C,'View Unit Dependencies',ecViewUnitDependencies);
  AddDefault(C,'Focus to source editor',ecJumpToEditor);
  AddDefault(C,'Toggle between Unit and Form',ecToggleFormUnit);

  // project menu
  C:=Categories[AddCategory('ProjectMenu',srkmCatProjectMenu,caAll)];
  AddDefault(C,'New project',ecNewProject);
  AddDefault(C,'New project from file',ecNewProjectFromFile);
  AddDefault(C,'Open project',ecOpenProject);
  AddDefault(C,'Save project',ecSaveProject);
  AddDefault(C,'Save project as',ecSaveProjectAs);
  AddDefault(C,'Publish project',ecPublishProject);
  AddDefault(C,'Project Inspector',ecProjectInspector);
  AddDefault(C,'Add active unit to project',ecAddCurUnitToProj);
  AddDefault(C,'Remove active unit from project',ecRemoveFromProj);
  AddDefault(C,'View project source',ecViewProjectSource);
  AddDefault(C,'View project ToDo list',ecViewProjectTodos);
  AddDefault(C,'View project options',ecProjectOptions);

  // run menu
  C:=Categories[AddCategory('RunMenu',srkmCatRunMenu,caAll)];
  AddDefault(C,'Build project/program',ecBuild);
  AddDefault(C,'Build all files of project/program',ecBuildAll);
  AddDefault(C,'Abort building',ecAbortBuild);
  AddDefault(C,'Run program',ecRun);
  AddDefault(C,'Pause program',ecPause);
  AddDefault(C,'Step into',ecStepInto);
  AddDefault(C,'Step over',ecStepOver);
  AddDefault(C,'Run to cursor',ecRunToCursor);
  AddDefault(C,'Stop program',ecStopProgram);
  AddDefault(C,'Reset debugger',ecResetDebugger);
  AddDefault(C,'Compiler options',ecCompilerOptions);
  AddDefault(C,'Run parameters',ecRunParameters);
  AddDefault(C,'Build File',ecBuildFile);
  AddDefault(C,'Run File',ecRunFile);
  AddDefault(C,'Config "Build File"',ecConfigBuildFile);

  // components menu
  C:=Categories[AddCategory('Components',srkmCatComponentsMenu,caAll)];
  AddDefault(C,'Open package',ecOpenPackage);
  AddDefault(C,'Open package file',ecOpenPackageFile);
  AddDefault(C,'Add active unit to a package',ecAddCurUnitToPkg);
  AddDefault(C,'Package graph',ecPackageGraph);
  AddDefault(C,'Configure custom components',ecConfigCustomComps);

  // tools menu
  C:=Categories[AddCategory(KeyCategoryToolMenuName,srkmCatToolMenu,caAll)];
  AddDefault(C,'External Tools settings',ecExtToolSettings);
  AddDefault(C,'Build Lazarus',ecBuildLazarus);
  AddDefault(C,'Configure "Build Lazarus"',ecConfigBuildLazarus);
  AddDefault(C,'Make resource string',ecMakeResourceString);
  AddDefault(C,'Diff editor files',ecDiff);
  AddDefault(C,'Convert DFM file to LFM',ecConvertDFM2LFM);
  AddDefault(C,'Convert Delphi unit to lazarus unit',ecConvertDelphiUnit);

  // environment menu
  C:=Categories[AddCategory('EnvironmentMenu',srkmCatEnvMenu,caAll)];
  AddDefault(C,'General environment options',ecEnvironmentOptions);
  AddDefault(C,'Editor options',ecEditorOptions);
  AddDefault(C,'CodeTools options',ecCodeToolsOptions);
  AddDefault(C,'CodeTools defines editor',ecCodeToolsDefinesEd);
  AddDefault(C,'Rescan FPC source directory',ecRescanFPCSrcDir);

  // help menu
  C:=Categories[AddCategory('HelpMenu',srkmCarHelpMenu,caAll)];
  AddDefault(C,'About Lazarus',ecAboutLazarus);

  // designer
  C:=Categories[AddCategory('Designer',lisKeyCatDesigner,caDesignOnly)];
  AddDefault(C,'Copy selected Components to clipboard',ecCopyComponents);
  AddDefault(C,'Cut selected Components to clipboard',ecCutComponents);
  AddDefault(C,'Paste Components from clipboard',ecPasteComponents);
  AddDefault(C,'Select parent component',ecSelectParentComponent);
  
  // custom keys (for experts, task groups, dynamic menu items, etc)
  C:=Categories[AddCategory(KeyCategoryCustomName,lisKeyCatCustom,caAll)];
end;

procedure TKeyCommandRelationList.Clear;
var a:integer;
begin
  for a:=0 to FRelations.Count-1 do
    Relations[a].Free;
  FRelations.Clear;
  for a:=0 to fCategories.Count-1 do
    Categories[a].Free;
  fCategories.Clear;
end;

function TKeyCommandRelationList.GetRelation(
  Index:integer):TKeyCommandRelation;
begin
  if (Index<0) or (Index>=Count) then
  begin
    writeln('[TKeyCommandRelationList.GetRelation] Index out of bounds '
      ,Index,' Count=',Count);
    // creates an exception, that gdb catches:
    if (Index div ((Index and 1) div 10000))=0 then ;
  end;
  Result:= TKeyCommandRelation(FRelations[Index]);
end;

function TKeyCommandRelationList.Count:integer;
begin
  Result:=FRelations.Count;
end;

function TKeyCommandRelationList.Add(Category: TKeyCommandCategory;
  const Name: string;
  Command:word; const TheKeyA, TheKeyB: TIDEShortCut):integer;
begin
  Result:=FRelations.Add(TKeyCommandRelation.Create(Category,Name,Command,
                         TheKeyA,TheKeyB));
end;

function TKeyCommandRelationList.AddDefault(Category: TKeyCommandCategory;
  const Name: string; Command: word): integer;
var
  TheKeyA, TheKeyB: TIDEShortCut;
begin
  GetDefaultKeyForCommand(Command,TheKeyA,TheKeyB);
  Result:=Add(Category,Name,Command,TheKeyA,TheKeyB);
end;

procedure TKeyCommandRelationList.SetCustomKeyCount(const NewCount: integer);
var i: integer;
  CustomCat: TKeyCommandCategory;
  CustomRelation: TKeyCommandRelation;
begin
  if FCustomKeyCount=NewCount then exit;
  CustomCat:=FindCategoryByName(KeyCategoryCustomName);
  if NewCount>FCustomKeyCount then begin
    // increase available custom commands
    while NewCount>FCustomKeyCount do begin
      Add(CustomCat,Format(srkmecCustomTool,[FCustomKeyCount]),
          ecCustomToolFirst+FCustomKeyCount,
          CleanIDEShortCut,CleanIDEShortCut);
      inc(FCustomKeyCount);
    end;
  end else begin
    // decrease available custom commands
    i:=CustomCat.Count-1;
    while (i>=0) and (FCustomKeyCount>NewCount) do begin
      if TObject(CustomCat[i]) is TKeyCommandRelation then begin
        CustomRelation:=TKeyCommandRelation(CustomCat[i]);
        if (CustomRelation.Command>=ecCustomToolFirst)
        and (CustomRelation.Command<=ecCustomToolLast) then begin
          fRelations.Remove(CustomRelation);
          CustomCat.Delete(i);
          dec(FCustomKeyCount);
        end;
      end;
      dec(i);
    end;
  end;
end;

procedure TKeyCommandRelationList.SetExtToolCount(NewCount: integer);
var i: integer;
  ExtToolCat: TKeyCommandCategory;
  ExtToolRelation: TKeyCommandRelation;
begin
  if NewCount=fExtToolCount then exit;
  ExtToolCat:=FindCategoryByName(KeyCategoryToolMenuName);
  if NewCount>fExtToolCount then begin
    // increase available external tool commands
    while NewCount>fExtToolCount do begin
      Add(ExtToolCat,Format(srkmecExtTool,[fExtToolCount]),
           ecExtToolFirst+fExtToolCount,CleanIDEShortCut,CleanIDEShortCut);
      inc(fExtToolCount);
    end;
  end else begin
    // decrease available external tool commands
    // they are always at the end of the Tools menu
    i:=ExtToolCat.Count-1;
    while (i>=0) and (fExtToolCount>NewCount) do begin
      if TObject(ExtToolCat[i]) is TKeyCommandRelation then begin
        ExtToolRelation:=TKeyCommandRelation(ExtToolCat[i]);
        if (ExtToolRelation.Command>=ecExtToolFirst)
        and (ExtToolRelation.Command<=ecExtToolLast) then begin
          fRelations.Remove(ExtToolRelation);
          ExtToolCat.Delete(i);
          dec(fExtToolCount);
        end;
      end;
      dec(i);
    end;
  end;
end;

function TKeyCommandRelationList.LoadFromXMLConfig(
  XMLConfig:TXMLConfig; const Prefix: String):boolean;
var a,b,p:integer;
  Name:ShortString;
  DefaultStr,NewValue: String;

  function ReadNextInt:integer;
  begin
    Result:=0;
    while (p<=length(NewValue)) and (not (NewValue[p] in ['0'..'9']))
      do inc(p);
    while (p<=length(NewValue)) and (NewValue[p] in ['0'..'9']) 
    and (Result<$10000)do begin
      Result:=Result*10+ord(NewValue[p])-ord('0');
      inc(p);
    end;
  end;

  function IntToShiftState(i:integer):TShiftState;
  begin
    Result:=[];
    if (i and 1)>0 then Include(Result,ssCtrl);
    if (i and 2)>0 then Include(Result,ssShift);
    if (i and 4)>0 then Include(Result,ssAlt);
  end;

// LoadFromXMLConfig
var
  FileVersion: integer;
  TheKeyA, TheyKeyB: TIDEShortCut;
  Key: word;
  Shift: TShiftState;
begin
  FileVersion:=XMLConfig.GetValue(Prefix+'Version/Value',0);
  ExtToolCount:=XMLConfig.GetValue(Prefix+'ExternalToolCount/Value',0);
  for a:=0 to FRelations.Count-1 do begin
    Name:=lowercase(Relations[a].Name);
    for b:=1 to length(Name) do
      if not (Name[b] in ['a'..'z','A'..'Z','0'..'9']) then Name[b]:='_';
    with Relations[a] do begin
      GetDefaultKeyForCommand(Command,TheKeyA,TheyKeyB);
      DefaultStr:=KeyValuesToStr(TheKeyA, TheyKeyB);
    end;
    if FileVersion<2 then
      NewValue:=XMLConfig.GetValue(Prefix+Name,DefaultStr)
    else
      NewValue:=XMLConfig.GetValue(Prefix+Name+'/Value',DefaultStr);
    p:=1;
    Key:=word(ReadNextInt);
    Shift:=IntToShiftState(ReadNextInt);
    Relations[a].KeyA:=IDEShortCut(Key,Shift,VK_UNKNOWN,[]);
    Key:=word(ReadNextInt);
    Shift:=IntToShiftState(ReadNextInt);
    Relations[a].KeyB:=IDEShortCut(Key,Shift,VK_UNKNOWN,[]);
  end;
  Result:=true;
end;

function TKeyCommandRelationList.SaveToXMLConfig(
  XMLConfig:TXMLConfig; const Prefix: String):boolean;
var a,b: integer;
  Name: String;
  CurKeyStr: String;
  DefaultKeyStr: string;
  TheKeyA, TheyKeyB: TIDEShortCut;
begin
  XMLConfig.SetValue(Prefix+'Version/Value',KeyMappingFormatVersion);
  XMLConfig.SetDeleteValue(Prefix+'ExternalToolCount/Value',ExtToolCount,0);
  for a:=0 to FRelations.Count-1 do begin
    Name:=lowercase(Relations[a].Name);
    for b:=1 to length(Name) do
      if not (Name[b] in ['a'..'z','A'..'Z','0'..'9']) then Name[b]:='_';
    with Relations[a] do begin
      CurKeyStr:=KeyValuesToStr(KeyA,KeyB);
      GetDefaultKeyForCommand(Command,TheKeyA,TheyKeyB);
      DefaultKeyStr:=KeyValuesToStr(TheKeyA, TheyKeyB);
    end;
    //writeln('TKeyCommandRelationList.SaveToXMLConfig A ',Prefix+Name,' ',CurKeyStr=DefaultKeyStr);
    XMLConfig.SetDeleteValue(Prefix+Name+'/Value',CurKeyStr,DefaultKeyStr);
  end;
  Result:=true;
end;

function TKeyCommandRelationList.Find(AKey:Word; AShiftState:TShiftState;
  Areas: TCommandAreas):TKeyCommandRelation;
var a:integer;
begin
  Result:=nil;
  if AKey=VK_UNKNOWN then exit;
  for a:=0 to FRelations.Count-1 do with Relations[a] do begin
    if Category.Areas*Areas=[] then continue;
    if ((KeyA.Key1=AKey) and (KeyA.Shift1=AShiftState))
    or ((KeyB.Key1=AKey) and (KeyB.Shift1=AShiftState)) then begin
      Result:=Relations[a];
      exit;
    end;
  end;
end;

function TKeyCommandRelationList.FindByCommand(
  ACommand:word):TKeyCommandRelation;
var a:integer;
begin
  Result:=nil;
  for a:=0 to FRelations.Count-1 do with Relations[a] do
    if (Command=ACommand) then begin
      Result:=Relations[a];
      exit;
    end;
end;

procedure TKeyCommandRelationList.AssignTo(
  ASynEditKeyStrokes:TSynEditKeyStrokes; Areas: TCommandAreas);
var
  a,b,MaxKeyCnt,KeyCnt:integer;
  Key: TSynEditKeyStroke;
  CurRelation: TKeyCommandRelation;
begin
  for a:=0 to FRelations.Count-1 do begin
    CurRelation:=Relations[a];
    if (CurRelation.KeyA.Key1=VK_UNKNOWN)
    or ((CurRelation.Category.Areas*Areas)=[]) then
      MaxKeyCnt:=0
    else if CurRelation.KeyB.Key1=VK_UNKNOWN then
      MaxKeyCnt:=1
    else
      MaxKeyCnt:=2;
    KeyCnt:=1;
    b:=ASynEditKeyStrokes.Count-1;
    // replace keys
    while b>=0 do begin
      Key:=ASynEditKeyStrokes[b];
      if Key.Command=CurRelation.Command then begin
        if KeyCnt>MaxKeyCnt then begin
          // All keys with this command are already defined
          // -> delete this one
          Key.Free;
        end else if KeyCnt=1 then begin
          // Define key1 for this command
          Key.Key:=CurRelation.KeyA.Key1;
          Key.Shift:=CurRelation.KeyA.Shift1;
          Key.Key2:=CurRelation.KeyA.Key2;
          Key.Shift2:=CurRelation.KeyA.Shift2;
        end else if KeyCnt=2 then begin
          // Define key2 for this command
          Key.Key:=CurRelation.KeyB.Key1;
          Key.Shift:=CurRelation.KeyB.Shift1;
          Key.Key2:=CurRelation.KeyB.Key2;
          Key.Shift2:=CurRelation.KeyB.Shift2;
        end;
        inc(KeyCnt);
      end;
      dec(b);
    end;
    // add missing keys
    while KeyCnt<=MaxKeyCnt do begin
      Key:=ASynEditKeyStrokes.Add;
      Key.Command:=CurRelation.Command;
      if KeyCnt=1 then begin
        Key.Key:=CurRelation.KeyA.Key1;
        Key.Shift:=CurRelation.KeyA.Shift1;
        Key.Key2:=CurRelation.KeyA.Key2;
        Key.Shift2:=CurRelation.KeyA.Shift2;
      end else begin
        Key.Key:=CurRelation.KeyB.Key1;
        Key.Shift:=CurRelation.KeyB.Shift1;
        Key.Key2:=CurRelation.KeyB.Key2;
        Key.Shift2:=CurRelation.KeyB.Shift2;
      end;
      inc(KeyCnt);
    end;
  end;
end;

procedure TKeyCommandRelationList.Assign(List: TKeyCommandRelationList);
var
  i: Integer;
  CurCategory: TKeyCommandCategory;
  CurRelation: TKeyCommandRelation;
begin
  Clear;
  
  // copy categories
  for i:=0 to List.CategoryCount-1 do begin
    CurCategory:=List.Categories[i];
    AddCategory(CurCategory.Name,CurCategory.Description,CurCategory.Areas);
  end;
  
  // copy keys
  for i:=0 to List.Count-1 do begin
    CurRelation:=List.Relations[i];
    CurCategory:=FindCategoryByName(CurRelation.Category.Name);
    Add(CurCategory,CurRelation.Name,CurRelation.Command,
      CurRelation.KeyA,CurRelation.KeyB);
  end;

  // copy ExtToolCount
  fExtToolCount:=List.ExtToolCount;
end;

procedure TKeyCommandRelationList.LoadScheme(const SchemeName: string);
var
  i: Integer;
  CurRelation: TKeyCommandRelation;
  NewScheme: TKeyMapScheme;
  TheKeyA, TheKeyB: TIDEShortCut;
begin
  NewScheme:=KeySchemeNameToSchemeType(SchemeName);
  // set all keys to new scheme
  for i:=0 to Count-1 do begin
    CurRelation:=Relations[i];
    case NewScheme of
    kmsLazarus: GetDefaultKeyForCommand(CurRelation.Command,TheKeyA,TheKeyB);
    kmsClassic: GetDefaultKeyForClassicScheme(CurRelation.Command,
                                              TheKeyA,TheKeyB);
    kmsCustom: ;
    end;
    CurRelation.KeyA:=TheKeyA;
    CurRelation.KeyB:=TheKeyB;
  end;
end;

function TKeyCommandRelationList.GetCategory(Index: integer): TKeyCommandCategory;
begin
  Result:=TKeyCommandCategory(fCategories[Index]);
end;

function TKeyCommandRelationList.CategoryCount: integer;
begin
  Result:=fCategories.Count;
end;

function TKeyCommandRelationList.AddCategory(const Name, Description: string;
  TheAreas: TCommandAreas): integer;
begin
  Result:=fCategories.Add(TKeyCommandCategory.Create(Name,Description,TheAreas));
end;

function TKeyCommandRelationList.FindCategoryByName(const CategoryName: string
  ): TKeyCommandCategory;
var i: integer;
begin
  for i:=0 to CategoryCount-1 do
    if CategoryName=Categories[i].Name then begin
      Result:=Categories[i];
      exit;
    end;
  Result:=nil;
end;

function TKeyCommandRelationList.TranslateKey(AKey: Word;
  AShiftState: TShiftState; Areas: TCommandAreas): word;
var
  ARelation: TKeyCommandRelation;
begin
  ARelation:=Find(AKey,AShiftState,Areas);
  if ARelation<>nil then
    Result:=ARelation.Command
  else
    Result:=ecNone;
end;

function TKeyCommandRelationList.IndexOf(ARelation: TKeyCommandRelation
  ): integer;
begin
  Result:=fRelations.IndexOf(ARelation);
end;

function TKeyCommandRelationList.CommandToShortCut(ACommand: word
  ): TShortCut;
var ARelation: TKeyCommandRelation;
begin
  ARelation:=FindByCommand(ACommand);
  if ARelation<>nil then
    Result:=ARelation.AsShortCut
  else
    Result:=VK_UNKNOWN;
end;

{ TKeyCommandCategory }

procedure TKeyCommandCategory.Clear;
begin
  fName:='';
  fDescription:='';
  inherited Clear;
end;

procedure TKeyCommandCategory.Delete(Index: Integer);
begin
  TObject(Items[Index]).Free;
  inherited Delete(Index);
end;

constructor TKeyCommandCategory.Create(const AName, ADescription: string;
  TheAreas: TCommandAreas);
begin
  inherited Create;
  FName:=AName;
  FDescription:=ADescription;
  FAreas:=TheAreas;
end;


//------------------------------------------------------------------------------
initialization
  KeyMappingEditForm:=nil;
  
finalization
  VirtualKeyStrings.Free;
  VirtualKeyStrings:=nil;

end.

