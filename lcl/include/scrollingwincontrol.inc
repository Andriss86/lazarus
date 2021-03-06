{%MainUnit ../forms.pp}

{
 *****************************************************************************
  This file is part of the Lazarus Component Library (LCL)

  See the file COPYING.modifiedLGPL.txt, included in this distribution,
  for details about the license.
 *****************************************************************************
}

procedure TScrollingWinControl.SetAutoScroll(Value: Boolean);
begin
  if FAutoScroll = Value then Exit;
  FAutoScroll := Value;
  UpdateScrollBars;
end;

procedure TScrollingWinControl.CreateWnd;
begin
  DisableAutoSizing{$IFDEF DebugDisableAutoSizing}('TScrollingWinControl.CreateWnd'){$ENDIF};
  try
    inherited CreateWnd;
    UpdateScrollBars;
  finally
    EnableAutoSizing{$IFDEF DebugDisableAutoSizing}('TScrollingWinControl.CreateWnd'){$ENDIF};
  end;
end;

function TScrollingWinControl.GetClientScrollOffset: TPoint;
begin
  if (HorzScrollBar <> nil) and (VertScrollBar <> nil) then
  begin
    Result.X := HorzScrollBar.Position;
    Result.Y := VertScrollBar.Position;
  end else
  begin
    Result.X := 0;
    Result.Y := 0;
  end;
end;

function TScrollingWinControl.GetLogicalClientRect: TRect;
begin
  if AutoScroll then begin
    { The logical ClientRect is used by the child control layout algorithm.
      And the visibility of scrollbars depend on the size of the child controls.
      Prevent circular dependencies:
      Use total ClientRect (no visible scrollbars). }
    Result := Rect(0,0,VertScrollBar.ClientSizeWithoutBar,HorzScrollBar.ClientSizeWithoutBar);
  end else
    Result := ClientRect;
  {if (FHorzScrollBar.Range>Result.Right)
  or (FVertScrollBar.Range>Result.Bottom) then
    DebugLn(['TScrollingWinControl.GetLogicalClientRect Client=',ClientWidth,'x',ClientHeight,' Ranges=',FHorzScrollBar.Range,'x',FVertScrollBar.Range]);}
  if Assigned(FHorzScrollBar) and FHorzScrollBar.Visible
  and (FHorzScrollBar.Range > Result.Right) then
    Result.Right := FHorzScrollBar.Range;
  if Assigned(FVertScrollBar) and FVertScrollBar.Visible
  and (FVertScrollBar.Range > Result.Bottom) then
    Result.Bottom := FVertScrollBar.Range;
end;

procedure TScrollingWinControl.DoOnResize;
begin
  inherited DoOnResize;

  if AutoScroll then
  begin
    if (HorzScrollBar = nil) or (VertScrollBar = nil) then Exit;
    if HorzScrollBar.Visible or VertScrollBar.Visible then
      UpdateScrollBars;
  end;
  //debugln(['TScrollingWinControl.DoOnResize ',DbgSName(Self),' ',dbgs(BoundsRect),' ',dbgs(ClientRect),' ',dbgs(GetLogicalClientRect)]);
end;

procedure TScrollingWinControl.GetPreferredSizeClientFrame(out aWidth,
  aHeight: integer);
begin
  if AutoScroll and (VertScrollBar<>nil) then
    aWidth:=Width-VertScrollBar.ClientSizeWithoutBar
  else
    aWidth:=Width-ClientWidth;
  if AutoScroll and (HorzScrollBar<>nil) then
    aHeight:=Height-HorzScrollBar.ClientSizeWithoutBar
  else
    aHeight:=Height-ClientHeight;
end;

procedure TScrollingWinControl.AlignControls(AControl: TControl; var ARect: TRect);
begin
  if AutoScroll then
  begin
    if (HorzScrollBar = nil) or (VertScrollBar = nil) then Exit;
    inherited AlignControls(AControl, ARect);

    UpdateScrollBars;
  end
  else
    inherited AlignControls(AControl, ARect);
end;

function TScrollingWinControl.AutoScrollEnabled: Boolean;
begin
  Result := not (AutoSize or (DockSite and UseDockManager));
end;

procedure TScrollingWinControl.CalculateAutoRanges;

  {procedure trav(aControl: TControl; Prefix: string);
  var
    w: integer;
    h: integer;
    i: Integer;
  begin
    if not aControl.IsVisible then exit;
    aControl.GetPreferredSize(w,h,true,true);
    debugln([Prefix,'W ',DbgSName(aControl),' ',dbgs(aControl.BoundsRect),' Pref=',w,'x',h]);
    if aControl is TWinControl then
      for i:=0 to TWinControl(aControl).ControlCount-1 do
        trav(TWinControl(aControl).Controls[i],Prefix+'  ');
  end;}

  procedure GetPreferredClientRect(out PreferredWidth, PreferredHeight: integer);
  var
    CurClientRect: TRect;
  begin
    PreferredWidth:=0;
    PreferredHeight:=0;
    GetPreferredSize(PreferredWidth,PreferredHeight,true,false);
    {$IFDEF VerboseScrollingWinControl}
    DebugLn(['GetPreferredClientRect ',DbgSName(Self),' ClientRect=',dbgs(ClientRect),' PrefSize=',PreferredWidth,'x',PreferredHeight]);
    //trav(Self,'  ');
    {$ENDIF}
    CurClientRect := ClientRect;
    if PreferredWidth>0 then
      PreferredWidth:=Max(0,PreferredWidth-(Width-CurClientRect.Right));
    if PreferredHeight>0 then
      PreferredHeight:=Max(0,PreferredHeight-(Height-CurClientRect.Bottom));
    //DebugLn(['GetPreferredClientRect ',DbgSName(Self),' PrefClient=',PreferredWidth,'x',PreferredHeight,' Client=',dbgs(CurClientRect),' Size=',dbgs(FControl.BoundsRect)]);
  end;

var
  PreferredWidth: Integer;
  PreferredHeight: Integer;
begin
  GetPreferredClientRect(PreferredWidth,PreferredHeight);
  {$IFDEF VerboseScrollingWinControl}
  DebugLn(['TScrollingWinControl.CalculateAutoRanges ',DbgSName(Self),' AutoSize=',AutoSize,' Bounds=',dbgs(BoundsRect),' Client=',dbgs(ClientRect),' LogClientRect=',dbgs(GetLogicalClientRect),' pref=',PreferredWidth,'x',PreferredHeight]);
  {$ENDIF}
  HorzScrollBar.InternalSetRange(PreferredWidth);
  VertScrollBar.InternalSetRange(PreferredHeight);
end;

class function TScrollingWinControl.GetControlClassDefaultSize: TSize;
begin
  Result.CX := 150;
  Result.CY := 150;
end;

procedure TScrollingWinControl.SetHorzScrollBar(Value: TControlScrollBar);
begin
  FHorzScrollbar.Assign(Value);
end;

procedure TScrollingWinControl.SetVertScrollBar(Value: TControlScrollBar);
begin
  FVertScrollbar.Assign(Value);
end;

procedure TScrollingWinControl.WMSize(var Message: TLMSize);
var
  NewState: TWindowState;
begin
  inherited;
  if (Message.SizeType and SIZE_SourceIsInterface) <> 0 then
  begin
    NewState := wsNormal;
    case (Message.SizeType xor SIZE_SourceIsInterface) of
      SIZE_MINIMIZED:
        NewState := wsMinimized;
      SIZE_MAXIMIZED:
        NewState := wsMaximized;
      SIZE_FULLSCREEN:
        NewState := wsFullScreen;
    end;
    Resizing(NewState);
  end;
end;

procedure TScrollingWinControl.Resizing(State: TWindowState);
begin
  //
end;

procedure TScrollingWinControl.ComputeScrollbars;
// true if something has changed
// update Page, AutoRange

  procedure UpdateBar(aBar: TControlScrollBar; aClientSize: integer);
  begin
    // page (must be smaller than Range but at least 1)
    aBar.FPage := Max(1,Min(Min(aBar.Range,aClientSize), High(HorzScrollbar.FPage)));
    aBar.FAutoRange := Max(0, aBar.Range - aClientSize);
    {$IFDEF VerboseScrollingWinControl}
    debugln(['TScrollingWinControl.ComputeScrollbars ',DbgSName(Self),' ',dbgs(aBar.Kind),' Page=',aBar.Page,' Range=',aBar.Range,' ClientSize=',aClientSize]);
    {$ENDIF}
  end;
  
var
  ClientW: Integer;
  ClientH: Integer;
begin
  CalculateAutoRanges;

  ClientW:=VertScrollBar.ClientSizeWithoutBar;
  ClientH:=HorzScrollBar.ClientSizeWithoutBar;
  if VertScrollBar.Range > ClientH then
  begin
    // vertical does not fit -> vertical scrollbar will be shown
    ClientW:=VertScrollBar.ClientSizeWithBar;
  end;
  if HorzScrollBar.Range > ClientW then
  begin
    // horizontal does not fit -> horizontal scrollbar will be shown
    ClientH:=HorzScrollBar.ClientSizeWithBar;
    if VertScrollBar.Range > ClientH then
    begin
      // vertical does not fit, because of the other scrollbar
      // -> vertical scrollbar will be shown too
      ClientW:=VertScrollBar.ClientSizeWithBar;
    end;
  end;

  UpdateBar(HorzScrollBar,ClientW);
  UpdateBar(VertScrollBar,ClientH);
end;

procedure TScrollingWinControl.UpdateScrollbars;
begin
  if ([csLoading, csDestroying] * ComponentState <> []) then Exit;
  if not HandleAllocated then Exit;
  if (HorzScrollBar = nil) or (VertScrollBar = nil) then Exit;

  if FIsUpdating then Exit;

  FIsUpdating := True;
  try
    if AutoScroll then
      ComputeScrollbars; // page, autorange, IsScrollBarVisible
    FVertScrollbar.UpdateScrollbar;
    FHorzScrollbar.UpdateScrollbar;
  finally
    FIsUpdating := False;
  end;
end;

class procedure TScrollingWinControl.WSRegisterClass;
begin
  inherited WSRegisterClass;
  RegisterScrollingWinControl;
end;

procedure TScrollingWinControl.ScrollBy(DeltaX, DeltaY: Integer);
begin
  if HandleAllocated and IsWindowVisible(Handle) then
  begin
    TWSScrollingWinControlClass(WidgetSetClass).ScrollBy(Self, DeltaX, DeltaY);
    //Invalidate;
  end
  else
    inherited ScrollBy(DeltaX, DeltaY);
end;

procedure TScrollingWinControl.ScrollbarHandler(ScrollKind: TScrollBarKind;
  OldPosition: Integer);
begin
  if ScrollKind = sbVertical then
    ScrollBy(0, OldPosition - FVertScrollBar.Position)
  else
    ScrollBy(OldPosition - FHorzScrollBar.Position, 0);
end;

procedure TScrollingWinControl.Loaded;
begin
  inherited Loaded;
  UpdateScrollbars;
end;

procedure TScrollingWinControl.SetAutoSize(Value: Boolean);
begin
  if AutoSize=Value then exit;
  if Value then
    ControlStyle:=ControlStyle-[csAutoSizeKeepChildLeft,csAutoSizeKeepChildTop]
  else
    ControlStyle:=ControlStyle+[csAutoSizeKeepChildLeft,csAutoSizeKeepChildTop];
  inherited SetAutoSize(Value);
end;

procedure TScrollingWinControl.WMVScroll(var Message : TLMVScroll);
begin
  VertScrollbar.ScrollHandler(Message);
end;

procedure TScrollingWinControl.WMHScroll(var Message : TLMHScroll);
begin
  //DebugLn(['TScrollingWinControl.WMHScroll ',dbgsName(Self)]);
  HorzScrollbar.ScrollHandler(Message);
end;

constructor TScrollingWinControl.Create(TheOwner : TComponent);
begin
  Inherited Create(TheOwner);

  FAutoScroll := False;
  FVertScrollbar := TControlScrollBar.Create(Self, sbVertical);
  FHorzScrollbar := TControlScrollBar.Create(Self, sbHorizontal);

  ControlStyle := [csAcceptsControls, csClickEvents, csDoubleClicks,
                   csAutoSizeKeepChildLeft, csAutoSizeKeepChildTop];

  with GetControlClassDefaultSize do
    SetInitialBounds(0, 0, CX, CY);
end;

destructor TScrollingWinControl.Destroy;
begin
  FreeThenNil(FHorzScrollBar);
  FreeThenNil(FVertScrollBar);
  inherited Destroy;
end;

// included by forms.pp
