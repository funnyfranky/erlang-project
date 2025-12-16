-module(erlang_project).
-behaviour(gen_statem).

%% Public API
-export([
    start_link/0, 
    start_link/1, 
    move/1, 
    reset/0, 
    state/0
]).

%% gen_statem callbacks
-export([
    init/1, 
    callback_mode/0, 
    terminate/3,

    playing/3, 
    game_over/3
]).

% Public API

start_link() ->
    start_link(none).

%% AI = none, x or o
start_link(AIPlayer) ->
    gen_statem:start_link({local, ?MODULE}, ?MODULE, [AIPlayer], []).

move(Pos) ->
    gen_statem:call(?MODULE, {move, Pos}).

reset() ->
    gen_statem:call(?MODULE, reset).

state() ->
    gen_statem:call(?MODULE, get_state).

% gen_statem callbacks

callback_mode() ->
    state_functions.

init([AIPlayer]) ->
    Board = new_board(),
    Data = #{
        board => Board,
        turn  => x,
        ai    => AIPlayer
    },
    io:format("Game started. Player X goes first.~n"),
    print_board(Board),
    {ok, playing, Data}.

terminate(_Reason, _State, _Data) ->
    ok.

% State: playing

playing({call, From}, reset, Data) ->
    Board = new_board(),
    NewData = Data#{board => Board, turn => x},
    io:format("Game reset. Player X goes first.~n"),
    print_board(Board),
    {keep_state, NewData, [{reply, From, ok}]};

playing({call, From}, get_state, Data) ->
    {keep_state_and_data, [{reply, From, {playing, Data}}]};

playing({call, From}, {move, Pos}, Data) ->
    case try_move(Pos, Data) of
        {error, Reason} ->
            {keep_state, Data, [{reply, From, {error, Reason}}]};

        {continue, NewData} ->
            Board = maps:get(board, NewData),
            print_board(Board),
            {keep_state, NewData, [{reply, From, ok}]};

        {win, Winner, NewData} ->
            io:format("~n!!! Player ~p WINS !!!~n", [Winner]),
            Board = maps:get(board, NewData),
            print_board(Board),
            {next_state, game_over, NewData, [{reply, From, {win, Winner}}]};

        {draw, NewData} ->
            io:format("~nIt's a draw.~n"),
            Board = maps:get(board, NewData),
            print_board(Board),
            {next_state, game_over, NewData, [{reply, From, draw}]}
    end.

% State: game_over

game_over({call, From}, reset, Data) ->
    Board = new_board(),
    NewData = Data#{board => Board, turn => x},
    io:format("New game started.~n"),
    print_board(Board),
    {next_state, playing, NewData, [{reply, From, ok}]};

game_over({call, From}, get_state, Data) ->
    {keep_state_and_data, [{reply, From, {game_over, Data}}]};

game_over({call, From}, {move, _}, Data) ->
    {keep_state, Data, [{reply, From, {error, game_over}}]}.

% Logic

try_move(Pos, #{board := Board, turn := Turn} = Data) ->
    case maps:find(Pos, Board) of
        error ->
            {error, invalid_position};

        {ok, empty} ->
            NewBoard = maps:put(Pos, Turn, Board),
            case check_status(NewBoard, Turn) of
                win ->
                    {win, Turn, Data#{board => NewBoard, turn => none}};
                draw ->
                    {draw, Data#{board => NewBoard, turn => none}};
                continue ->
                    NextTurn = switch_turn(Turn),
                    maybe_ai_move(playing, Data#{board => NewBoard, turn => NextTurn})
            end;

        {ok, _} ->
            {error, cell_occupied}
    end.

maybe_ai_move(_, #{ai := none} = Data) ->
    {continue, Data};

maybe_ai_move(_, #{turn := Turn, ai := Turn} = Data) ->
    Pos = ai_choose_move(Data),
    try_move(Pos, Data);

maybe_ai_move(_, Data) ->
    {continue, Data}.

% AI Logic

ai_choose_move(#{board := Board, turn := Turn}) ->
    Empty = empty_cells(Board),
    Opponent = switch_turn(Turn),

    case winning_move(Board, Turn, Empty) of
        {ok, Pos} -> Pos;
        error ->
            case winning_move(Board, Opponent, Empty) of
                {ok, Pos} -> Pos;
                error -> hd(Empty)
            end
    end.

winning_move(Board, Player, Positions) ->
    case lists:dropwhile(
        fun(Pos) ->
            NewBoard = maps:put(Pos, Player, Board),
            check_status(NewBoard, Player) =/= win
        end,
        Positions
    ) of
        [Pos | _] -> {ok, Pos};
        [] -> error
    end.

empty_cells(Board) ->
    [Pos || {Pos, empty} <- maps:to_list(Board)].

% Helpers

new_board() ->
    maps:from_list([{I, empty} || I <- lists:seq(1, 9)]).

switch_turn(x) -> o;
switch_turn(o) -> x.

check_status(Board, Player) ->
    Wins = [
        [1,2,3],[4,5,6],[7,8,9],
        [1,4,7],[2,5,8],[3,6,9],
        [1,5,9],[3,5,7]
    ],
    case lists:any(
        fun(Line) ->
            lists:all(fun(P) -> maps:get(P, Board) == Player end, Line)
        end,
        Wins
    ) of
        true -> win;
        false ->
            case lists:any(fun(V) -> V == empty end, maps:values(Board)) of
                true -> continue;
                false -> draw
            end
    end.

print_board(B) ->
    C = fun(I) -> fmt_cell(maps:get(I, B)) end,
    io:format("~n ~s | ~s | ~s ~n", [C(1),C(2),C(3)]),
    io:format("---+---+---~n"),
    io:format(" ~s | ~s | ~s ~n", [C(4),C(5),C(6)]),
    io:format("---+---+---~n"),
    io:format(" ~s | ~s | ~s ~n", [C(7),C(8),C(9)]).

fmt_cell(empty) -> " ";
fmt_cell(x) -> "X";
fmt_cell(o) -> "O".