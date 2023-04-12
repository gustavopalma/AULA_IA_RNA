unit uPerceptron;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ComCtrls, Buttons,
  csvdocument, ExtCtrls, StdCtrls, Grids, Types,LazFileUtils;

type

  { TForm1 }

  TForm1 = class(TForm)
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    SpeedButton4: TSpeedButton;
    SpeedButton5: TSpeedButton;
    grid_exec_dados: TStringGrid;
    SpeedButton6: TSpeedButton;
    txt_n_treinos: TLabeledEdit;
    txt_max_epocas: TLabeledEdit;
    txt_tx_aprendizado: TLabeledEdit;
    SpeedButton3: TSpeedButton;
    grid_data_treino: TStringGrid;
    grid_peso_fim: TStringGrid;
    grid_peso_ini: TStringGrid;
    procedure FormCreate(Sender: TObject);
    procedure SpeedButton3Click(Sender: TObject);
    procedure SpeedButton4Click(Sender: TObject);
    procedure SpeedButton5Click(Sender: TObject);
    procedure SpeedButton6Click(Sender: TObject);
  private
    FDadosNormalizados: Boolean;
    FDadosNormalizadosExec: Boolean;
  published
    OpenDialog1: TOpenDialog;
    SpeedButton1: TSpeedButton;
    SpeedButton2: TSpeedButton;
    ToolBar1: TToolBar;
    procedure SpeedButton1Click(Sender: TObject);
    procedure LoadGridFromCSVFile(Grid: TStringGrid;AFilename: string;
      ADelimiter:Char=','; WithHeader:boolean=true;AddRows:boolean=true);
    procedure SpeedButton2Click(Sender: TObject);
    property DadosNormalizados : Boolean read FDadosNormalizados write FDadosNormalizados;
    property DadosNormalizadosExec : Boolean read FDadosNormalizadosExec write FDadosNormalizadosExec;
  private

  public

  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.FormCreate(Sender: TObject);
begin
  FDadosNormalizados:= False;
end;





procedure TForm1.SpeedButton3Click(Sender: TObject);
var
  xn : array [0..2] of Real;
  wn : array [0..2] of Real;
  i,j, linha, maximo_epocas, epoca_atual,treinos, total_treinos : Integer;
  u, taxa_aprendizagem, limiar: Real;
  y,s_desejada: Integer;
  error: boolean;
  erro: double;
begin

    if not FDadosNormalizados then
    begin
      showmessage('Carregue e Normalize os Dados de Treinamento');
      exit;
    end;

    if txt_n_treinos.Text = EmptyStr then
    begin
      showmessage('Preencha o Número de Treinamentos');
      exit;
    end;

    total_treinos:= StrToInt(txt_n_treinos.Text); ;

    if txt_max_epocas.Text = EmptyStr then
    begin
      showmessage('Preencha o Número Máximo de épocas');
      exit;
    end;

    maximo_epocas := StrToInt(txt_max_epocas.Text);


    if txt_tx_aprendizado.Text = EmptyStr then
    begin
      showmessage('Preencha a Taxa de Aprendizado');
      exit;
    end;

    maximo_epocas := StrToInt(txt_max_epocas.Text);
    taxa_aprendizagem := StrToFloat(txt_tx_aprendizado.text);

  for treinos:= 0 to total_treinos -1 do
   begin
    epoca_atual := 0;
    {
     Faz o sorteio inicial dos pesos
    }
    for i := 0 to High(wn) do
     begin
      Randomize;
      wn[i] := Random(100) / 100;
      grid_peso_ini.Cells[i + 2, treinos + 1] := FloatToStr(wn[i]);
      sleep(5);
     end;

    Randomize;
    limiar := Random(100) / 100;
    grid_peso_ini.Cells[1, treinos + 1] := FloatToStr(limiar);
    error:=True;
    //roda o total de épocas
    while ((epoca_atual < maximo_epocas) and (error)) do
     begin
      error:=False;
      //Lê todos os dados de treinamento
      for linha := 1 to grid_data_treino.RowCount -1 do
       begin
        //Carrega as entradas
        i := 0;
        for j := 1 to grid_data_treino.ColCount -2 do
         begin
           xn[i] := StrToFloat(grid_data_treino.Cells[j,linha]);
           inc(i);
         end;

         //Carrega as entradas
         u := 0;
         for i := 0 to High(xn) do
          begin
           u := u + (xn[i] * wn[i]);
          end;

           u := u - limiar;

          //aplica a função de ativação
          if u >= 0 then
           y := 1
          else
           y := -1;

          s_desejada := Trunc(StrToFloat(grid_data_treino.Cells[4,linha]));

          if y <> s_desejada then
           begin
            for i := 0 to High(wn) do
             begin
               erro := (s_desejada - y);
               wn[i] := wn[i] + (taxa_aprendizagem * xn[i] * erro );
               limiar := limiar - (taxa_aprendizagem * erro );;
             end;
             error:= True;
           end;
      end;
      if not Error then
       begin
          grid_peso_fim.Cells[5, treinos + 1] := FloatToStr(epoca_atual);
       end;
      Inc(epoca_atual);
     end;
      for i := 0 to High(wn) do
     begin
       grid_peso_fim.Cells[i + 2, treinos + 1] := FloatToStr(wn[i]);
     end;
    if grid_peso_fim.Cells[5, treinos + 1] = EmptyStr then
      grid_peso_fim.Cells[5, treinos + 1]:= FloatToStr(maximo_epocas);
    grid_peso_fim.Cells[1, treinos + 1] := FloatToStr(limiar);
   end;
end;

procedure TForm1.SpeedButton4Click(Sender: TObject);
var
 xn : array [0..2] of Real;
 wn : array [0..2] of Real;
 i,j,y, rodada_treino, amostra_atual : integer;
 u : real;
begin
  if not FDadosNormalizadosExec then
   begin
    showmessage('Carregue e normalize os dados de execução !');
    exit;
   end;
  for amostra_atual := 1 to grid_exec_dados.RowCount - 1 do
   begin
    // carrega as entradas
    for j := 1 to 3 do
     begin
      xn[j - 1] := StrToFloat(grid_exec_dados.cells[j,amostra_atual]);
     end;

     //carrega os pesos
     for rodada_treino := 1 to grid_peso_fim.RowCount - 1 do
      begin
       for j := 2 to 4 do
        begin
         wn[j - 2] := StrToFloat(grid_peso_fim.Cells[j,rodada_treino]);
        end;

       u := 0;
       for i := 0 to High(xn) do
       begin
        u := u + (xn[i] * wn[i]);
       end;

       //aplica a função de ativação
       if u >= 0 then
        y := 1
       else
        y := -1;

       grid_exec_dados.cells[rodada_treino + 3, amostra_atual] := IntToStr(y);
     end;
   end;
end;

procedure TForm1.SpeedButton5Click(Sender: TObject);
var
  j : integer;
begin
   if OpenDialog1.Execute then
   begin
     LoadGridFromCSVFile(grid_exec_dados,OpenDialog1.FileName,';');
     grid_exec_dados.ColCount := grid_exec_dados.ColCount + 5;
     for j := 0 to 4 do
      begin
         grid_exec_dados.Cells[j + 4, 0 ] := 'y(t' + IntToStr(j + 1) + ')';
      end;
   end;
  FDadosNormalizados:=False;
end;

procedure TForm1.SpeedButton6Click(Sender: TObject);
var
  i, j : Integer;
  maior, valor : Real;
begin
  maior := 1;
  for i := 1 to 3 do
    begin
      for j := 1 to grid_exec_dados.RowCount - 1 do
       begin
         valor := StrToFloat(grid_exec_dados.Cells[i,j]);
         if valor > maior then
           begin
             maior := valor;
           end;
        end;
    end;
   for i := 1 to 3 do
    begin
      for j := 1 to grid_exec_dados.RowCount - 1 do
       begin
         valor := StrToFloat(grid_exec_dados.Cells[i,j]) / maior;
         grid_exec_dados.Cells[i,j] := FloatToStr(valor);
       end;
    end;
   FDadosNormalizadosExec:= True;
end;

procedure TForm1.SpeedButton1Click(Sender: TObject);
begin
  if OpenDialog1.Execute then
   begin
     LoadGridFromCSVFile(grid_data_treino,OpenDialog1.FileName,';');
     grid_data_treino.ColCount := grid_data_treino.ColCount - 1;
   end;
  FDadosNormalizados:=False;
end;

procedure TForm1.LoadGridFromCSVFile(Grid: TStringGrid; AFilename: string;
  ADelimiter: Char; WithHeader: boolean; AddRows: boolean);
const
  DefaultRowCount=10; //Number of rows to show by default
var
  FileStream: TFileStream;
  Parser: TCSVParser;
  RowOffset: integer;
begin
  Grid.BeginUpdate;
  // Reset the grid:
  Grid.Clear;
  Grid.RowCount:=DefaultRowCount;
  Grid.ColCount:=6; //Vaguely sensible
  if not(FileExistsUTF8(AFileName)) then exit;

  Parser:=TCSVParser.Create;
  FileStream := TFileStream.Create(AFilename, fmOpenRead+fmShareDenyWrite);
  try
    Parser.Delimiter:=ADelimiter;
    Parser.SetSource(FileStream);

    // If the grid has fixed rows, those will not receive data, so we need to
    // calculate the offset
    RowOffset:=Grid.FixedRows;
    // However, if we have a header row in our CSV data, we need to
    // discount that
    if WithHeader then RowOffset:=RowOffset-1;

    while Parser.ParseNextCell do
    begin
      // Stop if we've filled all existing rows. Todo: check for fixed grids etc, but not relevant for our case
      if AddRows=false then
        if Parser.CurrentRow+1>Grid.RowCount then break; //VisibleRowCount doesn't seem to work.

      // Widen grid if necessary. Slimming the grid will come after import done.
      if Grid.Columns.Enabled then
      begin
        if Grid.Columns.VisibleCount<Parser.CurrentCol+1 then Grid.Columns.Add;
      end
      else
      begin
        if Grid.ColCount<Parser.CurrentCol+1 then Grid.ColCount:=Parser.CurrentCol+1;
      end;

      // If header data found, and a fixed row is available, set the caption
      if (WithHeader) and
        (Parser.CurrentRow=0) and
        (Parser.CurrentRow<Grid.FixedRows-1) then
      begin
        // Assign header data to the first fixed row in the grid:
        Grid.Columns[Parser.CurrentCol].Title.Caption:=Parser.CurrentCellText;
      end;

      // Actual data import into grid cell, minding fixed rows and header
      if Grid.RowCount<Parser.CurrentRow+1 then
        Grid.RowCount:=Parser.CurrentRow+1;
      Grid.Cells[Parser.CurrentCol,Parser.CurrentRow+RowOffset]:=Parser.CurrentCellText;
    end;

    // Now we know the widest row in the import, we can snip the grid's
    // columns if necessary.
    if Grid.Columns.Enabled then
    begin
      while Grid.Columns.VisibleCount>Parser.MaxColCount do
      begin
        Grid.Columns.Delete(Grid.Columns.Count-1);
      end;
    end
    else
    begin
      if Grid.ColCount>Parser.MaxColCount then
        Grid.ColCount:=Parser.MaxColCount;
    end;

  finally
    Parser.Free;
    FileStream.Free;
    Grid.EndUpdate;
  end;
end;

procedure TForm1.SpeedButton2Click(Sender: TObject);
var
  i, j : Integer;
  maior, valor : Real;
begin
  maior := 1;
  for i := 1 to grid_data_treino.ColCount - 1 do
    begin
      for j := 1 to grid_data_treino.RowCount - 1 do
       begin
         valor := StrToFloat(grid_data_treino.Cells[i,j]);
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
         valor := StrToFloat(grid_data_treino.Cells[i,j]) / maior;
         grid_data_treino.Cells[i,j] := FloatToStr(valor);
       end;
    end;
   FDadosNormalizados:= True;
end;



end.

