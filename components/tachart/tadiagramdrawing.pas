{
 *****************************************************************************
  See the file COPYING.modifiedLGPL.txt, included in this distribution,
  for details about the license.
 *****************************************************************************

  Authors: Alexander Klenin

}
unit TADiagramDrawing;

{$H+}

interface

uses
  FPCanvas,
  TADrawUtils, TADiagram;

type
  TDiaContextDrawer = class(TDiaContext)
  private
    FDrawer: IChartDrawer;
  public
    property Drawer: IChartDrawer read FDrawer write FDrawer;
  end;

  TDiaPenDecorator = class(TDiaDecorator)
  private
    FPen: TFPCustomPen;
  public
    constructor Create(AOwner: TDiaDecoratorList);
    destructor Destroy; override;
    property Pen: TFPCustomPen read FPen;
  end;

implementation

uses
  Math, Types, SysUtils,
  TAGeometry;

function ToImage(const AP: TDiaPoint): TPoint; inline;
begin
  Result := Point(Round(AP.X[duPixels]), Round(AP.Y[duPixels]));
end;

procedure DrawDiaBox(ASelf: TDiaBox);
var
  id: IChartDrawer;
begin
  id := (ASelf.Owner.Context as TDiaContextDrawer).Drawer;
  id.PrepareSimplePen($000000);
  id.SetBrushColor($FFFFFF);
  with ASelf do
    id.Polygon([
      ToImage(FTopLeft), ToImage(FTopRight),
      ToImage(FBottomRight), ToImage(FBottomLeft)
    ], 0, 4);
  id.TextOut.Pos(ToImage(ASelf.FTopLeft) + Point(4, 4)).Text(ASelf.Caption).Done;
end;

procedure DrawEndPoint(
  ADrawer: IChartDrawer; AEndPoint: TDiaEndPoint;
  const APos: TPoint; AAngle: Double);
var
  da: Double;
  diag: Integer;
  pt1, pt2: TPoint;
begin
  ADrawer.SetPenParams(psSolid, $000000);
  ADrawer.SetBrushColor($FFFFFF);
  da := ArcTan2(AEndPoint.Width.Value, AEndPoint.Length.Value);

  diag := -Round(Sqrt(Sqr(AEndPoint.Length.Value) + Sqr(AEndPoint.Width.Value)));
  pt1 := APos + RotatePointX(diag, AAngle - da);
  pt2 := APos + RotatePointX(diag, AAngle + da);
  case AEndPoint.Shape of
    depsClosedArrow: ADrawer.Polygon([pt1, APos, pt2], 0, 3);
    depsOpenArrow: ADrawer.Polyline([pt1, APos, pt2], 0, 3);
  end;
end;

procedure DrawDiaLink(ASelf: TDiaLink);
var
  id: IChartDrawer;
var
  startPos, endPos: TPoint;
  d: TDiaDecorator;
begin
  if (ASelf.Start.Connector = nil) or (ASelf.Finish.Connector = nil) then exit;
  id := (ASelf.Owner.Context as TDiaContextDrawer).Drawer;
  id.PrepareSimplePen($000000);
  for d in ASelf.Decorators do
    if d is TDiaPenDecorator then
      id.Pen := (d as TDiaPenDecorator).Pen;
  startPos := ToImage(ASelf.Start.Connector.ActualPos);
  endPos := ToImage(ASelf.Finish.Connector.ActualPos);
  id.Line(startPos, endPos);
  if ASelf.Start.Shape <> depsNone then
    with startPos - endPos do
      DrawEndPoint(id, ASelf.Start, startPos, ArcTan2(Y, X));
  if ASelf.Finish.Shape <> depsNone then
    with endPos - startPos do
      DrawEndPoint(id, ASelf.Finish, endPos, ArcTan2(Y, X));
end;

{ TDiaPenDecorator }

constructor TDiaPenDecorator.Create(AOwner: TDiaDecoratorList);
begin
  inherited Create(AOwner);
  FPen := TFPCustomPen.Create;
  FPen.Mode := pmCopy;
end;

destructor TDiaPenDecorator.Destroy;
begin
  FreeAndNil(FPen);
  inherited;
end;

initialization
  TDiaBox.FInternalDraw := @DrawDiaBox;
  TDiaLink.FInternalDraw := @DrawDiaLink;

end.
