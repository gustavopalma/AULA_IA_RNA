unit uAdaline;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ComCtrls, StdCtrls,
  Buttons, Grids, ExtCtrls, csvdocument, BufDataset, DB, memds, LazFileUtils,
  TAGraph, TASeries, Math;

type

  { TForm1 }

  TForm1 = class(TForm)
    Chart1: TChart;
    Chart1LineSeries1: TLineSeries;
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    Label1: TLabel;
    Label2: TLabel;
    MemDataset1: TMemDataset;
    n_treinamentos: TLabeledEdit;
    maximo_epocas: TLabeledEdit;
    SpeedButton3: TSpeedButton;
    grid_execucao: TStringGrid;
    SpeedButton4: TSpeedButton;
    SpeedButton5: TSpeedButton;
    SpeedButton6: TSpeedButton;
    tx_aprendizado: TLabeledEdit;
    precisao: TLabeledEdit;
    OpenDialog1: TOpenDialog;
    SpeedButton1: TSpeedButton;
    grid_data_treino: TStringGrid;
    SpeedButton2: TSpeedButton;
    grid_pesos_iniciais: TStringGrid;
    grid_pesos_finais: TStringGrid;
    ToolBar1: TToolBar;
    procedure grid_pesos_iniciaisSelectCell(Sender: TObject;
      aCol, aRow: integer; var CanSelect: boolean);
    procedure SpeedButton1Click(Sender: TObject);
    procedure SpeedButton2Click(Sender: TObject);
    procedure SpeedButton3Click(Sender: TObject);
    procedure SpeedButton4Click(Sender: TObject);
    procedure SpeedButton5Click(Sender: TObject);
    procedure SpeedButton6Click(Sender: TObject);
  private
    FDadosNormalizados: boolean;
    procedure LoadGridFromCSVFile(Grid: TStringGrid; AFilename: string;
      ADelimiter: char = ','; WithHeader: boolean = True; AddRows: boolean = True);
  public
    property DadosNormalizados: boolean read FDadosNormalizados
      write FDadosNormalizados;
  end;

var
  Form1: TForm1;
  TError1: array of real;
  TError2: array of real;
  TError3: array of real;
  TError4: array of real;
  TError5: array of real;
  TErrorS1: array of real;
  TErrorS2: array of real;
  TErrorS3: array of real;
  TErrorS4: array of real;
  TErrorS5: array of real;

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.SpeedButton1Click(Sender: TObject);
begin
  if OpenDialog1.Execute then
  begin
    LoadGridFromCSVFile(grid_data_treino, OpenDialog1.FileName, ';');
  end;
  FDadosNormalizados := False;
end;

procedure TForm1.grid_pesos_iniciaisSelectCell(Sender: TObject;
  aCol, aRow: integer; var CanSelect: boolean);
var
  i: integer;
begin
  case aRow of
    1: begin
      with Chart1.Series[0] as TLineSeries do
        Clear;
      for i := 0 to High(TErrorS1) do
      begin
        with Chart1.Series[0] as TLineSeries do
        begin
          AddXY(i, TErrorS1[i]);
        end;
      end;
    end;
    2: begin
      with Chart1.Series[0] as TLineSeries do
        Clear;
      for i := 0 to High(TErrorS2) do
      begin
        with Chart1.Series[0] as TLineSeries do
        begin
          AddXY(i, TErrorS2[i]);
        end;
      end;
    end;
    3: begin
      with Chart1.Series[0] as TLineSeries do
        Clear;
      for i := 0 to High(TErrorS3) do
      begin
        with Chart1.Series[0] as TLineSeries do
        begin
          AddXY(i, TErrorS3[i]);
        end;
      end;
    end;
    4: begin
      with Chart1.Series[0] as TLineSeries do
        Clear;
      for i := 0 to High(TErrorS4) do
      begin
        with Chart1.Series[0] as TLineSeries do
        begin
          AddXY(i, TErrorS4[i]);
        end;
      end;
    end;
    5: begin
      with Chart1.Series[0] as TLineSeries do
        Clear;
      for i := 0 to High(TErrorS5) do
      begin
        with Chart1.Series[0] as TLineSeries do
        begin
          AddXY(i, TErrorS5[i]);
        end;
      end;
    end;
  end;
end;

procedure TForm1.SpeedButton2Click(Sender: TObject);
var
  i, j: integer;
  maior, valor: real;
begin
  maior := 1;
  for i := 1 to grid_data_treino.ColCount - 1 do
  begin
    for j := 1 to grid_data_treino.RowCount - 1 do
    begin
      valor := StrToFloat(grid_data_treino.Cells[i, j]);
      if valor > maior then
      begin
        maior := valor;
      end;
    end;
  end;
  for i := 1 to grid_data_treino.ColCount - 2 do
  begin
    for j := 1 to grid_data_treino.RowCount - 1 do
    begin
      valor := StrToFloat(grid_data_treino.Cells[i, j]) / maior;
      grid_data_treino.Cells[i, j] := FloatToStr(valor);
    end;
  end;
  FDadosNormalizados := True;
end;

procedure TForm1.SpeedButton3Click(Sender: TObject);
var
  wn: array [0..3] of real;
  wp: array [0..3] of real;
  xn: array [0..3] of real;
  dn: array [0..3] of real;
  b, y, Saida_desejada, saida_calculada, taxa_aprendizado, db, aux: real;
  i, j, epoca_atual, Total_epocas, amostra_atual, total_treinamentos: integer;
  treinamento_atual, s: integer;
  error: boolean;
begin

  Total_epocas := StrToInt(maximo_epocas.Text);

  taxa_aprendizado := StrToFloat(tx_aprendizado.Text);

  total_treinamentos := StrToInt(n_treinamentos.Text);

  grid_pesos_iniciais.RowCount := total_treinamentos + 1;
  grid_pesos_finais.RowCount := total_treinamentos + 1;

  for treinamento_atual := 0 to total_treinamentos - 1 do
  begin
    for i := 0 to High(wn) do
    begin
      Randomize;
      wn[i] := Random(100) / 100;
      grid_pesos_iniciais.Cells[i + 2, treinamento_atual + 1] := FloatToStr(wn[i]);
      Sleep(350);
    end;
    Randomize;
    b := Random(100) / 100;
    grid_pesos_iniciais.Cells[1, treinamento_atual + 1] := FloatToStr(b);

    error := False;
    for epoca_atual := 0 to Total_epocas do
    begin
      if ((epoca_atual <> 0) and (not Error)) then
        break;

      Error := False;
      for amostra_atual := 1 to grid_data_treino.RowCount - 1 do
      begin
        for j := 1 to grid_data_treino.ColCount - 2 do
        begin
          aux := StrToFloat(grid_data_treino.Cells[j, amostra_atual]);
          xn[j - 1] := aux;
        end;
        for i := 0 to High(dn) do
        begin
          dn[i] := 0;
        end;
        Saida_desejada := StrToFloat(grid_data_treino.Cells[5, amostra_atual]);

        saida_calculada := 0;
        y := 0;
        for i := 0 to High(wn) do
        begin
          saida_calculada := saida_calculada + xn[i] * wn[i];
        end;
        saida_calculada := saida_calculada + b;

        if saida_calculada < 0 then
          y := -1
        else
          y := 1;

        for i := 0 to High(dn) do
        begin
          dn[i] := taxa_aprendizado * (Saida_desejada - y) * xn[i];
        end;

        db := taxa_aprendizado * (Saida_desejada - y);

        if Saida_desejada - y <> 0 then
          error := True
        else
          continue;

        //reajusta os vetores de peso
        for i := 0 to High(wn) do
        begin
          wp[i] := wn[i];
          wn[i] := wn[i] + dn[i];
          case treinamento_atual of
            0: begin
              SetLength(Terror1, Length(TError1) + 1);
              TError1[Length(TError1) - 1] := wn[i] - wp[i];
              SetLength(TerrorS1, Length(TErrorS1) + 1);
              for s := 0 to High(TError1) do
              begin
                TErrorS1[Length(TErrorS1) - 1] :=
                  TErrorS1[Length(TErrorS1) - 1] + TError1[s];
              end;

            end;
            1: begin
              SetLength(Terror2, Length(TError2) + 1);
              TError2[Length(TError2) - 1] := wn[i] - wp[i];
              SetLength(TerrorS2, Length(TErrorS2) + 1);
              for s := 0 to High(TError2) do
              begin
                TErrorS2[Length(TErrorS2) - 1] :=
                  TErrorS2[Length(TErrorS2) - 1] + TError2[s];
              end;
            end;
            2: begin
              SetLength(Terror3, Length(TError3) + 1);
              TError3[Length(TError3) - 1] := wn[i] - wp[i];
              SetLength(TerrorS3, Length(TErrorS3) + 1);
              for s := 0 to High(TError3) do
              begin
                TErrorS3[Length(TErrorS3) - 1] :=
                  TErrorS3[Length(TErrorS3) - 1] + TError3[s];
              end;
            end;
            3: begin
              SetLength(Terror4, Length(TError4) + 1);
              TError4[Length(TError4) - 1] := wn[i] - wp[i];
              SetLength(TerrorS4, Length(TErrorS4) + 1);
              for s := 0 to High(TError4) do
              begin
                TErrorS4[Length(TErrorS4) - 1] :=
                  TErrorS4[Length(TErrorS4) - 1] + TError4[s];
              end;
            end;
            4: begin
              SetLength(Terror5, Length(TError5) + 1);
              TError5[Length(TError5) - 1] := wn[i] - wp[i];
              SetLength(TerrorS5, Length(TErrorS5) + 1);
              for s := 0 to High(TError5) do
              begin
                TErrorS5[Length(TErrorS5) - 1] :=
                  TErrorS5[Length(TErrorS5) - 1] + TError5[s];
              end;
            end;
          end;
        end;
        b := b + db;

      end;
    end;
    grid_pesos_finais.Cells[1, treinamento_atual + 1] := FloatToStr(b);
    for j := 2 to grid_pesos_finais.ColCount - 2 do
    begin
      grid_pesos_finais.Cells[j, treinamento_atual + 1] := FloatToStr(wn[j - 2]);
    end;
    grid_pesos_finais.Cells[6, treinamento_atual + 1] := IntToStr(epoca_atual);
  end;
end;

procedure TForm1.SpeedButton4Click(Sender: TObject);
begin
  if OpenDialog1.Execute then
  begin
    LoadGridFromCSVFile(grid_execucao, OpenDialog1.FileName, ';');
  end;
end;

procedure TForm1.SpeedButton5Click(Sender: TObject);
var
  i, j: integer;
  maior, valor: real;
begin
  maior := 1;
  for i := 1 to 4 do
  begin
    for j := 1 to grid_execucao.RowCount - 1 do
    begin
      valor := StrToFloat(grid_execucao.Cells[i, j]);
      if valor > maior then
      begin
        maior := valor;
      end;
    end;
  end;
  for i := 1 to 4 do
  begin
    for j := 1 to grid_execucao.RowCount - 1 do
    begin
      valor := StrToFloat(grid_execucao.Cells[i, j]) / maior;
      grid_execucao.Cells[i, j] := FloatToStr(valor);
    end;
  end;
end;

procedure TForm1.SpeedButton6Click(Sender: TObject);
var
  xn : array [0..3] of Real;
  wn : array [0..3] of Real;
  j,y, i, treinamento_atual, TotalTreinamentos, amostra_atual : Integer;
  rodada_treino : Integer;
  saida_calculada : Real;
begin
  TotalTreinamentos := StrToInt(n_treinamentos.text);

 for amostra_atual := 1 to grid_execucao.RowCount - 1 do
  begin
   for j := 1 to 4 do
    begin
     xn[j - 1] := StrToFloat(grid_execucao.cells[j,amostra_atual]);
    end;
      //carrega os pesos
     for rodada_treino := 1 to 4 do
      begin
       for j := 2 to 4 do
        begin
         wn[j - 2] := StrToFloat(grid_pesos_finais.Cells[j,rodada_treino]);
        end;

        saida_calculada := 0;
        y := 0;
        for i := 0 to High(wn) do
        begin
          saida_calculada := saida_calculada + xn[i] * wn[i];
        end;

        if saida_calculada < 0 then
          y := -1
        else
          y := 1;

       grid_execucao.cells[rodada_treino + 4, amostra_atual] := IntToStr(y);
     end;
  end;
end;



procedure TForm1.LoadGridFromCSVFile(Grid: TStringGrid; AFilename: string;
  ADelimiter: char; WithHeader: boolean; AddRows: boolean);
const
  DefaultRowCount = 10; //Number of rows to show by default
var
  FileStream: TFileStream;
  Parser: TCSVParser;
  RowOffset: integer;
begin
  Grid.BeginUpdate;
  // Reset the grid:
  Grid.Clear;
  Grid.RowCount := DefaultRowCount;
  Grid.ColCount := 6; //Vaguely sensible
  if not (FileExistsUTF8(AFileName)) then exit;

  Parser := TCSVParser.Create;
  FileStream := TFileStream.Create(AFilename, fmOpenRead + fmShareDenyWrite);
  try
    Parser.Delimiter := ADelimiter;
    Parser.SetSource(FileStream);

    // If the grid has fixed rows, those will not receive data, so we need to
    // calculate the offset
    RowOffset := Grid.FixedRows;
    // However, if we have a header row in our CSV data, we need to
    // discount that
    if WithHeader then RowOffset := RowOffset - 1;

    while Parser.ParseNextCell do
    begin
      // Stop if we've filled all existing rows. Todo: check for fixed grids etc, but not relevant for our case
      if AddRows = False then
        if Parser.CurrentRow + 1 > Grid.RowCount then break;
      //VisibleRowCount doesn't seem to work.

      // Widen grid if necessary. Slimming the grid will come after import done.
      if Grid.Columns.Enabled then
      begin
        if Grid.Columns.VisibleCount < Parser.CurrentCol + 1 then Grid.Columns.Add;
      end
      else
      begin
        if Grid.ColCount < Parser.CurrentCol + 1 then Grid.ColCount := Parser.CurrentCol + 1;
      end;

      // If header data found, and a fixed row is available, set the caption
      if (WithHeader) and (Parser.CurrentRow = 0) and
        (Parser.CurrentRow < Grid.FixedRows - 1) then
      begin
        // Assign header data to the first fixed row in the grid:
        Grid.Columns[Parser.CurrentCol].Title.Caption := Parser.CurrentCellText;
      end;

      // Actual data import into grid cell, minding fixed rows and header
      if Grid.RowCount < Parser.CurrentRow + 1 then
        Grid.RowCount := Parser.CurrentRow + 1;
      Grid.Cells[Parser.CurrentCol, Parser.CurrentRow + RowOffset] := Parser.CurrentCellText;
    end;

    // Now we know the widest row in the import, we can snip the grid's
    // columns if necessary.
    if Grid.Columns.Enabled then
    begin
      while Grid.Columns.VisibleCount > Parser.MaxColCount do
      begin
        Grid.Columns.Delete(Grid.Columns.Count - 1);
      end;
    end
    else
    begin
      if Grid.ColCount > Parser.MaxColCount then
        Grid.ColCount := Parser.MaxColCount;
    end;

  finally
    Parser.Free;
    FileStream.Free;
    Grid.EndUpdate;
  end;
end;


end.
