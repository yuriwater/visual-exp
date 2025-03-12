%% Constant
% 実行ボタンを押してスタート
% 結果のファイル名は「Task2_LimitDown_被験者番号_セッション番号_MMddHHmm.xlsx」
% 最大値を設定
maxGapSize = 80;

%% ------ここから下は触らない-----------
% 刻み値、繰り返し回数を設定
increment = 2;
repeatCount = 40;

% 最小値を計算
minGapSize = maxGapSize - (increment * repeatCount);
VariableN = 0;

% 被験者番号とセッション番号のダイアログ表示
prompt = {'被験者No.', 'セッション番号'};
dlgtitle = 'Task2LD';
dims = [1 15];
definput = {'001', '001'};
answer = inputdlg(prompt, dlgtitle, dims, definput);
% キャンセルした場合は処理を中止
if isempty(answer)
    return;
end

participait = answer{1}; % 被験者番号
Session = answer{2}; % セッション番号

% ファイル名　Task1_被験者番号_セッション番号_MMddHHmm
Date = string(datetime('now', 'Format', 'MMddHHmm'));
resultfilename = strcat('Task2_LimitDown_', participait, '_', Session, '_', Date, '.xlsx'); 

% Gappixelのサイズを生成
Gappix = maxGapSize:-increment:minGapSize; % 大きいサイズから小さいサイズへ
Angles = [90, 180, 270, 360]; % 0回避のため360を利用

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
    result = []; % 結果の初期化

    %% 繰り返し回数分セッションを行う
    for currentGapSize = Gappix
        if currentGapSize == 0
            done = 1;
        end
        
        if done
            break;
        end

        % 各サイズごとにランダムな角度を選択
        randomAngle = Angles(randi(length(Angles)));
        
        %背景白
        Screen('FillRect', window, white);
        
        % 環のパラメータ
        GapSize = currentGapSize * Scaling; % つぶれ回避のため3倍
        radius = GapSize * 2.5; % 半径
        lineWidth = GapSize; % 線の太さ

        % 環の描画
        Screen('FrameArc', window, [0 0 0], [xCenter - radius, yCenter - radius, xCenter + radius, yCenter + radius], 0, 360, lineWidth);

        % ギャップの描画 (GapSizeの幅の白い長方形をAngleに合わせて回転させる)
        RectHeight = xCenter; 
        RectWidth = GapSize;
        baseRect = [0 0 RectWidth RectHeight];
        centeredRect = CenterRectOnPointd(baseRect, xCenter, yCenter - RectHeight / 2);
        
        Screen('glPushMatrix', window); %座標系の状態保存
        Screen('glTranslate', window, xCenter, yCenter, 0); %座標系の移動
        Screen('glRotate', window, randomAngle, 0, 0, 1); %座標系の回転
        Screen('glTranslate', window, -xCenter, -yCenter, 0); %座標系の移動
        Screen('FillRect', window, white, centeredRect); % 長方形を描画
        Screen('glPopMatrix', window); %座標系の状態復元
        Screen('Flip', window); % 画面の更新

        % keyboard入力
        FlushEvents('keyDown');  % 過去のkeyイベントを削除
        WaitSecs(0.2); % 押し続け回避の待ち時間
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
        if randomAngle == answer
            correct = 1;
        else
            correct = 0;
            VariableN = 1;
            done = 1; % 失敗したら実験終了
        end
        result = [result; currentGapSize, randomAngle, answer, correct];
        if done
            break;
        end
    end

    %% 正解データをファイルに書き込み
    if ~isempty(result)

        if VariableN == 1
        result = result(1:end-1, :); % 不正解の最後の1行を除く
        end

        resulttable = array2table(result, "VariableNames", {'GapSize', 'Angle', 'Answer', 'Correct'});

        if exist(resultfilename, 'file') == 2
            % ファイルが存在する場合の処理
            resultfile0 = readtable(resultfilename);
            resultfile = [resultfile0; resulttable]; % ファイルに追加して書き足す
        else
            resultfile = resulttable;
        end
        writetable(resultfile, resultfilename);
        FlushEvents('keyDown'); % 過去のkeyイベントを削除
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
