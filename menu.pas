unit menu;

interface

uses
  data;

procedure ShowWelcome;
procedure ShowMenu;
function GetUserChoice: integer;
procedure ProcessChoice(Choice: integer);
procedure RunMainLoop;

implementation

uses
  System.SysUtils;

procedure ShowWelcome;
begin
  Writeln('Добро пожаловать в программу учета футбольной статистики!');
  Writeln;
end;

procedure ShowMenu;
begin
  Writeln('Меню функций:');
  Writeln('1. Чтение данных из файла');
  Writeln('2. Просмотр всего списка');
  Writeln('3. Сортировка данных');
  Writeln('4. Поиск данных с использованием фильтров');
  Writeln('5. Добавление данных в список');
  Writeln('6. Удаление данных из списка');
  Writeln('7. Редактирование данных');
  Writeln('8. Аналитика по игрокам');
  Writeln('9. Выход без сохранения');
  Writeln('10. Выход с сохранением');
  Writeln;
  Write('Выберите операцию (1-10): ');
end;

function GetUserChoice: integer;
var
  Choice: string;
begin
  Readln(Choice);
  Result := StrToIntDef(Choice, 0);
end;

function ConfirmOverwrite: Boolean;
var
  Answer: string;
begin
  Write('Данные уже загружены. Перезаписать? (y/n): ');
  Readln(Answer);
  Result := (LowerCase(Answer) = 'y') or (LowerCase(Answer) = 'yes');
end;

function ConfirmDelete: Boolean;
var
  Answer: string;
begin
  Write('Вы уверены, что хотите удалить этого игрока? (y/n): ');
  Readln(Answer);
  Result := (LowerCase(Answer) = 'y') or (LowerCase(Answer) = 'yes');
end;

function ConfirmExit: Boolean;
var
  Answer: string;
begin
  Write('Вы уверены, что хотите выйти? (y/n): ');
  Readln(Answer);
  Result := (LowerCase(Answer) = 'y') or (LowerCase(Answer) = 'yes');
end;

function ConfirmSave: Boolean;
var
  Answer: string;
begin
  Write('Сохранить данные перед выходом? (y/n): ');
  Readln(Answer);
  Result := (LowerCase(Answer) = 'y') or (LowerCase(Answer) = 'yes');
end;

procedure ReadData;
var
  FileName: string;
begin
  if IsDataLoaded then
  begin
    if not ConfirmOverwrite then
      Exit;
    ClearData;
  end;

  Write('Введите путь к файлу: ');
  Readln(FileName);
  
  if not ReadDataFromFile(FileName) then
    Writeln('Не удалось загрузить данные');
end;

procedure ViewPlayers;
var
  CurrentPage: Integer;
  TotalPages: Integer;
  Choice: string;
begin
  if not IsDataLoaded or (Length(PlayersData) = 0) then
  begin
    Writeln('Список игроков отсутствует. Сначала загрузите или добавьте данные.');
    Writeln('Нажмите Enter для возврата в меню...');
    Readln;
  end
  else
  begin
    TotalPages := GetTotalPages(10);
    CurrentPage := 1;
    repeat
      ShowPlayers(CurrentPage);
      Writeln('Навигация:');
      Writeln('n - следующая страница');
      Writeln('p - предыдущая страница');
      Writeln('q - выход в главное меню');
      Write('Выберите действие: ');
      Readln(Choice);
      case LowerCase(Choice)[1] of
        'n': if CurrentPage < TotalPages then Inc(CurrentPage);
        'p': if CurrentPage > 1 then Dec(CurrentPage);
        'q': Break;
      end;
    until False;
  end;
end;

procedure SortData;
var
  FieldChoice: string;
  OrderChoice: string;
  Field: TSortField;
  Order: TSortOrder;
begin
  if not IsDataLoaded or (Length(PlayersData) <= 1) then
  begin
    Writeln('Недостаточно данных для сортировки. Сначала загрузите или добавьте игроков.');
    Writeln('Нажмите Enter для возврата в меню...');
    Readln;
  end
  else
  begin
    Writeln('Выберите поле для сортировки:');
    Writeln('1. По имени');
    Writeln('2. По голам');
    Writeln('3. По передачам');
    Writeln('4. По очкам (голы + передачи)');
    Writeln('5. По штрафам');
    Write('Ваш выбор (1-5): ');
    Readln(FieldChoice);
    case StrToIntDef(FieldChoice, 0) of
      1: Field := sfName;
      2: Field := sfGoals;
      3: Field := sfAssists;
      4: Field := sfPoints;
      5: Field := sfPenalties;
    else
      Writeln('Неверный выбор поля');
      Writeln('Нажмите Enter для возврата в меню...');
      Readln;
      Exit;
    end;
    Writeln('Выберите порядок сортировки:');
    Writeln('1. По возрастанию');
    Writeln('2. По убыванию');
    Write('Ваш выбор (1-2): ');
    Readln(OrderChoice);
    case StrToIntDef(OrderChoice, 0) of
      1: Order := soAscending;
      2: Order := soDescending;
    else
      Writeln('Неверный выбор порядка');
      Writeln('Нажмите Enter для возврата в меню...');
      Readln;
      Exit;
    end;
    SortPlayers(Field, Order);
    Writeln('Сортировка выполнена успешно');
    ViewPlayers;
  end;
end;

function FindPlayerIndex(PlayerNumber: Integer): Integer;
begin
  Result := FindPlayerByNumber(PlayerNumber);
end;

procedure SearchData;
var
  FieldChoice: string;
  SearchValue: string;
  Field: TSearchField;
  FoundIndices: TArray<Integer>;
  i: Integer;
begin
  if not IsDataLoaded or (Length(PlayersData) = 0) then
  begin
    Writeln('Список игроков отсутствует. Сначала загрузите или добавьте данные.');
    Writeln('Нажмите Enter для возврата в меню...');
    Readln;
  end
  else
  begin
    Writeln('Выберите поле для поиска:');
    Writeln('1. По имени');
    Writeln('2. По ID');
    Writeln('3. По штрафам (больше указанного значения)');
    Write('Ваш выбор (1-3): ');
    Readln(FieldChoice);
    case StrToIntDef(FieldChoice, 0) of
      1: Field := sfByName;
      2: Field := sfById;
      3: Field := sfByPenalties;
    else
      Writeln('Неверный выбор поля');
      Writeln('Нажмите Enter для возврата в меню...');
      Readln;
      Exit;
    end;
    Write('Введите значение для поиска: ');
    Readln(SearchValue);
    SearchPlayers(Field, SearchValue, FoundIndices);
    if Length(FoundIndices) = 0 then
    begin
      Writeln('Не найдено записей, соответствующих критериям поиска');
      Writeln('Нажмите Enter для возврата в меню...');
      Readln;
    end
    else
    begin
      Writeln('Найдено записей: ', Length(FoundIndices));
      Writeln('----------------------------------------');
      Writeln('ID  | Имя           | Команда    | Голы | Передачи | Очки | Штрафы');
      Writeln('----------------------------------------');
      for i := 0 to High(FoundIndices) do
      begin
        Writeln(Format('%-3d | %-12s | %-10s | %-4d | %-8d | %-4d | %-6d мин',
          [PlayersData[FoundIndices[i]].Player.Number,
           PlayersData[FoundIndices[i]].Player.Name,
           GetTeamNameByCode(PlayersData[FoundIndices[i]].Player.TeamCode),
           PlayersData[FoundIndices[i]].Statistic.Goals,
           PlayersData[FoundIndices[i]].Statistic.Assists,
           PlayersData[FoundIndices[i]].Statistic.Points,
           PlayersData[FoundIndices[i]].Penalty.Minutes]));
      end;
      Writeln('----------------------------------------');
      Writeln('Нажмите Enter для продолжения...');
      Readln;
    end;
  end;
end;

procedure AddNewPlayer;
var
  Name: string;
  TeamName: string;
  Number, Goals, Assists, PenaltyMinutes: Integer;
  Input: string;
begin
  Writeln('Добавление нового игрока');
  Writeln('------------------------');

  repeat
    Write('Введите имя игрока: ');
    Readln(Name);
    if Name = '' then
      Writeln('Ошибка: Имя не может быть пустым');
  until Name <> '';

  Write('Введите название команды: ');
  Readln(TeamName);

  repeat
    Write('Введите номер игрока: ');
    Readln(Input);
    Number := StrToIntDef(Input, -1);
    if Number < 0 then
      Writeln('Ошибка: Введите положительное число');
  until Number >= 0;

  repeat
    Write('Введите количество голов: ');
    Readln(Input);
    Goals := StrToIntDef(Input, -1);
    if Goals < 0 then
      Writeln('Ошибка: Введите положительное число');
  until Goals >= 0;

  repeat
    Write('Введите количество передач: ');
    Readln(Input);
    Assists := StrToIntDef(Input, -1);
    if Assists < 0 then
      Writeln('Ошибка: Введите положительное число');
  until Assists >= 0;

  repeat
    Write('Введите количество минут штрафа: ');
    Readln(Input);
    PenaltyMinutes := StrToIntDef(Input, -1);
    if PenaltyMinutes < 0 then
      Writeln('Ошибка: Введите положительное число');
  until PenaltyMinutes >= 0;

  if AddPlayer(Name, TeamName, Number, Goals, Assists, PenaltyMinutes, '') then
  begin
    Writeln('Игрок успешно добавлен');
    ViewPlayers;
  end;
end;

procedure DeletePlayerMenu;
var
  PlayerNumber: Integer;
  Input: string;
begin
  if not IsDataLoaded then
  begin
    Writeln('Сначала загрузите данные');
    Exit;
  end;

  if Length(PlayersData) = 0 then
  begin
    Writeln('Нет игроков для удаления');
    Exit;
  end;

  Writeln('Список игроков:');
  ShowPlayers(1);

  repeat
    Write('Введите номер игрока для удаления: ');
    Readln(Input);
    PlayerNumber := StrToIntDef(Input, -1);
    if PlayerNumber < 0 then
      Writeln('Ошибка: Введите положительное число');
  until PlayerNumber >= 0;

  if not ConfirmDelete then
  begin
    Writeln('Удаление отменено');
    Exit;
  end;

  if data.DeletePlayer(PlayerNumber) then
  begin
    Writeln('Игрок успешно удален');
    ViewPlayers;
  end;
end;

procedure EditPlayer;
var
  PlayerNumber: Integer;
  NewName: string;
  NewTeamName: string;
  NewGoals, NewAssists, NewPenaltyMinutes: Integer;
  Input: string;
  PlayerIndex: Integer;
begin
  if not IsDataLoaded then
  begin
    Writeln('Сначала загрузите данные');
    Exit;
  end;

  if Length(PlayersData) = 0 then
  begin
    Writeln('Нет игроков для редактирования');
    Exit;
  end;

  Writeln('Список игроков:');
  ShowPlayers(1);

  repeat
    Write('Введите номер игрока для редактирования: ');
    Readln(Input);
    PlayerNumber := StrToIntDef(Input, -1);
    if PlayerNumber < 0 then
      Writeln('Ошибка: Введите положительное число');
  until PlayerNumber >= 0;

  PlayerIndex := FindPlayerIndex(PlayerNumber);
  if PlayerIndex = -1 then
  begin
    Writeln('Игрок не найден');
    Exit;
  end;

  Writeln('Текущие данные игрока:');
  Writeln('----------------------');
  Writeln('1. Имя: ', PlayersData[PlayerIndex].Player.Name);
  Writeln('2. Команда: ', GetTeamNameByCode(PlayersData[PlayerIndex].Player.TeamCode));
  Writeln('3. Голы: ', PlayersData[PlayerIndex].Statistic.Goals);
  Writeln('4. Передачи: ', PlayersData[PlayerIndex].Statistic.Assists);
  Writeln('5. Штрафные минуты: ', PlayersData[PlayerIndex].Penalty.Minutes);
  Writeln('----------------------');
  Writeln('Для сохранения текущего значения нажмите Enter');
  Writeln;

  Write('Новое имя: ');
  Readln(NewName);
  Write('Новое название команды (или Enter для сохранения текущего): ');
  Readln(NewTeamName);

  Write('Новое количество голов (-1 для сохранения текущего): ');
  Readln(Input);
  NewGoals := StrToIntDef(Input, -1);

  Write('Новое количество передач (-1 для сохранения текущего): ');
  Readln(Input);
  NewAssists := StrToIntDef(Input, -1);

  Write('Новое количество штрафных минут (-1 для сохранения текущего): ');
  Readln(Input);
  NewPenaltyMinutes := StrToIntDef(Input, -1);

  if UpdatePlayer(PlayerNumber, NewName, NewTeamName, NewGoals, NewAssists, NewPenaltyMinutes, '') then
  begin
    Writeln('Данные игрока успешно обновлены');
    ViewPlayers;
  end;
end;

procedure ShowViewMenu;
begin
  Writeln('Просмотр списка:');
  Writeln('1. Список команд');
  Writeln('2. Список игроков');
  Writeln('3. Назад');
  Write('Выберите: ');
end;

procedure ShowAddMenu;
begin
  Writeln('Добавление:');
  Writeln('1. Добавить команду');
  Writeln('2. Добавить игрока');
  Writeln('3. Назад');
  Write('Выберите: ');
end;

procedure ShowDeleteMenu;
begin
  Writeln('Удаление:');
  Writeln('1. Удалить команду');
  Writeln('2. Удалить игрока');
  Writeln('3. Назад');
  Write('Выберите: ');
end;

procedure ShowEditMenu;
begin
  Writeln('Редактирование:');
  Writeln('1. Редактировать команду');
  Writeln('2. Редактировать игрока');
  Writeln('3. Назад');
  Write('Выберите: ');
end;

procedure ShowAnalyticsMenu;
begin
  Writeln('Аналитика по игрокам:');
  Writeln('1. Топ-10 успешных игроков');
  Writeln('2. Топ-10 по штрафам');
  Writeln('3. Лучшие и самые штрафные игроки по командам');
  Writeln('4. Назад');
  Write('Выберите: ');
end;

procedure SaveData;
var FileName: string;
begin
  Write('Введите имя файла для сохранения: ');
  Readln(FileName);
  if not SaveDataToFile(FileName) then
    Writeln('Ошибка при сохранении данных!')
  else
    Writeln('Данные успешно сохранены.');
end;

procedure ViewMenu;
var c: string;
begin
  repeat
    ShowViewMenu;
    Readln(c);
    if c = '1' then
      ViewTeams
    else if c = '2' then
      ViewPlayers
    else if c = '3' then
      Break;
  until c = '3';
end;

procedure AddMenu;
var c: string;
    TableNumber: Integer;
    Name, Country, Input: string;
begin
  repeat
    ShowAddMenu;
    Readln(c);
    if c = '1' then
    begin
      Write('Введите название команды: '); Readln(Name);
      Write('Введите страну: '); Readln(Country);
      repeat
        Write('Введите номер в таблице: ');
        Readln(Input);
        TableNumber := StrToIntDef(Input, -1);
        if TableNumber < 1 then
          Writeln('Ошибка: Введите число больше 0');
      until TableNumber >= 1;
      if AddTeam(Name, Country, TableNumber) then
        Writeln('Команда успешно добавлена!');
    end
    else if c = '2' then
      AddNewPlayer
    else if c = '3' then
      Break;
  until c = '3';
end;

procedure DeleteMenu;
var c: string;
    Code: Integer;
    Input: string;
begin
  repeat
    ShowDeleteMenu;
    Readln(c);
    if c = '1' then
    begin
      repeat
        Write('Введите код команды для удаления: ');
        Readln(Input);
        Code := StrToIntDef(Input, -1);
        if Code < 1 then
          Writeln('Ошибка: Введите число больше 0');
      until Code >= 1;
      if DeleteTeam(Code) then
        Writeln('Команда успешно удалена!');
    end
    else if c = '2' then
      DeletePlayerMenu
    else if c = '3' then
      Break;
  until c = '3';
end;

procedure EditMenu;
var c: string;
    Code, TableNumber: Integer;
    Name, Country, Input: string;
begin
  repeat
    ShowEditMenu;
    Readln(c);
    if c = '1' then
    begin
      repeat
        Write('Введите код команды для редактирования: ');
        Readln(Input);
        Code := StrToIntDef(Input, -1);
        if Code < 1 then
          Writeln('Ошибка: Введите число больше 0');
      until Code >= 1;
      Write('Новое название (Enter - без изменений): '); Readln(Name);
      Write('Новая страна (Enter - без изменений): '); Readln(Country);
      Write('Новый номер в таблице (0 - без изменений): '); Readln(Input); TableNumber := StrToIntDef(Input, 0);
      if EditTeam(Code, Name, Country, TableNumber) then
        Writeln('Данные команды успешно обновлены!');
    end
    else if c = '2' then
      EditPlayer
    else if c = '3' then
      Break;
  until c = '3';
end;

procedure AnalyticsMenu;
var c: string;
    Indices: TArray<Integer>;
    Best, Penalty: TArray<Integer>;
    i: Integer;
    F: TextFile;
begin
  repeat
    ShowAnalyticsMenu;
    Readln(c);
    if c = '1' then
    begin
      GetTop10SuccessfulPlayers(Indices);
      AssignFile(F, 'top10_success.txt'); Rewrite(F);
      Writeln('Топ-10 успешных игроков:');
      Writeln(F, 'Топ-10 успешных игроков:');
      for i := 0 to High(Indices) do
      begin
        Writeln(Format('%d. %s (Очки: %d)',
          [i+1, PlayersData[Indices[i]].Player.Name, PlayersData[Indices[i]].Statistic.Points]));
        Writeln(F, Format('%d. %s (Очки: %d)',
          [i+1, PlayersData[Indices[i]].Player.Name, PlayersData[Indices[i]].Statistic.Points]));
      end;
      CloseFile(F);
      Writeln('Результат сохранён в top10_success.txt');
      Writeln('Нажмите Enter...'); Readln;
    end
    else if c = '2' then
    begin
      GetTop10PenaltyPlayers(Indices);
      AssignFile(F, 'top10_penalty.txt'); Rewrite(F);
      Writeln('Топ-10 по штрафам:');
      Writeln(F, 'Топ-10 по штрафам:');
      for i := 0 to High(Indices) do
      begin
        Writeln(Format('%d. %s (Штраф: %d)',
          [i+1, PlayersData[Indices[i]].Player.Name, PlayersData[Indices[i]].Penalty.Minutes]));
        Writeln(F, Format('%d. %s (Штраф: %d)',
          [i+1, PlayersData[Indices[i]].Player.Name, PlayersData[Indices[i]].Penalty.Minutes]));
      end;
      CloseFile(F);
      Writeln('Результат сохранён в top10_penalty.txt');
      Writeln('Нажмите Enter...'); Readln;
    end
    else if c = '3' then
    begin
      GetBestAndPenaltyPlayersByTeam(Best, Penalty);
      AssignFile(F, 'team_analytics.txt'); Rewrite(F);
      Writeln('Лучшие и самые штрафные игроки по командам:');
      Writeln(F, 'Лучшие и самые штрафные игроки по командам:');
      for i := 0 to High(Best) do
      begin
        Writeln(Format('Команда %d: лучший - %s (Очки: %d), штрафной - %s (Штраф: %d)',
          [PlayersData[Best[i]].Player.TeamCode,
           PlayersData[Best[i]].Player.Name,
           PlayersData[Best[i]].Statistic.Points,
           PlayersData[Penalty[i]].Player.Name,
           PlayersData[Penalty[i]].Penalty.Minutes]));
        Writeln(F, Format('Команда %d: лучший - %s (Очки: %d), штрафной - %s (Штраф: %d)',
          [PlayersData[Best[i]].Player.TeamCode,
           PlayersData[Best[i]].Player.Name,
           PlayersData[Best[i]].Statistic.Points,
           PlayersData[Penalty[i]].Player.Name,
           PlayersData[Penalty[i]].Penalty.Minutes]));
      end;
      CloseFile(F);
      Writeln('Результат сохранён в team_analytics.txt');
      Writeln('Нажмите Enter...'); Readln;
    end
    else if c = '4' then
      Break;
  until c = '4';
end;

procedure ProcessChoice(Choice: integer);
begin
  case Choice of
    1: ReadData;
    2: ViewMenu;
    3: SortData;
    4: SearchData;
    5: AddMenu;
    6: DeleteMenu;
    7: EditMenu;
    8: AnalyticsMenu;
    9: Halt(0);
    10: begin SaveData; Halt(0); end;
    else Writeln('Неверный выбор. Попробуйте снова.');
  end;
end;

procedure RunMainLoop;
var
  Choice: integer;
begin
  repeat
    ShowMenu;
    Choice := GetUserChoice;
    ProcessChoice(Choice);
  until Choice = 10;
end;

end. 