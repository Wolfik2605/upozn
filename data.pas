unit data;

interface

uses
  System.SysUtils, System.Classes, Math;

function FindPlayerByNumber(Number: Integer): Integer;
function GetTeamNameByCode(Code: Integer): string;

type
  TTeam = record
    Code: Integer;
    Name: string;
    Country: string;
    TableNumber: Integer;
  end;

  TPlayer = record
    ID: Integer;      // Уникальный идентификатор
    Name: string;
    TeamCode: Integer; // Ссылка на команду
    Position: string;  // Амплуа
    Number: Integer;
  end;

  TStatistic = record
    PlayerID: Integer;  // Ссылка на ID игрока
    Goals: Integer;
    Assists: Integer;
    Points: Integer;    // Вычисляемое поле: голы + передачи
  end;

  TPenalty = record
    PlayerID: Integer;  // Ссылка на ID игрока
    Minutes: Integer;
  end;

  TSortField = (sfName, sfGoals, sfAssists, sfPoints, sfPenalties);
  TSortOrder = (soAscending, soDescending);
  TSearchField = (sfByName, sfById, sfByPenalties);

  // Структура для хранения всех данных игрока
  TPlayerData = record
    Player: TPlayer;
    Statistic: TStatistic;
    Penalty: TPenalty;
  end;

var
  PlayersData: array of TPlayerData;  // Основной массив данных
  TeamsData: array of TTeam;
  IsDataLoaded: Boolean;
  NextPlayerID: Integer;  // Счетчик для генерации уникальных ID
  NextTeamCode: Integer;

procedure InitializeData;
procedure ClearData;
function ReadDataFromFile(const FileName: string): Boolean;
procedure ShowPlayers(Page: Integer; PageSize: Integer = 10);
function GetTotalPages(PageSize: Integer): Integer;
procedure SortPlayers(Field: TSortField; Order: TSortOrder);
procedure SearchPlayers(Field: TSearchField; const Value: string; var FoundIndices: TArray<Integer>);
function AddPlayer(const Name: string; const TeamName: string; Number: Integer;
                  Goals: Integer; Assists: Integer; PenaltyMinutes: Integer;
                  const PenaltyReason: string): Boolean;
function DeletePlayer(PlayerNumber: Integer): Boolean;
function UpdatePlayer(PlayerNumber: Integer; const NewName: string; const NewTeam: string;
                     NewGoals: Integer; NewAssists: Integer; NewPenaltyMinutes: Integer;
                     const NewPenaltyReason: string): Boolean;
procedure FindMostSuccessfulPlayers(var FoundIndices: TArray<Integer>);
procedure FindPlayersWithMaxPenalties(var FoundIndices: TArray<Integer>);
function SaveDataToFile(const FileName: string): Boolean;
procedure GetTop10SuccessfulPlayers(var Indices: TArray<Integer>);
procedure GetTop10PenaltyPlayers(var Indices: TArray<Integer>);
procedure GetBestAndPenaltyPlayersByTeam(var BestIndices, PenaltyIndices: TArray<Integer>);
procedure ViewTeams;
function AddTeam(const Name, Country: string; TableNumber: Integer): Boolean;
function DeleteTeam(Code: Integer): Boolean;
function EditTeam(Code: Integer; const NewName, NewCountry: string; NewTableNumber: Integer): Boolean;

implementation

procedure InitializeData;
begin
  SetLength(PlayersData, 0);
  SetLength(TeamsData, 0);
  IsDataLoaded := False;
  NextPlayerID := 1;
  NextTeamCode := 1;
end;

procedure ClearData;
begin
  SetLength(PlayersData, 0);
  SetLength(TeamsData, 0);
  IsDataLoaded := False;
  NextPlayerID := 1;
  NextTeamCode := 1;
end;

function FindPlayerByNumber(Number: Integer): Integer;
var
  i: Integer;
begin
  Result := -1;
  if (not IsDataLoaded) or (Length(PlayersData) = 0) then Exit;
  for i := 0 to High(PlayersData) do
    if PlayersData[i].Player.Number = Number then
    begin
      Result := i;
      Break;
    end;
end;

function IsNameUnique(const Name: string; ExcludeID: Integer = -1): Boolean;
var
  i: Integer;
begin
  Result := True;
  for i := 0 to High(PlayersData) do
    if (CompareText(PlayersData[i].Player.Name, Name) = 0) and
       (PlayersData[i].Player.ID <> ExcludeID) then
    begin
      Result := False;
      Break;
    end;
end;

function ReadDataFromFile(const FileName: string): Boolean;
var
  F: TextFile;
  Line: string;
  Parts: TArray<string>;
  PlayerData: TPlayerData;
  LineNumber: Integer;
begin
  Result := False;
  if not FileExists(FileName) then
  begin
    Writeln('Ошибка: Файл не найден');
    Exit;
  end;

  AssignFile(F, FileName);
  Reset(F);
  if EOF(F) then
  begin
    Writeln('Файл не содержит данных');
    CloseFile(F);
    Exit;
  end;

  LineNumber := 0;
  while not EOF(F) do
  begin
    Inc(LineNumber);
    Readln(F, Line);
    Parts := Line.Split([';']);

    if Length(Parts) < 4 then
    begin
      Writeln('Предупреждение: Неверный формат данных в строке ', LineNumber);
      Continue;
    end;

    // Без try except, просто проверяем через TryStrToInt
    if not TryStrToInt(Parts[0], PlayerData.Player.Number) then
    begin
      Writeln('Ошибка: Некорректный номер игрока в строке ', LineNumber);
      Continue;
    end;
    PlayerData.Player.ID := NextPlayerID;
    Inc(NextPlayerID);
    PlayerData.Player.Name := Parts[1];
    PlayerData.Player.TeamCode := StrToIntDef(Parts[2], -1);

    if not TryStrToInt(Parts[3], PlayerData.Statistic.Goals) then
    begin
      Writeln('Ошибка: Некорректное количество голов в строке ', LineNumber);
      Continue;
    end;
    if not TryStrToInt(Parts[4], PlayerData.Statistic.Assists) then
    begin
      Writeln('Ошибка: Некорректное количество передач в строке ', LineNumber);
      Continue;
    end;
    PlayerData.Statistic.PlayerID := PlayerData.Player.ID;
    PlayerData.Statistic.Points := PlayerData.Statistic.Goals + PlayerData.Statistic.Assists;

    if not TryStrToInt(Parts[5], PlayerData.Penalty.Minutes) then
    begin
      Writeln('Ошибка: Некорректное количество штрафных минут в строке ', LineNumber);
      Continue;
    end;
    PlayerData.Penalty.PlayerID := PlayerData.Player.ID;

    // Проверка уникальности номера
    if FindPlayerByNumber(PlayerData.Player.Number) <> -1 then
    begin
      Writeln('Предупреждение: Игрок с номером ', PlayerData.Player.Number, 
             ' уже существует в строке ', LineNumber);
      Continue;
    end;

    // Добавление данных в массив
    SetLength(PlayersData, Length(PlayersData) + 1);
    PlayersData[High(PlayersData)] := PlayerData;
  end;

  CloseFile(F);
  IsDataLoaded := True;
  Result := True;
  Writeln('Данные успешно загружены');
end;

procedure ShowPlayers(Page: Integer; PageSize: Integer = 10);
var
  i, StartIndex, EndIndex: Integer;
  TotalPages: Integer;
begin
  if (not IsDataLoaded) or (Length(PlayersData) = 0) then
  begin
    Writeln('Нет данных для отображения. Сначала загрузите или добавьте игроков.');
    Writeln('Нажмите Enter для возврата...');
    Readln;
    Exit;
  end;

  TotalPages := GetTotalPages(PageSize);
  if (Page < 1) or (Page > TotalPages) then
  begin
    Writeln('Неверный номер страницы');
    Exit;
  end;

  StartIndex := (Page - 1) * PageSize;
  EndIndex := Min(StartIndex + PageSize - 1, High(PlayersData));

  Writeln('Страница ', Page, ' из ', TotalPages);
  Writeln('----------------------------------------');
  Writeln('ID  | Имя           | Команда    | Голы | Передачи | Очки | Штрафы');
  Writeln('----------------------------------------');

  for i := StartIndex to EndIndex do
  begin
    Writeln(Format('%-3d | %-12s | %-10s | %-4d | %-8d | %-4d | %-6d мин',
      [PlayersData[i].Player.Number,
       PlayersData[i].Player.Name,
       PlayersData[i].Player.TeamCode,
       PlayersData[i].Statistic.Goals,
       PlayersData[i].Statistic.Assists,
       PlayersData[i].Statistic.Points,
       PlayersData[i].Penalty.Minutes]));
  end;

  Writeln('----------------------------------------');
  Writeln('Нажмите Enter для продолжения...');
  Readln;
end;

procedure SortPlayers(Field: TSortField; Order: TSortOrder);
var
  i, j: Integer;
  TempData: TPlayerData;
  CompareResult: Integer;
begin
  if Length(PlayersData) <= 1 then
    Exit;

  // Сортировка выборкой
  for i := 0 to High(PlayersData) - 1 do
  begin
    for j := i + 1 to High(PlayersData) do
    begin
      case Field of
        sfName:
          CompareResult := CompareText(PlayersData[i].Player.Name, PlayersData[j].Player.Name);
        sfGoals:
          CompareResult := PlayersData[i].Statistic.Goals - PlayersData[j].Statistic.Goals;
        sfAssists:
          CompareResult := PlayersData[i].Statistic.Assists - PlayersData[j].Statistic.Assists;
        sfPoints:
          CompareResult := PlayersData[i].Statistic.Points - PlayersData[j].Statistic.Points;
        sfPenalties:
          CompareResult := PlayersData[i].Penalty.Minutes - PlayersData[j].Penalty.Minutes;
      end;

      if (Order = soAscending) and (CompareResult > 0) or
         (Order = soDescending) and (CompareResult < 0) then
      begin
        TempData := PlayersData[i];
        PlayersData[i] := PlayersData[j];
        PlayersData[j] := TempData;
      end;
    end;
  end;
end;

procedure SearchPlayers(Field: TSearchField; const Value: string; var FoundIndices: TArray<Integer>);
var
  i: Integer;
  SearchNumber: Integer;
  SearchPenalties: Integer;
begin
  SetLength(FoundIndices, 0);

  case Field of
    sfByName:
      begin
        // Линейный поиск по имени
        for i := 0 to High(PlayersData) do
        begin
          if Pos(LowerCase(Value), LowerCase(PlayersData[i].Player.Name)) > 0 then
          begin
            SetLength(FoundIndices, Length(FoundIndices) + 1);
            FoundIndices[High(FoundIndices)] := i;
          end;
        end;
      end;

    sfById:
      begin
        SearchNumber := StrToIntDef(Value, -1);
        if SearchNumber = -1 then Exit;

        // Линейный поиск по номеру
        for i := 0 to High(PlayersData) do
        begin
          if PlayersData[i].Player.Number = SearchNumber then
          begin
            SetLength(FoundIndices, Length(FoundIndices) + 1);
            FoundIndices[High(FoundIndices)] := i;
          end;
        end;
      end;

    sfByPenalties:
      begin
        SearchPenalties := StrToIntDef(Value, -1);
        if SearchPenalties = -1 then Exit;

        // Линейный поиск по штрафам
        for i := 0 to High(PlayersData) do
        begin
          if PlayersData[i].Penalty.Minutes > SearchPenalties then
          begin
            SetLength(FoundIndices, Length(FoundIndices) + 1);
            FoundIndices[High(FoundIndices)] := i;
          end;
        end;
      end;
  end;
end;

function AddPlayer(const Name: string; const TeamName: string; Number: Integer;
                  Goals: Integer; Assists: Integer; PenaltyMinutes: Integer;
                  const PenaltyReason: string): Boolean;
var
  PlayerData: TPlayerData;
  TeamCode: Integer;
  i: Integer;
begin
  Result := False;

  // Проверка на пустые данные
  if (Name = '') or (TeamName = '') then
  begin
    Writeln('Ошибка: Имя игрока и название команды не могут быть пустыми');
    Exit;
  end;

  // Проверка корректности данных
  if (Number <= 0) then
  begin
    Writeln('Ошибка: Номер игрока должен быть положительным числом');
    Exit;
  end;

  if (Goals < 0) or (Assists < 0) or (PenaltyMinutes < 0) then
  begin
    Writeln('Ошибка: Количество голов, передач и штрафов не может быть отрицательным');
    Exit;
  end;

  // Проверка уникальности имени
  if not IsNameUnique(Name) then
  begin
    Writeln('Ошибка: Игрок с таким именем уже существует');
    Exit;
  end;

  // Проверка уникальности номера
  if FindPlayerByNumber(Number) <> -1 then
  begin
    Writeln('Ошибка: Игрок с таким номером уже существует');
    Exit;
  end;

  // Проверка существования команды
  if Length(TeamsData) = 0 then
  begin
    Writeln('Ошибка: Список команд пуст. Сначала добавьте команду.');
    Exit;
  end;

  // Поиск кода команды по названию
  TeamCode := -1;
  for i := 0 to High(TeamsData) do
    if SameText(TeamsData[i].Name, TeamName) then
    begin
      TeamCode := TeamsData[i].Code;
      Break;
    end;

  if TeamCode = -1 then
  begin
    Writeln('Ошибка: Команда с названием "', TeamName, '" не найдена');
    Exit;
  end;

  try
    // Инициализация данных игрока
    PlayerData.Player.ID := NextPlayerID;
    Inc(NextPlayerID);
    PlayerData.Player.Name := Name;
    PlayerData.Player.TeamCode := TeamCode;
    PlayerData.Player.Number := Number;

    // Инициализация статистики
    PlayerData.Statistic.PlayerID := PlayerData.Player.ID;
    PlayerData.Statistic.Goals := Goals;
    PlayerData.Statistic.Assists := Assists;
    PlayerData.Statistic.Points := Goals + Assists;

    // Инициализация штрафов
    PlayerData.Penalty.PlayerID := PlayerData.Player.ID;
    PlayerData.Penalty.Minutes := PenaltyMinutes;

    // Добавление данных в массив
    SetLength(PlayersData, Length(PlayersData) + 1);
    PlayersData[High(PlayersData)] := PlayerData;

    IsDataLoaded := True;
    Result := True;
  except
    on E: Exception do
    begin
      Writeln('Ошибка при добавлении игрока: ', E.Message);
      Result := False;
    end;
  end;
end;

function DeletePlayer(PlayerNumber: Integer): Boolean;
var
  i, PlayerIndex: Integer;
begin
  Result := False;
  if (not IsDataLoaded) or (Length(PlayersData) = 0) then
  begin
    Writeln('Нет данных для удаления. Сначала загрузите или добавьте игроков.');
    Exit;
  end;
  PlayerIndex := FindPlayerByNumber(PlayerNumber);
  if PlayerIndex = -1 then
  begin
    Writeln('Ошибка: Игрок с номером ', PlayerNumber, ' не найден');
    Exit;
  end;

  // Удаление игрока и связанных данных
  for i := PlayerIndex to High(PlayersData) - 1 do
    PlayersData[i] := PlayersData[i + 1];

  // Уменьшение размера массива
  SetLength(PlayersData, Length(PlayersData) - 1);

  Result := True;
end;

function UpdatePlayer(PlayerNumber: Integer; const NewName: string; const NewTeam: string;
                     NewGoals: Integer; NewAssists: Integer; NewPenaltyMinutes: Integer;
                     const NewPenaltyReason: string): Boolean;
var
  PlayerIndex: Integer;
begin
  Result := False;
  if (not IsDataLoaded) or (Length(PlayersData) = 0) then
  begin
    Writeln('Нет данных для редактирования. Сначала загрузите или добавьте игроков.');
    Exit;
  end;
  PlayerIndex := FindPlayerByNumber(PlayerNumber);
  if PlayerIndex = -1 then
  begin
    Writeln('Ошибка: Игрок с номером ', PlayerNumber, ' не найден');
    Exit;
  end;

  // Проверка корректности данных
  if (NewGoals < 0) or (NewAssists < 0) or (NewPenaltyMinutes < 0) then
  begin
    Writeln('Ошибка: Количество голов, передач и штрафов не может быть отрицательным');
    Exit;
  end;

  // Проверка уникальности имени, если оно изменилось
  if (NewName <> '') and (CompareText(NewName, PlayersData[PlayerIndex].Player.Name) <> 0) and
     not IsNameUnique(NewName, PlayersData[PlayerIndex].Player.ID) then
  begin
    Writeln('Ошибка: Игрок с таким именем уже существует');
    Exit;
  end;

  // Обновление данных игрока
  if NewName <> '' then
    PlayersData[PlayerIndex].Player.Name := NewName;
  if NewTeam <> '' then
    PlayersData[PlayerIndex].Player.TeamCode := StrToIntDef(NewTeam, -1);

  // Обновление статистики
  if NewGoals >= 0 then
    PlayersData[PlayerIndex].Statistic.Goals := NewGoals;
  if NewAssists >= 0 then
    PlayersData[PlayerIndex].Statistic.Assists := NewAssists;
  PlayersData[PlayerIndex].Statistic.Points := 
    PlayersData[PlayerIndex].Statistic.Goals + PlayersData[PlayerIndex].Statistic.Assists;

  // Обновление штрафов
  if NewPenaltyMinutes >= 0 then
    PlayersData[PlayerIndex].Penalty.Minutes := NewPenaltyMinutes;

  Result := True;
end;

procedure FindMostSuccessfulPlayers(var FoundIndices: TArray<Integer>);
var
  i, MaxPoints: Integer;
begin
  SetLength(FoundIndices, 0);
  if (not IsDataLoaded) or (Length(PlayersData) = 0) then Exit;

  // Находим максимальное количество очков
  MaxPoints := PlayersData[0].Statistic.Points;
  for i := 1 to High(PlayersData) do
  begin
    if PlayersData[i].Statistic.Points > MaxPoints then
      MaxPoints := PlayersData[i].Statistic.Points;
  end;

  // Находим всех игроков с максимальным количеством очков
  for i := 0 to High(PlayersData) do
  begin
    if PlayersData[i].Statistic.Points = MaxPoints then
    begin
      SetLength(FoundIndices, Length(FoundIndices) + 1);
      FoundIndices[High(FoundIndices)] := i;
    end;
  end;
end;

procedure FindPlayersWithMaxPenalties(var FoundIndices: TArray<Integer>);
var
  i, MaxPenalties: Integer;
begin
  SetLength(FoundIndices, 0);
  if (not IsDataLoaded) or (Length(PlayersData) = 0) then Exit;

  // Находим максимальное количество штрафных минут
  MaxPenalties := PlayersData[0].Penalty.Minutes;
  for i := 1 to High(PlayersData) do
  begin
    if PlayersData[i].Penalty.Minutes > MaxPenalties then
      MaxPenalties := PlayersData[i].Penalty.Minutes;
  end;

  // Находим всех игроков с максимальным количеством штрафных минут
  for i := 0 to High(PlayersData) do
  begin
    if PlayersData[i].Penalty.Minutes = MaxPenalties then
    begin
      SetLength(FoundIndices, Length(FoundIndices) + 1);
      FoundIndices[High(FoundIndices)] := i;
    end;
  end;
end;

function SaveDataToFile(const FileName: string): Boolean;
var
  F: TextFile;
  i: Integer;
begin
  Result := False;
  if not IsDataLoaded then
  begin
    Writeln('Ошибка: Нет данных для сохранения');
    Result := False;
  end
  else
  begin
    AssignFile(F, FileName);
    Rewrite(F);
    for i := 0 to High(PlayersData) do
    begin
      Writeln(F, Format('%d;%s;%d;%d;%d',
        [PlayersData[i].Player.Number,
         PlayersData[i].Player.Name,
         PlayersData[i].Player.TeamCode,
         PlayersData[i].Statistic.Goals,
         PlayersData[i].Statistic.Assists,
         PlayersData[i].Penalty.Minutes]));
    end;
    CloseFile(F);
    Result := True;
    Writeln('Данные успешно сохранены в файл ', FileName);
  end;
end;

function GetTotalPages(PageSize: Integer): Integer;
begin
  Result := (Length(PlayersData) + PageSize - 1) div PageSize;
end;

procedure GetTop10SuccessfulPlayers(var Indices: TArray<Integer>);
var
  Sorted: array of Integer;
  i, j, n: Integer;
begin
  SetLength(Indices, 0);
  if (not IsDataLoaded) or (Length(PlayersData) = 0) then Exit;
  n := Length(PlayersData);
  SetLength(Sorted, n);
  for i := 0 to n-1 do Sorted[i] := i;
  // Сортировка по очкам (выборкой)
  for i := 0 to n-2 do
    for j := i+1 to n-1 do
      if PlayersData[Sorted[j]].Statistic.Points > PlayersData[Sorted[i]].Statistic.Points then
      begin
        var t := Sorted[i]; Sorted[i] := Sorted[j]; Sorted[j] := t;
      end;
  n := Min(10, n);
  SetLength(Indices, n);
  for i := 0 to n-1 do Indices[i] := Sorted[i];
end;

procedure GetTop10PenaltyPlayers(var Indices: TArray<Integer>);
var
  Sorted: array of Integer;
  i, j, n: Integer;
begin
  SetLength(Indices, 0);
  if (not IsDataLoaded) or (Length(PlayersData) = 0) then Exit;
  n := Length(PlayersData);
  SetLength(Sorted, n);
  for i := 0 to n-1 do Sorted[i] := i;
  // Сортировка по штрафам (выборкой)
  for i := 0 to n-2 do
    for j := i+1 to n-1 do
      if PlayersData[Sorted[j]].Penalty.Minutes > PlayersData[Sorted[i]].Penalty.Minutes then
      begin
        var t := Sorted[i]; Sorted[i] := Sorted[j]; Sorted[j] := t;
      end;
  n := Min(10, n);
  SetLength(Indices, n);
  for i := 0 to n-1 do Indices[i] := Sorted[i];
end;

procedure GetBestAndPenaltyPlayersByTeam(var BestIndices, PenaltyIndices: TArray<Integer>);
var
  i, t, idx, maxPoints, maxPenalty: Integer;
  TeamCodes: array of Integer;
  TeamCount: Integer;
begin
  SetLength(BestIndices, 0);
  SetLength(PenaltyIndices, 0);
  if (not IsDataLoaded) or (Length(PlayersData) = 0) then Exit;
  // Собираем уникальные коды команд
  SetLength(TeamCodes, 0);
  for i := 0 to High(PlayersData) do
  begin
    idx := -1;
    for t := 0 to High(TeamCodes) do
      if PlayersData[i].Player.TeamCode = TeamCodes[t] then idx := t;
    if idx = -1 then
    begin
      SetLength(TeamCodes, Length(TeamCodes)+1);
      TeamCodes[High(TeamCodes)] := PlayersData[i].Player.TeamCode;
    end;
  end;
  // Для каждой команды ищем лучшего и самого штрафного
  for t := 0 to High(TeamCodes) do
  begin
    maxPoints := -1; idx := -1;
    for i := 0 to High(PlayersData) do
      if PlayersData[i].Player.TeamCode = TeamCodes[t] then
        if PlayersData[i].Statistic.Points > maxPoints then
        begin
          maxPoints := PlayersData[i].Statistic.Points;
          idx := i;
        end;
    if idx <> -1 then
    begin
      SetLength(BestIndices, Length(BestIndices)+1);
      BestIndices[High(BestIndices)] := idx;
    end;
    maxPenalty := -1; idx := -1;
    for i := 0 to High(PlayersData) do
      if PlayersData[i].Player.TeamCode = TeamCodes[t] then
        if PlayersData[i].Penalty.Minutes > maxPenalty then
        begin
          maxPenalty := PlayersData[i].Penalty.Minutes;
          idx := i;
        end;
    if idx <> -1 then
    begin
      SetLength(PenaltyIndices, Length(PenaltyIndices)+1);
      PenaltyIndices[High(PenaltyIndices)] := idx;
    end;
  end;
end;

function GetTeamNameByCode(Code: Integer): string;
var i: Integer;
begin
  for i := 0 to High(TeamsData) do
    if TeamsData[i].Code = Code then
      Exit(TeamsData[i].Name);
  Result := 'Неизвестно';
end;

procedure ViewTeams;
var i: Integer;
begin
  if Length(TeamsData) = 0 then
  begin
    Writeln('Список команд пуст.');
    Writeln('Нажмите Enter для возврата...');
    Readln;
    Exit;
  end;
  Writeln('Код | Название         | Страна         | № в таблице');
  Writeln('---------------------------------------------------');
  for i := 0 to High(TeamsData) do
    Writeln(Format('%-3d | %-15s | %-13s | %-3d',
      [TeamsData[i].Code, TeamsData[i].Name, TeamsData[i].Country, TeamsData[i].TableNumber]));
  Writeln('---------------------------------------------------');
  Writeln('Нажмите Enter для возврата...');
  Readln;
end;

function AddTeam(const Name, Country: string; TableNumber: Integer): Boolean;
begin
  Result := False;
  // Проверка на уникальность названия
  for var i := 0 to High(TeamsData) do
    if SameText(TeamsData[i].Name, Name) then
    begin
      Writeln('Команда с таким названием уже существует!');
      Exit;
    end;
  SetLength(TeamsData, Length(TeamsData)+1);
  TeamsData[High(TeamsData)].Code := NextTeamCode;
  TeamsData[High(TeamsData)].Name := Name;
  TeamsData[High(TeamsData)].Country := Country;
  TeamsData[High(TeamsData)].TableNumber := TableNumber;
  Inc(NextTeamCode);
  Result := True;
end;

function DeleteTeam(Code: Integer): Boolean;
var i, idx: Integer;
begin
  Result := False;
  idx := -1;
  for i := 0 to High(TeamsData) do
    if TeamsData[i].Code = Code then idx := i;
  if idx = -1 then
  begin
    Writeln('Команда с таким кодом не найдена!');
    Exit;
  end;
  for i := idx to High(TeamsData)-1 do
    TeamsData[i] := TeamsData[i+1];
  SetLength(TeamsData, Length(TeamsData)-1);
  Result := True;
end;

function EditTeam(Code: Integer; const NewName, NewCountry: string; NewTableNumber: Integer): Boolean;
var i: Integer;
begin
  Result := False;
  for i := 0 to High(TeamsData) do
    if TeamsData[i].Code = Code then
    begin
      if NewName <> '' then TeamsData[i].Name := NewName;
      if NewCountry <> '' then TeamsData[i].Country := NewCountry;
      if NewTableNumber > 0 then TeamsData[i].TableNumber := NewTableNumber;
      Result := True;
      Exit;
    end;
  Writeln('Команда с таким кодом не найдена!');
end;

end. 