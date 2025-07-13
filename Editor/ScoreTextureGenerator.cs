using UnityEngine;
using UnityEditor;
using System.IO;
using System.Collections.Generic;

/// <summary>
/// ���ʃf�[�^���L�q���ꂽCSV�t�@�C����ǂݍ��݁A
/// �V�F�[�_�[�ň����f�[�^�e�N�X�`���iEXR�`���j�𐶐�����G�f�B�^�g��
/// </summary>
namespace fla_scripts
{
	public class ScoreTextureGenerator : EditorWindow
	{
		// Inspector����ݒ肷�鍀��
		public TextAsset csvFile; // �ǂݍ��ޕ��ʂ�CSV�t�@�C��
		public string outputFileName = "ScoreTexture.exr"; // �o�͂���e�N�X�`���̃t�@�C����
		public int textureWidth = 1024; // ��������e�N�X�`���̕�

		/// <summary>
		/// Unity�̃��j���[�� "Tools/Generate Score Texture" ��ǉ����A�E�B���h�E��\������
		/// </summary>
		[MenuItem ("Tools/Generate Score Texture")]
		public static void ShowWindow ()
		{
			GetWindow<ScoreTextureGenerator> ("Score Texture Generator");
		}

		void OnGUI ()
		{
			// �E�B���h�E�̃^�C�g�����x��
			GUILayout.Label ("����CSV����e�N�X�`���𐶐�", EditorStyles.boldLabel);
			// �e��ݒ荀�ڂ�GUI�ɕ\��
			csvFile = (TextAsset)EditorGUILayout.ObjectField ("����CSV�t�@�C��", csvFile, typeof (TextAsset), false);
			outputFileName = EditorGUILayout.TextField ("�o�̓t�@�C���� (.exr)", outputFileName);
			textureWidth = EditorGUILayout.IntField ("�e�N�X�`���� (�m�[�c�ő吔)", textureWidth);

			// �{�^���������ꂽ���̏���
			if (GUILayout.Button ("�e�N�X�`������"))
			{
				if (csvFile != null)
				{
					GenerateTexture ();
				}
				else
				{
					Debug.LogError ("CSV�t�@�C�����w�肵�Ă��������B");
				}
			}
		}

		/// <summary>
		/// �e�N�X�`���𐶐�����
		/// </summary>
		void GenerateTexture ()
		{
			// CSV����ǂݍ��񂾃m�[�c�f�[�^���X�g
			List<Vector4> noteDataList = new List<Vector4> ();
			// CSV�t�@�C���̃e�L�X�g�����s����('\n')�ŕ������Ċe�s���擾
			string[] lines = csvFile.text.Split ('\n');

			// �e�s����͂��ăm�[�c�f�[�^�ɕϊ�
			foreach (string line in lines)
			{
				if (string.IsNullOrWhiteSpace (line)) continue;
				string[] values = line.Split (',');
				if (values.Length >= 2)
				{
					try
					{
						// �e�s����͂��ăm�[�c�f�[�^�ɕϊ�
						float time = float.Parse (values[0].Trim ());
						float type = float.Parse (values[1].Trim ());
						// 3�ڈȍ~�̒l�͔C�ӁA�Ȃ���΃f�t�H���g�l(0f)���g�p
						float lane = (values.Length > 2) ? float.Parse (values[2].Trim ()) : 0f;
						float extra = (values.Length > 3) ? float.Parse (values[3].Trim ()) : 0f;
						// ��͂����f�[�^�����X�g�ɒǉ�
						noteDataList.Add (new Vector4 (time, type, lane, extra));
					}
					catch (System.Exception e)
					{
						Debug.LogWarning ($"CSV�̍s��̓G���[: {line} - {e.Message}");
					}
				}
			}

			// �f�[�^����
			if (noteDataList.Count == 0)
			{
				Debug.LogError ("CSV����m�[�c�f�[�^���ǂݍ��߂܂���ł����B");
				return;
			}
			if (noteDataList.Count > textureWidth)
			{
				Debug.LogWarning ($"�m�[�c��({noteDataList.Count})���e�N�X�`����({textureWidth})�𒴂��Ă��܂��B�e�N�X�`�����𑝂₷���m�[�c�����炵�Ă��������B");
			}

			// 1�s�N�Z����1�m�[�c�̏���\������f�[�^�e�N�X�`���𐶐�
			Texture2D scoreTexture = new Texture2D (textureWidth, 1, TextureFormat.RGBAHalf, false, true);
			scoreTexture.filterMode = FilterMode.Point;
			scoreTexture.wrapMode = TextureWrapMode.Clamp;

			// �e�N�X�`���������l�Ŗ��߂�
			// ���g�p�s�N�Z�������ʂł���悤�Atime�ɂ��肦�Ȃ��l(-1)�Ȃǂ����Ă���
			Color[] initialPixels = new Color[textureWidth];
			for (int i = 0; i < textureWidth; ++i)
			{
				initialPixels[i] = new Color (-1f, 0f, 0f, 0f);
			}
			scoreTexture.SetPixels (initialPixels);

			// ���X�g�̃m�[�c�f�[�^���e�N�X�`���̃s�N�Z���ɏ�������
			// 1�Ԗڂ̃m�[�c��x=0, 2�Ԗڂ̃m�[�c��x=1... �Ƃ����悤�ɔz�u����
			for (int i = 0; i < noteDataList.Count && i < textureWidth; ++i)
			{
				Vector4 data = noteDataList[i];
				scoreTexture.SetPixel (i, 0, new Color (data.x, data.y, data.z, data.w));
			}

			// SetPixel/SetPixels�ōs�����ύX���e�N�X�`���ɓK�p����
			scoreTexture.Apply (false, false);

			// �e�N�X�`����EXR�`���̃o�C�g�z��ɃG���R�[�h����
			byte[] bytes = scoreTexture.EncodeToEXR (Texture2D.EXRFlags.OutputAsFloat);

			// �t�@�C���̕ۑ��ƃC���|�[�g�ݒ�
			string csvAssetPath = AssetDatabase.GetAssetPath (csvFile);
			string outputDirectory = Path.GetDirectoryName (csvAssetPath);
			string path = Path.Combine (outputDirectory, outputFileName);
			File.WriteAllBytes (path, bytes);
			AssetDatabase.ImportAsset (path, ImportAssetOptions.ForceUpdate);

			// �C���|�[�g�����e�N�X�`���̐ݒ���f�[�^�p�ɍœK������
			TextureImporter textureImporter = AssetImporter.GetAtPath (path) as TextureImporter;
			if (textureImporter != null)
			{
				textureImporter.sRGBTexture = false;
				textureImporter.filterMode = FilterMode.Point;
				textureImporter.wrapMode = TextureWrapMode.Clamp;
				// �v���b�g�t�H�[�����Ƃ̃e�N�X�`�����k�ݒ���㏑�����t�H�[�}�b�g���ύX����Ȃ��悤�ɂ���
				TextureImporterPlatformSettings settings = textureImporter.GetDefaultPlatformTextureSettings ();
				settings.format = TextureImporterFormat.RGBAHalf;
				settings.overridden = true;
				textureImporter.SetPlatformTextureSettings (settings);

				// �ύX�����C���|�[�g�ݒ��ۑ�
				AssetDatabase.WriteImportSettingsIfDirty (path);
				AssetDatabase.Refresh ();
			}

			Debug.Log ($"���ʃe�N�X�`���� {path} �ɐ������܂����B");
			Object.DestroyImmediate (scoreTexture);
		}
	}
}