unit Consequences;

{$mode objfpc}{$H+}

// linux dependencies: sudo apt install zlib1g-dev libopenal-dev libvorbis-dev

interface

uses
  Classes, SysUtils
  , CastleSoundEngine
  ;

type

  TConsequence = record
    //Visual : TStimulusFigure;
    Auditive : TSoundBuffer;
    //Interval : integer;
  end;

function NextConsequence(AHit : Boolean) : TConsequence;
procedure Play(AConsequence : TConsequence);

implementation

uses
  FileMethods
  , Session.Configuration.GlobalContainer
  ;

const
  //ImageFilterHit  = 'acerto*.bmp;acerto*.BMP;acerto*.jpg;acerto*.JPG;acerto*.png;acerto*.PNG;';
  //ImageFilterMiss = 'erro*.bmp;erro*.BMP;erro*.jpg;erro*.JPG;erro*.png;erro*.PNG;';
  AudioFilterHit  = 'acerto*.wav;acerto*.WAV;acerto*.ogg;acerto*.OGG;';
  AudioFilterMiss = 'erro*.wav;erro*.WAV;erro*.ogg;erro*.OGG;';
  FolderConsequences = 'consequencias';

var
  //ImageFilesHit  : TStringArray;
  //ImageFilesMiss : TStringArray;
  AudioFilesHit : TStringArray;
  AudioFilesMiss : TStringArray;
  //VisualsHit : array of TStimulusFigure;
  AudiblesHit : array of TSoundBuffer;
  //VisualsMiss : array of TStimulusFigure;
  AudiblesMiss : array of TSoundBuffer;

function NextConsequence(AHit : Boolean) : TConsequence;
begin
  if AHit then
    begin
      if Length(AudiblesHit) = 0 then Exit;

      if Length(AudiblesHit) = 1 then
      begin
        Result.Auditive := AudiblesHit[0];
        Exit;
      end;

      if Length(AudiblesHit) > 1 then
        Result.Auditive := AudiblesHit[Random(Length(AudiblesHit))];
    end
  else
    begin
      if Length(AudiblesMiss) = 0 then Exit;

      if Length(AudiblesMiss) = 1 then
      begin
        Result.Auditive := AudiblesMiss[0];
        Exit;
      end;

      if Length(AudiblesMiss) > 0 then
        Result.Auditive := AudiblesMiss[Random(Length(AudiblesMiss))];
    end;
end;

procedure Play(AConsequence: TConsequence);
begin
  //AConsequence.Visual.Start;
  SoundEngine.PlaySound(AConsequence.Auditive);
end;

procedure LoadBuffers(AudiosHit, AudiosMiss : TStringArray);
var
  i : integer;
begin
  SetLength(AudiblesHit, Length(AudiosHit));
  for i := Low(AudiosHit) to High(AudiosHit) do
  begin
    AudiblesHit[i] := SoundEngine.LoadBuffer(AudiosHit[i]);
  end;

  SetLength(AudiblesMiss, Length(AudiosMiss));
  for i := Low(AudiosMiss) to High(AudiosMiss) do
  begin
    AudiblesMiss[i] := SoundEngine.LoadBuffer(AudiosMiss[i]);
  end;
end;

initialization
  FindFilesFor(AudioFilesHit,
    GlobalContainer.RootMedia+FolderConsequences, AudioFilterHit);
  FindFilesFor(AudioFilesMiss,
    GlobalContainer.RootMedia+FolderConsequences, AudioFilterMiss);
  LoadBuffers(AudioFilesHit, AudioFilesMiss);


end.

