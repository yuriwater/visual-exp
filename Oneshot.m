%% Oneshot
% GapSizeとAngleを変更してから、実行
% escapeキーまたは矢印キーで画面を閉じる

%% 変数
GapSize = 20; % ギャップのサイズ
Angle = 270; % ギャップの位置（度単位）
%切り欠き幅の位置　上(360)　下(180) 左(90) 右(270) 
%左右のみ反転したものが表示

%% ------ここから下は触らない-----------
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

    % 白の背景にウィンドウを開く
    white = [255 255 255];
    [window, windowRect] = Screen('OpenWindow', screenNumber, white);
    
    % 画面の中心座標
    [xCenter, yCenter] = RectCenter(windowRect);

    % 環のパラメータ
    GapSize = GapSize * Scaling; % つぶれ回避のため3倍
    radius = GapSize * 2.5; % 半径
    lineWidth = GapSize; % 線の太さ

    % 環の描画
    Screen('FrameArc', window, [0 0 0], [xCenter - radius, yCenter - radius, xCenter + radius, yCenter + radius], 0, 360, lineWidth);

    % ギャップの描画 (GapSize幅の白い長方形をAngleに合わせて回転させる)
    % 長方形の座標を定義　底辺が画面の中央、高さが十分に必要
    RectHeight = xCenter; %画面を突き抜けるくらいの高さ
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

    % キー入力を待つ
    exitKeys = {'Return', 'space', 'escape', 'LeftArrow', 'RightArrow', 'UpArrow', 'DownArrow'};
    exitKeyCodes = KbName(exitKeys);

    while true   
        [~, ~, keyCode] = KbCheck(-1);
        if any(keyCode(exitKeyCodes))
            break;
        end
    end

    % ウィンドウを閉じる
    Screen('CloseAll');
    ShowCursor;
    ListenChar(0);

catch ME
    % エラー処理
    Screen('CloseAll');
    ShowCursor;
    ListenChar(0);
    rethrow(ME);
end
% キー入力制限解除
ListenChar(0);
