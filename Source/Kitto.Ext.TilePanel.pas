{-------------------------------------------------------------------------------
   Copyright 2013 Ethea S.r.l.

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
-------------------------------------------------------------------------------}

unit Kitto.Ext.TilePanel;

{$I Kitto.Defines.inc}

interface

uses
  Types,
  EF.Tree,
  Kitto.Metadata.Views,
  Kitto.Ext.Base, Kitto.Ext.Controller, Kitto.Ext.Session, Kitto.Ext.TabPanel;

type
  // A tile page to be added to a container.
  TKExtTilePanel = class(TKExtPanelBase)
  strict private
    FView: TKView;
    FConfig: TEFTree;
    FTileBoxHtml: string;
    FMaxTilesPerFolder: Integer;
    FTileRows: Integer;
    FColors: TStringDynArray;
    FColorIndex: Integer;
    procedure AddBreak;
    procedure AddTitle(const ADisplayLabel: string);
    function GetTileHeight: Integer;
    function GetTileWidth: Integer;
    procedure BuildTileBoxHtml;
    function GetBoxStyle(const ATilesPerRow, ARows: Integer): string;
    procedure AddTile(const ANode: TKTreeViewNode; const ADisplayLabel: string);
    procedure AddTiles(const ANode: TKTreeViewNode; const ADisplayLabel: string);
    function GetNextTileColor: string;
    function GetColors(const AColorSetName: string): TStringDynArray;
  public
    const DEFAULT_COLOR_SET = 'Metro';
    property Config: TEFTree read FConfig write FConfig;
    property View: TKView read FView write FView;
    procedure DoDisplay;
  published
    procedure DisplayView;
  end;

  // Hosted by the tile panel controller; manages the additional tile page.
  TKExtTileTabPanel = class(TKExtTabPanel)
  private
    FTilePanel: TKExtTilePanel;
    procedure AddTileSubPanel;
  strict protected
    function TabsVisible: Boolean; override;
  public
    procedure SetAsViewHost; override;
    procedure DisplaySubViewsAndControllers; override;
  end;

  // A tab panel controller with a tile menu on the first page.
  TKExtTilePanelController = class(TKExtTabPanelController)
  strict protected
    function GetTabPanelClass: TKExtTabPanelClass; override;
    function GetDefaultTabIconsVisible: Boolean; override;
  published
    procedure DisplayPage;
  end;

implementation

uses
  SysUtils, StrUtils,
  Ext,
  EF.StrUtils, EF.Macros, EF.Localization,
  Kitto.Config, Kitto.Utils, Kitto.Ext.Utils;

{ TKExtTilePanelController }

procedure TKExtTilePanelController.DisplayPage;
begin
  { TODO : To be called when the tile is a multi-level tile.
    Should change the html to reflect the specified page or sub-page,
    perhaps using animation. As an alternative, produce all pages at once
    and animate among them. }
end;

function TKExtTilePanelController.GetDefaultTabIconsVisible: Boolean;
begin
  Result := False;
end;

function TKExtTilePanelController.GetTabPanelClass: TKExtTabPanelClass;
begin
  Result := TKExtTileTabPanel;
end;

{ TKExtTileTabPanel }

procedure TKExtTileTabPanel.DisplaySubViewsAndControllers;
begin
  AddTileSubPanel;
  inherited;
  if Items.Count > 0 then
    SetActiveTab(0);
end;

procedure TKExtTileTabPanel.SetAsViewHost;
begin
  // Don't act as view host on mobile - we want modal views there.
  if not Session.IsMobileBrowser then
    inherited;
end;

function TKExtTileTabPanel.TabsVisible: Boolean;
begin
  Result := Config.GetBoolean('TabsVisible', not Session.IsMobileBrowser);
end;

procedure TKExtTileTabPanel.AddTileSubPanel;
begin
  inherited;
  FTilePanel := TKExtTilePanel.CreateAndAddTo(Items);
  FTilePanel.View := View;
  FTilePanel.Config := Config;
  FTilePanel.DoDisplay;
end;

{ TKExtTilePanel }

procedure TKExtTilePanel.DoDisplay;
var
  LTitle: string;
begin
  LTitle := _(Config.GetExpandedString('Title', View.DisplayLabel));
  if LTitle <> '' then
    Title := LTitle
  else
    Title := _('Home');
  AutoScroll := Session.IsMobileBrowser;

  FColors := GetColors(Config.GetExpandedString('ColorSet', DEFAULT_COLOR_SET));
  BuildTileBoxHtml;
end;

procedure TKExtTilePanel.DisplayView;
begin
  Session.DisplayView(TKView(Session.QueryAsInteger['View']));
end;

function TKExtTilePanel.GetBoxStyle(const ATilesPerRow, ARows: Integer): string;
begin
//  LWidth := (ATilesPerRow * GetTileWidth) + Succ(ATilesPerRow) * 2 * GetBorderWidth;
//  LHeight := (ARows * GetTileHeight) + Succ(ATilesPerRow) * 2 * GetBorderWidth;
  { TODO : add space for folders/titles }
 //Result := Format('width:%dpx;height:%dpx;', [LWidth, LHeight]);
 Result := '';
end;

function TKExtTilePanel.GetColors(const AColorSetName: string): TStringDynArray;
begin
  if SameText(AColorSetName, 'Metro') then
  begin
    SetLength(Result, 10);
    Result[0] := '#A200FF';
    Result[1] := '#FF0097';
    Result[2] := '#00ABA9';
    Result[3] := '#8CBF26';
    Result[4] := '#A05000';
    Result[5] := '#E671B8';
    Result[6] := '#F09609';
    Result[7] := '#1BA1E2';
    Result[8] := '#E51400';
    Result[9] := '#339933';
  end
  else if SameText(AColorSetName, 'Blue') then
  begin
    SetLength(Result, 5);
    Result[0] := '#1240AB';
    Result[1] := '#365BB0';
    Result[2] := '#5777C0';
    Result[3] := '#0D3184';
    Result[4] := '#082568';
  end
  else if SameText(AColorSetName, 'Red') then
  begin
    SetLength(Result, 5);
    Result[0] := '#FF0000';
    Result[1] := '#FF3939';
    Result[2] := '#FF6363';
    Result[3] := '#C50000';
    Result[4] := '#9B0000';
  end
  else if SameText(AColorSetName, 'Gold') then
  begin
    SetLength(Result, 5);
    Result[0] := '#FFD300';
    Result[1] := '#FFDD39';
    Result[2] := '#FFE463';
    Result[3] := '#C5A300';
    Result[4] := '#9B8000';
  end
  else if SameText(AColorSetName, 'Violet') then
  begin
    SetLength(Result, 5);
    Result[0] := '#3914AF';
    Result[1] := '#5538B4';
    Result[2] := '#735AC3';
    Result[3] := '#2B0E88';
    Result[4] := '#20096A';
  end
  else
  begin
    SetLength(Result, 1);
    Result[0] := '#000000';
  end;
end;

function TKExtTilePanel.GetNextTileColor: string;
begin
  Result := FColors[FColorIndex];
  Inc(FColorIndex);
  if FColorIndex > High(FColors) then
    FColorIndex := Low(FColors);
end;

function TKExtTilePanel.GetTileHeight: Integer;
begin
  Result := Config.GetInteger('TileHeight', 50);
end;

function TKExtTilePanel.GetTileWidth: Integer;
begin
  Result := Config.GetInteger('TileWidth', 100);
end;

procedure TKExtTilePanel.AddTiles(const ANode: TKTreeViewNode; const ADisplayLabel: string);
var
  I: Integer;
  LSubNode: TKTreeViewNode;
  LDisplayLabelNode: TEFNode;
  LDisplayLabel: string;
begin
  FTileBoxHtml := FTileBoxHtml + '<div class="k-tile-row">';
  if ANode is TKTreeViewFolder then
  begin
    AddTitle(ADisplayLabel);
    for I := 0 to ANode.TreeViewNodeCount - 1 do
    begin
      LSubNode := ANode.TreeViewNodes[I];
      LDisplayLabelNode := LSubNode.FindNode('DisplayLabel');
      if Assigned(LDisplayLabelNode) then
        LDisplayLabel := _(LDisplayLabelNode.AsString)
      else
        LDisplayLabel := GetDisplayLabelFromNode(LSubNode, Session.Config.Views);
      AddTile(LSubNode, LDisplayLabel);
    end;
    if FMaxTilesPerFolder < ANode.TreeViewNodeCount then
      FMaxTilesPerFolder := ANode.TreeViewNodeCount;
    Inc(FTileRows);
  end
  else
    AddTile(ANode, ADisplayLabel);
  AddBreak;
  FTileBoxHtml := FTileBoxHtml + '</div>';
end;

procedure TKExtTilePanel.AddBreak;
begin
  FTileBoxHtml := FTileBoxHtml + '<br style="clear:left;" />';
end;

procedure TKExtTilePanel.AddTitle(const ADisplayLabel: string);
begin
  FTileBoxHtml := FTileBoxHtml + Format(
    '<div class="k-tile-title-row">%s</div>',
    [HTMLEncode(ADisplayLabel)]);
end;

procedure TKExtTilePanel.AddTile(const ANode: TKTreeViewNode; const ADisplayLabel: string);
var
  LClickCode: string;

  function GetCSS: string;
  var
    LCSS: string;
  begin
    LCSS := ANode.GetString('CSS');
    if LCSS <> '' then
      Result := ' ' + LCSS
    else
      Result := '';
  end;

  function GetDisplayLabel: string;
  begin
    if ANode.GetBoolean('HideLabel', False) then
      Result := ''
    else
      Result := HTMLEncode(ADisplayLabel);
  end;

  function GetColor: string;
  var
    LColor: TEFNode;
  begin
    LColor := ANode.FindNode('BackgroundColor');
    if Assigned(LColor) then
      Result := LColor.AsString
    else
      Result := GetNextTileColor;
  end;

begin
  Assert(not (ANode is TKTreeViewFolder));

  LClickCode := JSMethod(Ajax(DisplayView, ['View', Integer(Session.Config.Views.ViewByNode(ANode))]));
  if GetCSS <> '' then
  begin
    FTileBoxHtml := FTileBoxHtml + Format(
      '<a href="#" onclick="%s"><div class="k-tile%s">' +
      '<div class="k-tile-inner">%s</div></div></a>',
      [HTMLEncode(LClickCode), GetCSS, GetDisplayLabel]);
  end
  else
  begin
    FTileBoxHtml := FTileBoxHtml + Format(
      '<a href="#" onclick="%s"><div class="k-tile" style="background-color:%s;width:%dpx;height:%dpx">' +
      '<div class="k-tile-inner">%s</div></div></a>',
      [HTMLEncode(LClickCode), GetColor, GetTileWidth, GetTileHeight, GetDisplayLabel]);
  end;
end;

procedure TKExtTilePanel.BuildTileBoxHtml;
var
  LTreeViewRenderer: TKExtTreeViewRenderer;
  LNode: TEFNode;
  LTreeView: TKTreeView;
  LFileName: string;
begin
  FColorIndex :=  0;
  FTileBoxHtml := '<div class="k-tile-box" style="%s">';

  LTreeViewRenderer := TKExtTreeViewRenderer.Create;
  try
    LTreeViewRenderer.Session := Session;
    LNode := Config.GetNode('TreeView');
    LTreeView := Session.Config.Views.ViewByNode(LNode) as TKTreeView;
    FMaxTilesPerFolder := 0;
    FTileRows := 0;
    LTreeViewRenderer.Render(LTreeView,
      procedure (ANode: TKTreeViewNode; ADisplayLabel: string)
      begin
        AddTiles(ANode, ADisplayLabel);
      end,
      Self, DisplayView);
    FTileBoxHtml := FTileBoxHtml + '</div></div>';
    FTileBoxHtml := Format(FTileBoxHtml, [GetBoxStyle(FMaxTilesPerFolder, FTileRows)]);

    LFileName := ChangeFileExt(ExtractFileName(LTreeView.PersistentFileName), '.html');
    LoadHtml(LFileName,
      function (AHtml: string): string
      begin
        if AHtml <> '' then
          Result := ReplaceText(AHtml, '{content}', FTileBoxHtml)
        else
          Result := FTileBoxHtml;
      end);
  finally
    FreeAndNil(LTreeViewRenderer);
  end;
end;

initialization
  TKExtControllerRegistry.Instance.RegisterClass('TilePanel', TKExtTilePanelController);

finalization
  TKExtControllerRegistry.Instance.UnregisterClass('TilePanel');

end.