{
  Stimulus Control
  Copyright (C) 2014-2019 Carlos Rafael Fernandes Picanço, Universidade Federal do Pará.

  The present file is distributed under the terms of the GNU General Public License (GPL v3.0).

  You should have received a copy of the GNU General Public License
  along with this program. If not, see <http://www.gnu.org/licenses/>.
}
unit Controls.Trials.GoNoGo.Dani;

{$mode objfpc}{$H+}

interface

uses LCLIntf, Controls, Classes, SysUtils, ExtCtrls, StdCtrls, LazFileUtils

  , Controls.Trials.Abstract
  , Controls.Trials.Helpers
  , Controls.Stimuli.Text
  , Controls.GoLeftGoRight
  , Schedules
  , Consequences
  ;

type

  TButtonSide = (ssNone, ssLeft, ssRight);

  { TGNG }

  TGNG = class(TTrial)
  private
    FLabel : TLabel;
    FTimer : TTimer;
    FButtonResponse : TButtonSide;
    FDataSupport : TDataSupport;
    FSample : TLabelStimulus;
    FComparison : TLabelStimulus;
    FOperandum : TGoLeftGoRight;
    FSchedule : TSchedule;
    FButtonSide : TButtonSide;
    FConsequence : TConsequence;
    procedure ButtonLeftClick(Sender: TObject);
    procedure ButtonRightClick(Sender: TObject);
    procedure ShowOperandum(Sender : TObject);
    procedure TrialPaint;
    procedure Consequence(Sender: TObject);
    procedure Response(Sender: TObject);
    procedure TrialBeforeEnd(Sender: TObject);
    procedure TrialStart(Sender: TObject);
    procedure TrialResult(Sender: TObject);
  protected
    { TTrial }
    procedure WriteData(Sender: TObject); override;
  public
    constructor Create(AOwner: TCustomControl); override;
    destructor Destroy; override;
    procedure Play(ACorrection : Boolean); override;
    function AsString : string; override;
    function HasConsequence: Boolean; override;
  end;

implementation

uses Graphics, StrUtils, Constants, Timestamps;

{ TGNG }

constructor TGNG.Create(AOwner: TCustomControl);
begin
  inherited Create(AOwner);
  OnTrialBeforeEnd := @TrialBeforeEnd;
  OnTrialStart := @TrialStart;
  OnTrialPaint := @TrialPaint;
  FButtonResponse := ssNone;
  Header :=  Header + #9 +
             rsReportStmBeg + #9 +
             rsReportRspLat + #9 +
             rsReportStmEnd + #9 +
             rsReportRspStl;
  FLabel := TLabel.Create(Self);
  FLabel.Top := 15;
  FLabel.Left:= 15;
  FLabel.Font.Size := 15;
  FLabel.Alignment := taCenter;
  FLabel.Layout := tlCenter;
  FLabel.WordWrap := True;
  FLabel.Caption := 'Seus Pontos: ' +LineEnding + (CounterManager.BlcHits * 17).ToString;
  FLabel.Parent := Self.Parent;

  FTimer := TTimer.Create(Self);
  FTimer.Interval := 0;
  FTimer.Enabled := False;
  FTimer.OnTimer := @ShowOperandum;
  FDataSupport.Responses:= 0;
end;

destructor TGNG.Destroy;
begin

  inherited Destroy;
end;

procedure TGNG.TrialResult(Sender: TObject);
begin
  if Result = T_NONE then
  begin
    case FButtonResponse of
      ssNone: Result := T_NONE;
      ssLeft:
        case FButtonSide of
          ssNone: Result := T_NONE;
          ssLeft: Result := T_HIT;
          ssRight: Result := T_MISS;
        end;
      ssRight:
        case FButtonSide of
          ssNone: Result := T_NONE;
          ssLeft: Result := T_MISS;
          ssRight: Result := T_HIT;
        end;
    end;
    FConsequence := NextConsequence(Result = T_HIT);
    if HasConsequence then Consequences.Play(FConsequence);
  end;
end;

procedure TGNG.TrialBeforeEnd(Sender: TObject);
begin
  FDataSupport.StmEnd := TickCount;
  TrialResult(Sender);
  LogEvent(Result);
  WriteData(Sender);
end;

procedure TGNG.Consequence(Sender: TObject);
begin
  if Assigned(CounterManager.OnConsequence) then CounterManager.OnConsequence(Self);
  EndTrial(Sender);
end;

procedure TGNG.TrialPaint;
var
  R : TRect;
begin
  if FLabel.Visible then
    begin
      R := FLabel.BoundsRect;
      if InflateRect(R,5,5) then
      begin
        Canvas.Pen.Color := clBlack;
        Canvas.Pen.Width := 2;
      end;
      Canvas.Rectangle(R);
    end;

  if FSample.Visible then
    begin
      R := FSample.BoundsRect;
      if InflateRect(R,50,50) then
      begin
        Canvas.Pen.Color := $2e7aff;
        Canvas.Pen.Width := 15;
      end;

      Canvas.Rectangle(R);
    end;
end;

procedure TGNG.ButtonLeftClick(Sender: TObject);
begin
  FButtonResponse := ssLeft;
  LogEvent('Sim');
  //if FButtonSide = ssLeft then //force right response
  FSchedule.DoResponse;
end;

procedure TGNG.ButtonRightClick(Sender: TObject);
begin
  FButtonResponse := ssRight;
  LogEvent('Não');
  //if FButtonSide = ssRight then //force right response
  FSchedule.DoResponse;
end;

procedure TGNG.ShowOperandum(Sender: TObject);
begin
  FTimer.Enabled:=False;
  FOperandum.Show;
end;

procedure TGNG.Play(ACorrection: Boolean);
var
  s1, LName : string;
  LConfiguration : TStringList;
begin
  inherited Play(ACorrection);
  LConfiguration := Configurations.SList;

  s1:= LConfiguration.Values[_Samp +_cStm] + #32;
  LName := RootMedia + ExtractDelimited(1,s1,[#32]);
  FSample := TLabelStimulus.Create(Self, Self.Parent);
  with FSample do
    begin
      LoadFromFile(LName);
      CentralizeTopMiddle;
    end;

  s1:= LConfiguration.Values[_Comp + IntToStr(1) +_cStm] + #32;
  LName := RootMedia + ExtractDelimited(1,s1,[#32]);

  FComparison := TLabelStimulus.Create(Self, Self.Parent);
  with FComparison do
    begin
      LoadFromFile(LName);
      CentralizeBottom;
    end;

  FTimer.Interval := LConfiguration.Values[_OperandumDelay].ToInteger;
  FOperandum := TGoLeftGoRight.Create(Self);
  FOperandum.OnButtonRightClick:=@ButtonRightClick;
  FOperandum.OnButtonLeftClick:=@ButtonLeftClick;
  FOperandum.Parent := Self.Parent;
  FOperandum.CentralizeBottom;

  FSchedule := TSchedule.Create(Self);
  with FSchedule do
    begin
      OnConsequence := @Consequence;
      OnResponse:= @Response;
      Load(CRF);
    end;

  case UpperCase(LConfiguration.Values[_ResponseStyle]) of
    'LEFT'   : FButtonSide := ssLeft;
    'RIGHT' : FButtonSide := ssRight;
    'NONE' : FButtonSide := ssNone;
  end;
  if Self.ClassType = TGNG then Config(Self);
end;

function TGNG.AsString: string;
begin
  Result := '';
end;

function TGNG.HasConsequence: Boolean;
begin
  Result := Self.Result <> T_NONE;
end;

procedure TGNG.TrialStart(Sender: TObject);
begin
  Mouse.CursorPos := Parent.ClientToScreen(Point(Parent.Width div 2, Parent.Height div 2));
  FSample.Show;
  FComparison.Show;
  FDataSupport.Latency := TimeStart;
  FDataSupport.StmBegin := TickCount;
  FSchedule.Start;
  if FTimer.Interval > 0 then
    begin
      FOperandum.Hide;
      FTimer.Enabled := True;
    end;
  if FButtonSide = ssNone then FLabel.Hide;
end;

procedure TGNG.WriteData(Sender: TObject);
var
  LLatency : string;
  LButtonSide : string;
begin
  inherited WriteData(Sender);

  if FDataSupport.Latency = TimeStart then
    LLatency := 'NA'
  else LLatency := TimestampToStr(FDataSupport.Latency - TimeStart);

  WriteStr(LButtonSide, FButtonSide);

  Data :=  Data +
           TimestampToStr(FDataSupport.StmBegin - TimeStart) + #9 +
           LLatency + #9 +
           TimestampToStr(FDataSupport.StmEnd - TimeStart) + #9 +
           LButtonSide;
end;

procedure TGNG.Response(Sender: TObject);
begin
  Inc(FDataSupport.Responses);
  if FDataSupport.Latency = TimeStart then
    FDataSupport.Latency := TickCount;

  if Assigned(CounterManager.OnStmResponse) then CounterManager.OnStmResponse(Sender);
  if Assigned(OnStmResponse) then OnStmResponse (Self);
end;

end.
