Shader "Unlit/BeatGameScoreTexture_PingPong"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _GameTime ("Game Time (Anim)", Float) = 0 // ���݂̃Q�[������

		// �v���C���[�̓��̓g���K�[�i0 or 1�j
        _InputTriggerFinger1 ("Input Trigger Finger 1 (Index)", Float) = 0
        _InputTriggerFinger2 ("Input Trigger Finger 2 (Middle)", Float) = 0

        // �ǂݍ��ݗp�̃t�B�[�h�o�b�N�e�N�X�`��
        _ReadTex ("Read Feedback Texture (RenderTexture)", 2D) = "black" {}

		// ���ʃf�[�^�e�N�X�`��
        _ScoreTex ("Score Texture", 2D) = "black" {}
		// ���ʃe�N�X�`���̕��i=�ő�m�[�c��)
        _ScoreTexWidth ("Score Texture Width", Float) = 1024
		
		// �t�B�[�h�o�b�N�e�N�X�`���̉𑜓x
        _FeedbackTexWidth ("Feedback Texture Width", Float) = 256
        _FeedbackTexHeight ("Feedback Texture Height", Float) = 256

		// �Q�[���̌����ڂ┻��Ɋւ���p�����[�^
		_NoteSpeed ("Note Speed", Float) = 0.5							// �m�[�c���x
		_JudgeLineY ("Judge Line Y (UV)", Range(0,1)) = 0.2				// ���胉�C����Y���W (UV���)
		_PerfectWindow ("Perfect Window (Sec)", Float) = 0.05			// Perfect����̎��ԕ� (�b)
		_GreatWindow ("Great Window (Sec)", Float) = 0.1				// Great����̎��ԕ� (�b)
		_GoodWindow ("Good Window (Sec)", Float) = 0.15					// Good����̎��ԕ� (�b)
		_Note1Color ("Note 1 Color (Finger 1)", Color) = (1,0.5,0,1)	// �m�[�c�^�C�v1�̐F
		_Note2Color ("Note 2 Color (Finger 2)", Color) = (0,1,1,1)		// �m�[�c�^�C�v2�̐F
		_LaneColor ("Lane Color", Color) = (0.2,0.2,0.2,1)				// ���[���̐F
		_JudgeLineColor ("Judge Line Color", Color) = (1,0,0,1)			// ���胉�C���̐F
		_PerfectEffectColor ("Perfect Effect Color", Color) = (1,1,1,1)	// Perfect�G�t�F�N�g�̐F
		_GreatEffectColor ("Great Effect Color", Color) = (0,1,0,1)		// Great�G�t�F�N�g�̐F
		_GoodEffectColor ("Good Effect Color", Color) = (0,0,1,1)		// Good�G�t�F�N�g�̐F
		_MissEffectColor ("Miss Effect Color", Color) = (0.5,0.5,0.5,1)	// Miss�G�t�F�N�g�̐F
		_VisibleNoteTimeWindowBefore ("Visible Window Before (sec)", Float) = 3.0	// �m�[�c���o�����鉽�b�O����\�����邩
		_VisibleNoteTimeWindowAfter ("Visible Window After (sec)", Float) = 0.5		// �m�[�c�����胉�C�����߂��Ă��牽�b��܂ŕ\�����邩

		// �X�R�A�E�R���{�\���p�̃p�����[�^
		_NumberFontTex ("Number Font Texture (0-9)", 2D) = "white" {}	// �����t�H���g�̃e�N�X�`��
		_NumberFontCharSize ("Number Font Char Size (UV)", Vector) = (0.1, 0.2, 0, 0)	// �t�H���g�e�N�X�`������1�����̃T�C�Y(UV)
		_ScoreDisplayPos ("Score Display Pos (UV)", Vector) = (0.7, 0.9, 0, 0)			// �X�R�A�\���ʒu�̊�_(UV)
		_ComboDisplayPos ("Combo Display Pos (UV)", Vector) = (0.7, 0.8, 0, 0)			// �R���{�\���ʒu�̊�_(UV)
		_NumberSpacing ("Number Spacing (UV x-axis)", Float) = 0.08	// �����Ɛ����̊Ԋu
		_MaxDigits ("Max Digits to Display", Float) = 4				// �\������ő包��
		_NumberColor ("Number Text Color", Color) = (1,1,1,1)		// �����̐F
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
            
			// ���ʃe�N�X�`������w�肵���C���f�b�N�X�̃m�[�c�f�[�^��ǂݍ���
            float4 readNoteDataFromTexture(float index) {
                float u = (index + 0.5) / _ScoreTexWidth;
                float v = 0.5;
                return tex2Dlod(_ScoreTex, float4(u, v, 0, 0));
            }

			// ���l����w�肵�����̐������擾����
			int getDigit(int value, int digit, int maxDigits) {
				if (digit >= maxDigits) return -1;
				for (int i = 0; i < digit; ++i) { value /= 10; }
				return value % 10;
			}

			// ��ʂ̎w�肵���ʒu�ɐ��l��`�悷��
			fixed4 drawNumber(v2f i, int numberValue, float2 displayPosUV, float2 charSizeOnScreenUV, 
							  float2 fontCharSizeUV, float spacingUV_X, int maxDigitsToDraw, 
							  fixed4 baseColor, fixed4 targetColor)
			{
				int actualMaxDigits = min((int)_MaxDigits, 5); // ���[�v�񐔐����̂��ߍő�5���ɐ���
				for (int k = 0; k < actualMaxDigits; ++k) {
					int digitValue = getDigit(numberValue, k, actualMaxDigits);
					if (numberValue == 0 && k > 0) digitValue = -1;
					else if (numberValue > 0 && digitValue == 0 && numberValue < pow(10,k) ) digitValue = -1;
					if (digitValue < 0 && !(numberValue == 0 && k == 0) ) { }
					// ��ʏ�ł̊e���̕`���`���v�Z
					float digitScreenPosX_TopLeft = displayPosUV.x + (charSizeOnScreenUV.x + spacingUV_X) * (actualMaxDigits - 1 - k);
					float digitScreenPosY_TopLeft = displayPosUV.y;
					// ���݂̃s�N�Z�������̌��̕`��͈͓��ɂ��邩�`�F�b�N
					if (i.uv.x >= digitScreenPosX_TopLeft && i.uv.x <= digitScreenPosX_TopLeft + charSizeOnScreenUV.x &&
						i.uv.y <= digitScreenPosY_TopLeft && i.uv.y >= digitScreenPosY_TopLeft - charSizeOnScreenUV.y)
					{
						if (digitValue >=0) {
							// �t�H���g�e�N�X�`������Ή����鐔�����T���v�����O���邽�߂�UV���v�Z
							float fontU_Start = fontCharSizeUV.x * digitValue;
							float fontV_Start = 0;
							float normalizedU_InChar = (i.uv.x - digitScreenPosX_TopLeft) / charSizeOnScreenUV.x;
							float normalizedV_InChar = (i.uv.y - (digitScreenPosY_TopLeft - charSizeOnScreenUV.y)) / charSizeOnScreenUV.y;
							float2 fontSampleUV = float2(fontU_Start + normalizedU_InChar * fontCharSizeUV.x, fontV_Start + normalizedV_InChar * fontCharSizeUV.y);
							fixed4 fontColor = tex2D(_NumberFontTex, fontSampleUV);
							// �t�H���g�̃A���t�@�l���g���Ĕw�i�F�ƕ����F���u�����h
							targetColor = lerp(baseColor, _NumberColor * fontColor, fontColor.a);
							return targetColor;
						}
					}
				}
				return baseColor;
			}

            fixed4 frag (v2f i) : SV_Target
            {
				// _ReadTex�̍����̃s�N�Z������X�R�A�A�R���{�A���̃m�[�c�C���f�b�N�X�Ȃǂ̏����擾
				float4 feedback = tex2Dlod(_ReadTex, float4(0.5 / _FeedbackTexWidth, 0.5 / _FeedbackTexHeight, 0, 0));
				
				// �Q�[���J�n����̓t�B�[�h�o�b�N�������Z�b�g
				if (_GameTime < 0.01) {
					feedback = float4(0,0,0,0);
					return float4(0,0,0,0); 
				}

				// �ǂݍ��񂾃t�B�[�h�o�b�N�f�[�^�����̒l�ɕ���
                float score = feedback.r * 255.0; // r�`�����l��: �X�R�A (0-1 -> 0-255)
                float combo = feedback.g * 255.0; // g�`�����l��: �R���{ (0-1 -> 0-255)
				// a�`�����l��: ���ɏ������ׂ��m�[�c�̃C���f�b�N�X
                float nextNoteIndexFloat = feedback.a * _ScoreTexWidth;
                int nextNoteIndex = floor(nextNoteIndexFloat);

				// �w�i�ƃ��[���̕`��
                fixed4 col = _LaneColor;
				if (i.uv.x < 0.3 || i.uv.x > 0.7) {
                    col = tex2D(_MainTex, i.uv);
                }
				// ���胉�C����`��
                if (abs(i.uv.y - _JudgeLineY) < 0.005) {
                    col = _JudgeLineColor;
                }

				// �m�[�c�̏����Ɣ���
                fixed4 currentEffectColor = fixed4(0,0,0,0); // ���̃t���[���Ŕ�����������G�t�F�N�g�̐F
                float currentGlobalJudge = 0.0; // ���̃t���[���̔��茋��(1:P, 2:Gr, 3:Gd, 4:M)
                bool input1TriggeredThisFrame = _InputTriggerFinger1 > 0.5; // ����1����������
                bool input2TriggeredThisFrame = _InputTriggerFinger2 > 0.5; // ����2����������
                int currentProcessedNoteIndex = nextNoteIndex; // ���̃t���[���ŏ�������m�[�c�C���f�b�N�X

				// ���ʃf�[�^�����[�v�Ń`�F�b�N
                for (int k = 0; k < 30; ++k) {
                    int noteIdxToCheck = nextNoteIndex + k;
                    if (noteIdxToCheck >= _ScoreTexWidth) break; // ���ʂ̏I�[

                    float4 noteData = readNoteDataFromTexture(noteIdxToCheck);
                    float noteAppearTime = noteData.r;
                    float noteType = noteData.g;

                    if (noteType <= 0.0) { // �����ȃm�[�c�f�[�^
                        if (k == 0 && noteIdxToCheck < _ScoreTexWidth) {
                             currentProcessedNoteIndex = noteIdxToCheck + 1;
                        }
                        continue;
                    }
					// ����������
                    if (_GameTime > noteAppearTime + _VisibleNoteTimeWindowAfter) {
                        if (noteIdxToCheck == currentProcessedNoteIndex) {
                            currentProcessedNoteIndex = noteIdxToCheck + 1;
                            combo = 0;
                        }
                        continue;
                    }
					// �`��͈͊O�̃m�[�c�̓X�L�b�v
                    if (_GameTime < noteAppearTime - _VisibleNoteTimeWindowBefore) {
                        break; 
                    }
					// �m�[�c��Y���W���v�Z
                    float noteY = _JudgeLineY + (noteAppearTime - _GameTime) * _NoteSpeed;
                    bool noteVisible = (noteY < 1.0 && noteY > -0.1);

					// ���菈�� (�����Ώۂ̃m�[�c�̂�)
                    if (noteIdxToCheck == currentProcessedNoteIndex) {
                        float timingDiff = _GameTime - noteAppearTime;
						// ���������͂��s��ꂽ��
                        bool correctInput = (noteType == 1.0 && input1TriggeredThisFrame) ||
                                            (noteType == 2.0 && input2TriggeredThisFrame);
						// Good����
                        if (abs(timingDiff) < _GoodWindow + 0.01) {
                            if (correctInput) {
								// ���������͂��������ꍇ
                                fixed4 judgeEffectColor = _MissEffectColor;
                                float judgeValue = 4.0;
                                if (abs(timingDiff) <= _PerfectWindow) {
                                    score += 100; combo += 1; judgeValue = 1.0; judgeEffectColor = _PerfectEffectColor; // Perfect
                                } else if (abs(timingDiff) <= _GreatWindow) {
                                    score += 50; combo += 1; judgeValue = 2.0; judgeEffectColor = _GreatEffectColor; // Great
                                } else if (abs(timingDiff) <= _GoodWindow) {
                                    score += 20; combo += 1; judgeValue = 3.0; judgeEffectColor = _GoodEffectColor; // Good
                                }
                                currentProcessedNoteIndex = noteIdxToCheck + 1; // ���̃m�[�c��
                            } 
							// �Ԉ�������͂��������ꍇ
                            else if ((noteType == 1.0 && input2TriggeredThisFrame) || (noteType == 2.0 && input1TriggeredThisFrame)) {
                                if (abs(timingDiff) < _GoodWindow) {
                                    combo = 0; // Miss
                                    currentProcessedNoteIndex = noteIdxToCheck + 1;
                                    currentEffectColor = _MissEffectColor;
                                    currentGlobalJudge = 4.0;
                                }
                            }
                        }
						// ���Ԃ��߂���Miss�ɂȂ����ꍇ
						else if (timingDiff > _GoodWindow) {
							combo = 0; // Miss
							currentGlobalJudge = 4.0; // Miss�G�t�F�N�g�p
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
				// ����G�t�F�N�g��UI�̕`��
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
				// �X�R�A��`��
				float2 scoreCharSizeOnScreen = float2(desiredCharWidthOnScreen, screenCharHeight);
				col = drawNumber(i, currentScore, _ScoreDisplayPos.xy, scoreCharSizeOnScreen,
								 _NumberFontCharSize.xy, _NumberSpacing * scoreCharSizeOnScreen.x, (int)_MaxDigits,
								 col, col);
				float desiredComboCharWidthOnScreen = 0.055;
				float comboScreenCharHeight = desiredComboCharWidthOnScreen / desiredScreenAspectRatio;
				// �R���{��`��
				float2 comboCharSizeOnScreen = float2(desiredComboCharWidthOnScreen, comboScreenCharHeight);
				col = drawNumber(i, currentCombo, _ComboDisplayPos.xy, comboCharSizeOnScreen,
								 _NumberFontCharSize.xy, _NumberSpacing * comboCharSizeOnScreen.x, (int)_MaxDigits,
								 col, col);
                
				// ���̃t���[���ւ̃t�B�[�h�o�b�N������������
                if (i.uv.x < 10.0 / _FeedbackTexWidth && i.uv.y < 10.0 / _FeedbackTexHeight)
                {// ��ʍ����̓���̈�ɂ����Q�[���̏�Ԃ���������
					// ���ɏ������ׂ��m�[�c�̃C���f�b�N�X��0-1�͈̔͂ɐ��K��
                    float normalizedNextNoteIndex = saturate((float)currentProcessedNoteIndex / _ScoreTexWidth);
					// RGBA�`�����l���ɏ����p�b�N���ĕԂ�
                    return float4(score / 255.0,
                                  combo / 255.0,
                                  currentGlobalJudge / 4.0,
                                  normalizedNextNoteIndex);
                }
				// �t�B�[�h�o�b�N�������ݗ̈�ȊO�̓Q�[����ʂ̐F��Ԃ�
                return col;
            }
            ENDCG
        }
    }
}