Shader "Unlit/BeatGameScoreTexture_PingPong"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _GameTime ("Game Time (Anim)", Float) = 0 // 現在のゲーム時間

		// プレイヤーの入力トリガー（0 or 1）
        _InputTriggerFinger1 ("Input Trigger Finger 1 (Index)", Float) = 0
        _InputTriggerFinger2 ("Input Trigger Finger 2 (Middle)", Float) = 0

        // 読み込み用のフィードバックテクスチャ
        _ReadTex ("Read Feedback Texture (RenderTexture)", 2D) = "black" {}

		// 譜面データテクスチャ
        _ScoreTex ("Score Texture", 2D) = "black" {}
		// 譜面テクスチャの幅（=最大ノーツ数)
        _ScoreTexWidth ("Score Texture Width", Float) = 1024
		
		// フィードバックテクスチャの解像度
        _FeedbackTexWidth ("Feedback Texture Width", Float) = 256
        _FeedbackTexHeight ("Feedback Texture Height", Float) = 256

		// ゲームの見た目や判定に関するパラメータ
		_NoteSpeed ("Note Speed", Float) = 0.5							// ノーツ速度
		_JudgeLineY ("Judge Line Y (UV)", Range(0,1)) = 0.2				// 判定ラインのY座標 (UV空間)
		_PerfectWindow ("Perfect Window (Sec)", Float) = 0.05			// Perfect判定の時間幅 (秒)
		_GreatWindow ("Great Window (Sec)", Float) = 0.1				// Great判定の時間幅 (秒)
		_GoodWindow ("Good Window (Sec)", Float) = 0.15					// Good判定の時間幅 (秒)
		_Note1Color ("Note 1 Color (Finger 1)", Color) = (1,0.5,0,1)	// ノーツタイプ1の色
		_Note2Color ("Note 2 Color (Finger 2)", Color) = (0,1,1,1)		// ノーツタイプ2の色
		_LaneColor ("Lane Color", Color) = (0.2,0.2,0.2,1)				// レーンの色
		_JudgeLineColor ("Judge Line Color", Color) = (1,0,0,1)			// 判定ラインの色
		_PerfectEffectColor ("Perfect Effect Color", Color) = (1,1,1,1)	// Perfectエフェクトの色
		_GreatEffectColor ("Great Effect Color", Color) = (0,1,0,1)		// Greatエフェクトの色
		_GoodEffectColor ("Good Effect Color", Color) = (0,0,1,1)		// Goodエフェクトの色
		_MissEffectColor ("Miss Effect Color", Color) = (0.5,0.5,0.5,1)	// Missエフェクトの色
		_VisibleNoteTimeWindowBefore ("Visible Window Before (sec)", Float) = 3.0	// ノーツが出現する何秒前から表示するか
		_VisibleNoteTimeWindowAfter ("Visible Window After (sec)", Float) = 0.5		// ノーツが判定ラインを過ぎてから何秒後まで表示するか

		// スコア・コンボ表示用のパラメータ
		_NumberFontTex ("Number Font Texture (0-9)", 2D) = "white" {}	// 数字フォントのテクスチャ
		_NumberFontCharSize ("Number Font Char Size (UV)", Vector) = (0.1, 0.2, 0, 0)	// フォントテクスチャ内の1文字のサイズ(UV)
		_ScoreDisplayPos ("Score Display Pos (UV)", Vector) = (0.7, 0.9, 0, 0)			// スコア表示位置の基点(UV)
		_ComboDisplayPos ("Combo Display Pos (UV)", Vector) = (0.7, 0.8, 0, 0)			// コンボ表示位置の基点(UV)
		_NumberSpacing ("Number Spacing (UV x-axis)", Float) = 0.08	// 数字と数字の間隔
		_MaxDigits ("Max Digits to Display", Float) = 4				// 表示する最大桁数
		_NumberColor ("Number Text Color", Color) = (1,1,1,1)		// 数字の色
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="Geometry" }
        LOD 100
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _ReadTex;
            sampler2D _ScoreTex;
            float _ScoreTexWidth;

            float _GameTime;
            float _InputTriggerFinger1;
            float _InputTriggerFinger2;
            
            float _NoteSpeed;
			float _JudgeLineY;
			float _PerfectWindow;
			float _GreatWindow;
			float _GoodWindow;
			fixed4 _Note1Color;
			fixed4 _Note2Color;
			fixed4 _LaneColor;
			fixed4 _JudgeLineColor;
			fixed4 _PerfectEffectColor;
			fixed4 _GreatEffectColor;
			fixed4 _GoodEffectColor;
			fixed4 _MissEffectColor;
			float _VisibleNoteTimeWindowBefore;
			float _VisibleNoteTimeWindowAfter;
			sampler2D _NumberFontTex;
			float4 _NumberFontCharSize;
			float4 _ScoreDisplayPos;
			float4 _ComboDisplayPos;
			float _NumberSpacing;
			float _MaxDigits;
			fixed4 _NumberColor;
            float _FeedbackTexWidth;
            float _FeedbackTexHeight;


            #define FEEDBACK_UV float2(0.001, 0.999)

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }
            
			// 譜面テクスチャから指定したインデックスのノーツデータを読み込む
            float4 readNoteDataFromTexture(float index) {
                float u = (index + 0.5) / _ScoreTexWidth;
                float v = 0.5;
                return tex2Dlod(_ScoreTex, float4(u, v, 0, 0));
            }

			// 数値から指定した桁の数字を取得する
			int getDigit(int value, int digit, int maxDigits) {
				if (digit >= maxDigits) return -1;
				for (int i = 0; i < digit; ++i) { value /= 10; }
				return value % 10;
			}

			// 画面の指定した位置に数値を描画する
			fixed4 drawNumber(v2f i, int numberValue, float2 displayPosUV, float2 charSizeOnScreenUV, 
							  float2 fontCharSizeUV, float spacingUV_X, int maxDigitsToDraw, 
							  fixed4 baseColor, fixed4 targetColor)
			{
				int actualMaxDigits = min((int)_MaxDigits, 5); // ループ回数制限のため最大5桁に制限
				for (int k = 0; k < actualMaxDigits; ++k) {
					int digitValue = getDigit(numberValue, k, actualMaxDigits);
					if (numberValue == 0 && k > 0) digitValue = -1;
					else if (numberValue > 0 && digitValue == 0 && numberValue < pow(10,k) ) digitValue = -1;
					if (digitValue < 0 && !(numberValue == 0 && k == 0) ) { }
					// 画面上での各桁の描画矩形を計算
					float digitScreenPosX_TopLeft = displayPosUV.x + (charSizeOnScreenUV.x + spacingUV_X) * (actualMaxDigits - 1 - k);
					float digitScreenPosY_TopLeft = displayPosUV.y;
					// 現在のピクセルがこの桁の描画範囲内にあるかチェック
					if (i.uv.x >= digitScreenPosX_TopLeft && i.uv.x <= digitScreenPosX_TopLeft + charSizeOnScreenUV.x &&
						i.uv.y <= digitScreenPosY_TopLeft && i.uv.y >= digitScreenPosY_TopLeft - charSizeOnScreenUV.y)
					{
						if (digitValue >=0) {
							// フォントテクスチャから対応する数字をサンプリングするためのUVを計算
							float fontU_Start = fontCharSizeUV.x * digitValue;
							float fontV_Start = 0;
							float normalizedU_InChar = (i.uv.x - digitScreenPosX_TopLeft) / charSizeOnScreenUV.x;
							float normalizedV_InChar = (i.uv.y - (digitScreenPosY_TopLeft - charSizeOnScreenUV.y)) / charSizeOnScreenUV.y;
							float2 fontSampleUV = float2(fontU_Start + normalizedU_InChar * fontCharSizeUV.x, fontV_Start + normalizedV_InChar * fontCharSizeUV.y);
							fixed4 fontColor = tex2D(_NumberFontTex, fontSampleUV);
							// フォントのアルファ値を使って背景色と文字色をブレンド
							targetColor = lerp(baseColor, _NumberColor * fontColor, fontColor.a);
							return targetColor;
						}
					}
				}
				return baseColor;
			}

            fixed4 frag (v2f i) : SV_Target
            {
				// _ReadTexの左下のピクセルからスコア、コンボ、次のノーツインデックスなどの情報を取得
				float4 feedback = tex2Dlod(_ReadTex, float4(0.5 / _FeedbackTexWidth, 0.5 / _FeedbackTexHeight, 0, 0));
				
				// ゲーム開始直後はフィードバック情報をリセット
				if (_GameTime < 0.01) {
					feedback = float4(0,0,0,0);
					return float4(0,0,0,0); 
				}

				// 読み込んだフィードバックデータを元の値に復元
                float score = feedback.r * 255.0; // rチャンネル: スコア (0-1 -> 0-255)
                float combo = feedback.g * 255.0; // gチャンネル: コンボ (0-1 -> 0-255)
				// aチャンネル: 次に処理すべきノーツのインデックス
                float nextNoteIndexFloat = feedback.a * _ScoreTexWidth;
                int nextNoteIndex = floor(nextNoteIndexFloat);

				// 背景とレーンの描画
                fixed4 col = _LaneColor;
				if (i.uv.x < 0.3 || i.uv.x > 0.7) {
                    col = tex2D(_MainTex, i.uv);
                }
				// 判定ラインを描画
                if (abs(i.uv.y - _JudgeLineY) < 0.005) {
                    col = _JudgeLineColor;
                }

				// ノーツの処理と判定
                fixed4 currentEffectColor = fixed4(0,0,0,0); // このフレームで発生した判定エフェクトの色
                float currentGlobalJudge = 0.0; // このフレームの判定結果(1:P, 2:Gr, 3:Gd, 4:M)
                bool input1TriggeredThisFrame = _InputTriggerFinger1 > 0.5; // 入力1があったか
                bool input2TriggeredThisFrame = _InputTriggerFinger2 > 0.5; // 入力2があったか
                int currentProcessedNoteIndex = nextNoteIndex; // このフレームで処理するノーツインデックス

				// 譜面データをループでチェック
                for (int k = 0; k < 30; ++k) {
                    int noteIdxToCheck = nextNoteIndex + k;
                    if (noteIdxToCheck >= _ScoreTexWidth) break; // 譜面の終端

                    float4 noteData = readNoteDataFromTexture(noteIdxToCheck);
                    float noteAppearTime = noteData.r;
                    float noteType = noteData.g;

                    if (noteType <= 0.0) { // 無効なノーツデータ
                        if (k == 0 && noteIdxToCheck < _ScoreTexWidth) {
                             currentProcessedNoteIndex = noteIdxToCheck + 1;
                        }
                        continue;
                    }
					// 見逃し判定
                    if (_GameTime > noteAppearTime + _VisibleNoteTimeWindowAfter) {
                        if (noteIdxToCheck == currentProcessedNoteIndex) {
                            currentProcessedNoteIndex = noteIdxToCheck + 1;
                            combo = 0;
                        }
                        continue;
                    }
					// 描画範囲外のノーツはスキップ
                    if (_GameTime < noteAppearTime - _VisibleNoteTimeWindowBefore) {
                        break; 
                    }
					// ノーツのY座標を計算
                    float noteY = _JudgeLineY + (noteAppearTime - _GameTime) * _NoteSpeed;
                    bool noteVisible = (noteY < 1.0 && noteY > -0.1);

					// 判定処理 (処理対象のノーツのみ)
                    if (noteIdxToCheck == currentProcessedNoteIndex) {
                        float timingDiff = _GameTime - noteAppearTime;
						// 正しい入力が行われたか
                        bool correctInput = (noteType == 1.0 && input1TriggeredThisFrame) ||
                                            (noteType == 2.0 && input2TriggeredThisFrame);
						// Good判定
                        if (abs(timingDiff) < _GoodWindow + 0.01) {
                            if (correctInput) {
								// 正しい入力があった場合
                                fixed4 judgeEffectColor = _MissEffectColor;
                                float judgeValue = 4.0;
                                if (abs(timingDiff) <= _PerfectWindow) {
                                    score += 100; combo += 1; judgeValue = 1.0; judgeEffectColor = _PerfectEffectColor; // Perfect
                                } else if (abs(timingDiff) <= _GreatWindow) {
                                    score += 50; combo += 1; judgeValue = 2.0; judgeEffectColor = _GreatEffectColor; // Great
                                } else if (abs(timingDiff) <= _GoodWindow) {
                                    score += 20; combo += 1; judgeValue = 3.0; judgeEffectColor = _GoodEffectColor; // Good
                                }
                                currentProcessedNoteIndex = noteIdxToCheck + 1; // 次のノーツへ
                            } 
							// 間違った入力があった場合
                            else if ((noteType == 1.0 && input2TriggeredThisFrame) || (noteType == 2.0 && input1TriggeredThisFrame)) {
                                if (abs(timingDiff) < _GoodWindow) {
                                    combo = 0; // Miss
                                    currentProcessedNoteIndex = noteIdxToCheck + 1;
                                    currentEffectColor = _MissEffectColor;
                                    currentGlobalJudge = 4.0;
                                }
                            }
                        }
						// 時間を過ぎてMissになった場合
						else if (timingDiff > _GoodWindow) {
							combo = 0; // Miss
							currentGlobalJudge = 4.0; // Missエフェクト用
							currentEffectColor = _MissEffectColor;
							currentProcessedNoteIndex = noteIdxToCheck + 1;
						}
                    }
                    if (noteVisible && noteIdxToCheck >= currentProcessedNoteIndex) {
                        fixed4 currentNoteColor = (noteType == 1.0) ? _Note1Color : _Note2Color;
                        float noteLaneX = (noteType == 1.0) ? 0.4 : 0.6;
                        float noteSizeX = 0.15;
                        float noteSizeY = 0.05;
                        if (i.uv.x > (noteLaneX - noteSizeX/2.0) && i.uv.x < (noteLaneX + noteSizeX/2.0) &&
                            abs(i.uv.y - noteY) < noteSizeY/2.0) {
                           col = lerp(col, currentNoteColor, currentNoteColor.a);
                       }
                    }
                } 
				// 判定エフェクトとUIの描画
                if (currentGlobalJudge > 0.0 && abs(i.uv.y - _JudgeLineY) < 0.05) {
                    col = lerp(col, currentEffectColor, 0.7);
                }
                int currentScore = floor(score);
				int currentCombo = floor(combo);
				float desiredCharWidthOnScreen = 0.063;
				float fontOriginalAspectRatio = _NumberFontCharSize.x / _NumberFontCharSize.y;
				if (_NumberFontCharSize.y == 0) fontOriginalAspectRatio = 1.0;
				float desiredScreenAspectRatio = 1;
				float screenCharHeight = desiredCharWidthOnScreen / desiredScreenAspectRatio;
				// スコアを描画
				float2 scoreCharSizeOnScreen = float2(desiredCharWidthOnScreen, screenCharHeight);
				col = drawNumber(i, currentScore, _ScoreDisplayPos.xy, scoreCharSizeOnScreen,
								 _NumberFontCharSize.xy, _NumberSpacing * scoreCharSizeOnScreen.x, (int)_MaxDigits,
								 col, col);
				float desiredComboCharWidthOnScreen = 0.055;
				float comboScreenCharHeight = desiredComboCharWidthOnScreen / desiredScreenAspectRatio;
				// コンボを描画
				float2 comboCharSizeOnScreen = float2(desiredComboCharWidthOnScreen, comboScreenCharHeight);
				col = drawNumber(i, currentCombo, _ComboDisplayPos.xy, comboCharSizeOnScreen,
								 _NumberFontCharSize.xy, _NumberSpacing * comboCharSizeOnScreen.x, (int)_MaxDigits,
								 col, col);
                
				// 次のフレームへのフィードバック情報を書き込む
                if (i.uv.x < 10.0 / _FeedbackTexWidth && i.uv.y < 10.0 / _FeedbackTexHeight)
                {// 画面左下の特定領域にだけゲームの状態を書き込む
					// 次に処理すべきノーツのインデックスを0-1の範囲に正規化
                    float normalizedNextNoteIndex = saturate((float)currentProcessedNoteIndex / _ScoreTexWidth);
					// RGBAチャンネルに情報をパックして返す
                    return float4(score / 255.0,
                                  combo / 255.0,
                                  currentGlobalJudge / 4.0,
                                  normalizedNextNoteIndex);
                }
				// フィードバック書き込み領域以外はゲーム画面の色を返す
                return col;
            }
            ENDCG
        }
    }
}