unit Unit1;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.Objects,

  Math, FMX.ScrollBox, FMX.Memo, Winsoft.FireMonkey.Obr, System.Actions,
  FMX.ActnList, FMX.StdActns, FMX.MediaLibrary.Actions;

type
  TForm1 = class(TForm)
    Image1: TImage;
    btnGerar: TButton;
    Button1: TButton;
    FObr1: TFObr;
    memQrCode: TMemo;
    ActionList1: TActionList;
    TakePhotoFromCameraAction1: TTakePhotoFromCameraAction;
    procedure btnGerarClick(Sender: TObject);
    procedure TakePhotoFromCameraAction1DidFinishTaking(Image: TBitmap);
  private
    { Private declarations }
    procedure GerarQRCode(const AData: TStrings; const AImage: TImage);
  public
    { Public declarations }

  end;

var
  Form1: TForm1;

implementation

uses
  FMXDelphiZXIngQRCode;

{$R *.fmx}

{ TForm1 }

procedure TForm1.btnGerarClick(Sender: TObject);
var
  StrDados : TStringList;
begin
  try
    StrDados := TStringList.Create;
    StrDados.Clear;
    StrDados.Add(' ');
    StrDados.Add('http://portal.tdevrocks.com.br');
    StrDados.Add('http://cursos.tdevrocks.com.br/treinamentos');
    StrDados.Add('tdevrocks@tdevrocks.com.br');
    StrDados.Add('(11) 9-9831-0204');
    StrDados.Add('Adriano Santos');
    StrDados.Add('TDevRocks Portal');

    GerarQRCode(StrDados, Image1);
  finally
    StrDados.DisposeOf;
    StrDados := nil;
  end;
end;

procedure TForm1.GerarQRCode(const AData: TStrings; const AImage: TImage);
const
  downsizeQuality: Integer = 2; // bigger value, better quality, slower rendering
var
  QRCode       : TDelphiZXingQRCode;
  Row          : Integer;
  Column       : Integer;
  pixelColor   : TAlphaColor;
  vBitMapData  : TBitmapData;
  pixelCount, y, x: Integer;
  columnPixel, rowPixel: Integer;
  function GetPixelCount(AWidth, AHeight: Single): Integer;
  begin
    if QRCode.Rows > 0 then
      Result := Trunc(Min(AWidth, AHeight)) div QRCode.Rows
    else
      Result := 0;
  end;
begin
  QRCode := TDelphiZXingQRCode.Create;
  try
    QRCode.Data      := AData.Text;
    QRCode.Encoding  := TQRCodeEncoding(0);
    QRCode.QuietZone := 4;
    pixelCount       := GetPixelCount(AImage.Width, AImage.Height);
    case AImage.WrapMode of
      TImageWrapMode.iwOriginal,TImageWrapMode.iwTile,TImageWrapMode.iwCenter:
      begin
        if pixelCount > 0 then
          AImage.Bitmap.SetSize(QRCode.Columns * pixelCount,
            QRCode.Rows * pixelCount);
      end;
      TImageWrapMode.iwFit:
      begin
        if pixelCount > 0 then
        begin
          AImage.Bitmap.SetSize(QRCode.Columns * pixelCount * downsizeQuality,
            QRCode.Rows * pixelCount * downsizeQuality);
          pixelCount := pixelCount * downsizeQuality;
        end;
      end;
      TImageWrapMode.iwStretch:
        raise Exception.Create('Não é uma boa ideia esticar o QRCode.');
    end;
    if AImage.Bitmap.Canvas.BeginScene then
    begin
      try
        AImage.Bitmap.Canvas.Clear(TAlphaColors.White);
        if pixelCount > 0 then
        begin
          if AImage.Bitmap.Map(TMapAccess.maWrite, vBitMapData)  then
          begin
            try
              for Row := 0 to QRCode.Rows - 1 do
              begin
                for Column := 0 to QRCode.Columns - 1 do
                begin
                  if (QRCode.IsBlack[Row, Column]) then
                    pixelColor := TAlphaColors.Black
                  else
                    pixelColor := TAlphaColors.White;
                  columnPixel := Column * pixelCount;
                  rowPixel := Row * pixelCount;
                  for x := 0 to pixelCount - 1 do
                    for y := 0 to pixelCount - 1 do
                      vBitMapData.SetPixel(columnPixel + x,
                        rowPixel + y, pixelColor);
                end;
              end;
            finally
              AImage.Bitmap.Unmap(vBitMapData);
            end;
          end;
        end;
      finally
        AImage.Bitmap.Canvas.EndScene;
      end;
    end;
  finally
    QRCode.Free;
  end;

end;

procedure TForm1.TakePhotoFromCameraAction1DidFinishTaking(Image: TBitmap);
var
  I : Integer;
  Barcode: TObrSymbol;
begin
  memQrCode.Lines.Clear;
  Image1.Bitmap.Assign(Image);

  FObr1.Active := True;
  FObr1.Picture.Assign(Image);
  FObr1.Scan;
  if FObr1.BarcodeCount = 0 then
    memQrCode.Lines.Add('Nenhum código encontrado')
  else
  begin
    for I := 0 to Pred(FObr1.BarcodeCount) do
    begin
      Barcode := FObr1.Barcode[I];
      memQrCode.Lines.Add(
        Barcode.SymbologyName +
        Barcode.SymbologyAddonName + ' ' +
        Barcode.OrientationName + ' ' +
        Barcode.DataUtf8
      )
    end;
  end;
end;

end.
