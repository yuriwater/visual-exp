%% Constant
% 実行ボタンを押してスタート
% 切りかけ幅の種類×4方向 で１セッション
% セッション×繰り返し回数　が実行される
% 1セッション終わる度にファイルに結果が保存される
% 結果のファイル名は「Task1_被験者番号_セッション番号_MMddHHmm.xlsx」

%% ------ここから下は触らない-----------
% 被験者番号とセッション番号、繰り返し回数のダイアログ表示
prompt = {'被験者No.', 'セッション番号','繰り返し回数'};
dlgtitle = 'Task1';
dims = [1 15];
definput = {'001', '001','5'};
answer = inputdlg(prompt, dlgtitle, dims, definput);
% キャンセルした場合は処理を中止
if isempty(answer)
    return;
end

participait = answer{1}; % 被験者番号
Session = answer{2}; % セッション番号
SessionCount = str2double(answer{3}); % 繰り返し回数

% ファイル名　Task1_被験者番号_セッション番号_MMddHHmm
Date = string(datetime('now', 'Format', 'MMddHHmm'));
resultfilename = strcat('Task1_', participait, '_', Session, '_', Date, '.xlsx'); 

% ファイル選択ダイアログを開く
[filename, path] = uigetfile('*.xlsx', 'Select Parameter file');

% キャンセルした場合は処理を中止
if isequal(filename, 0) || isequal(path, 0)
    return;
else
    % 選択されたファイルを表示
    fullPath = fullfile(path, filename);
    disp(['ファイル: ', fullPath]);

    % ファイルを読み込む
    data = readmatrix(fullPath);

    % GapPixを表示（必要に応じて）
    disp('GapPix:');
    disp(data');
end

%% すべてのGapPixと角度を組み合わせた行列を作成
Angles = [90, 180, 270, 360]; % 0回避のため360を利用
% 行列の作成
[Gappix, AngleGrid] = meshgrid(data, Angles);
% ベクトルを縦に並べて行列に変換
Matrix = [Gappix(:), AngleGrid(:)];
numRows = size(Matrix, 1); % 行列の行数

%% 実験開始
% 垂直同期のテストをスキップ
Screen('Preference', 'SkipSyncTests', 1);

% Psychtoolboxの初期化
PsychDefaultSetup(2);
KbName('UnifyKeyNames');

% ランドルトC環つぶれ回避のための倍率（初期1）
Scaling = 1;

try
    % Matlabへのキー入力の制限
    ListenChar(-1);
    HideCursor;
    % スクリーン番号を取得
    screenNumber = max(Screen('Screens'));

    % 白のウィンドウを開く
    white = [255 255 255];
    [window, windowRect] = Screen('OpenWindow', screenNumber, white);
    [xCenter, yCenter] = RectCenter(windowRect); % 画面の中心座標

    done = 0;

    %% 繰り返し回数分セッションを行う
    for j = 1:SessionCount

        result = zeros(size(Matrix)); %結果の初期化
        % escapeキーで終了
        if done
            break;
        end

        % セッション毎に行をランダムに並び替える
        randomOrder = randperm(numRows);
        Matrix = Matrix(randomOrder, :);

        %% セッション開始
        for i = 1:size(Matrix, 1)
            % escapeキーで終了
            if done
                break;
            end

            %背景白
            Screen('FillRect', window, white);
            
            % 環のパラメータ
            GapSize = Matrix(i, 1) * Scaling; % つぶれ回避のため3倍
            radius = GapSize * 2.5; % 半径
            lineWidth = GapSize; % 線の太さ
            Angle = Matrix(i, 2); % ギャップの位置（度単位）

            % 環の描画
            Screen('FrameArc', window, [0 0 0], [xCenter - radius, yCenter - radius, xCenter + radius, yCenter + radius], 0, 360, lineWidth);

            % ギャップの描画 (GapSizeの幅の白い長方形をAngleに合わせて回転させる)
            % 長方形の座標を定義　底辺が画面の中央、高さが十分に必要
            RectHeight = xCenter; 
            RectWidth = GapSize;
            baseRect = [0 0 RectWidth RectHeight];
            centeredRect = CenterRectOnPointd(baseRect, xCenter, yCenter-RectHeight / 2);
            
            Screen('glPushMatrix', window); %座標系の状態保存
            % 座標系を中央に→回転→座標系をもどす（画面の中央を中心に回転）
            Screen('glTranslate', window, xCenter, yCenter, 0); %座標系の移動
            Screen('glRotate', window, Angle, 0, 0, 1); %座標系の回転
            Screen('glTranslate', window, -xCenter, -yCenter, 0); %座標系の移動
            Screen('FillRect', window, white, centeredRect); % 長方形を描画
            Screen('glPopMatrix', window); %座標系の状態復元
            % 画面の更新
            Screen('Flip', window);

            % keyboard入力
            FlushEvents('keyDown');  % 過去のkeyイベントを削除
            WaitSecs(0.2); % 押し続け回避の待ち時間
            % キーが押されるまでループ
            while 1
                [~, ~, keyCode] = KbCheck(-1);
                if keyCode(KbName('LeftArrow')) % 鏡を通した時の方向（画面の左右逆）
                    answer = 90;
                    break;
                elseif keyCode(KbName('RightArrow')) % 鏡を通した時の方向（画面の左右逆)
                    answer = 270;
                    break;
                elseif keyCode(KbName('UpArrow'))
                    answer = 360;
                    break;
                elseif keyCode(KbName('DownArrow'))
                    answer = 180;
                    break;
                elseif keyCode(KbName('escape'))
                    done = 1;
                    break;
                end
            end

            %% 正誤判定
            if Angle == answer
                result(i, 2) = 1;
            else
                result(i, 2) = 0;
            end
            result(i, 1) = answer;
        end
        %%  セッション終了
        % セッションごとにファイルに書き込み
        resulttable = array2table(result, "VariableNames", {'Answer', 'Correct'});

        % エクセルファイルが存在するか確認
        Matrix_result = horzcat(array2table(Matrix, "VariableNames", {'GapSize', 'Angle'}), resulttable);

        if exist(resultfilename, 'file') == 2
            % ファイルが存在する場合の処理
            resultfile0 = readtable(resultfilename);
            resultfile = [resultfile0; Matrix_result]; % ファイルに追加して書き足す
        else
            resultfile = Matrix_result;
        end
        writetable(resultfile, resultfilename);
        FlushEvents('keyDown'); % 過去のkeyイベントを削除
        % done=1ならループを出て終了
    end
catch
    % エラー処理
    Screen('CloseAll');
    ShowCursor;
    ListenChar(0);
    psychrethrow(psychlasterror);
end
 % 終了処理
    Screen('CloseAll');
    ShowCursor;
    ListenChar(0);
