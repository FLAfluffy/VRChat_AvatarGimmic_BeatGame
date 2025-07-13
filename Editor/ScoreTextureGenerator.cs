using UnityEngine;
using UnityEditor;
using System.IO;
using System.Collections.Generic;

/// <summary>
/// 譜面データが記述されたCSVファイルを読み込み、
/// シェーダーで扱うデータテクスチャ（EXR形式）を生成するエディタ拡張
/// </summary>
namespace fla_scripts
{
	public class ScoreTextureGenerator : EditorWindow
	{
		// Inspectorから設定する項目
		public TextAsset csvFile; // 読み込む譜面のCSVファイル
		public string outputFileName = "ScoreTexture.exr"; // 出力するテクスチャのファイル名
		public int textureWidth = 1024; // 生成するテクスチャの幅

		/// <summary>
		/// Unityのメニューに "Tools/Generate Score Texture" を追加し、ウィンドウを表示する
		/// </summary>
		[MenuItem ("Tools/Generate Score Texture")]
		public static void ShowWindow ()
		{
			GetWindow<ScoreTextureGenerator> ("Score Texture Generator");
		}

		void OnGUI ()
		{
			// ウィンドウのタイトルラベル
			GUILayout.Label ("譜面CSVからテクスチャを生成", EditorStyles.boldLabel);
			// 各種設定項目をGUIに表示
			csvFile = (TextAsset)EditorGUILayout.ObjectField ("譜面CSVファイル", csvFile, typeof (TextAsset), false);
			outputFileName = EditorGUILayout.TextField ("出力ファイル名 (.exr)", outputFileName);
			textureWidth = EditorGUILayout.IntField ("テクスチャ幅 (ノーツ最大数)", textureWidth);

			// ボタンが押された時の処理
			if (GUILayout.Button ("テクスチャ生成"))
			{
				if (csvFile != null)
				{
					GenerateTexture ();
				}
				else
				{
					Debug.LogError ("CSVファイルを指定してください。");
				}
			}
		}

		/// <summary>
		/// テクスチャを生成する
		/// </summary>
		void GenerateTexture ()
		{
			// CSVから読み込んだノーツデータリスト
			List<Vector4> noteDataList = new List<Vector4> ();
			// CSVファイルのテキストを改行文字('\n')で分割して各行を取得
			string[] lines = csvFile.text.Split ('\n');

			// 各行を解析してノーツデータに変換
			foreach (string line in lines)
			{
				if (string.IsNullOrWhiteSpace (line)) continue;
				string[] values = line.Split (',');
				if (values.Length >= 2)
				{
					try
					{
						// 各行を解析してノーツデータに変換
						float time = float.Parse (values[0].Trim ());
						float type = float.Parse (values[1].Trim ());
						// 3つ目以降の値は任意、なければデフォルト値(0f)を使用
						float lane = (values.Length > 2) ? float.Parse (values[2].Trim ()) : 0f;
						float extra = (values.Length > 3) ? float.Parse (values[3].Trim ()) : 0f;
						// 解析したデータをリストに追加
						noteDataList.Add (new Vector4 (time, type, lane, extra));
					}
					catch (System.Exception e)
					{
						Debug.LogWarning ($"CSVの行解析エラー: {line} - {e.Message}");
					}
				}
			}

			// データ検証
			if (noteDataList.Count == 0)
			{
				Debug.LogError ("CSVからノーツデータが読み込めませんでした。");
				return;
			}
			if (noteDataList.Count > textureWidth)
			{
				Debug.LogWarning ($"ノーツ数({noteDataList.Count})がテクスチャ幅({textureWidth})を超えています。テクスチャ幅を増やすかノーツを減らしてください。");
			}

			// 1ピクセルで1ノーツの情報を表現するデータテクスチャを生成
			Texture2D scoreTexture = new Texture2D (textureWidth, 1, TextureFormat.RGBAHalf, false, true);
			scoreTexture.filterMode = FilterMode.Point;
			scoreTexture.wrapMode = TextureWrapMode.Clamp;

			// テクスチャを初期値で埋める
			// 未使用ピクセルを識別できるよう、timeにありえない値(-1)などを入れておく
			Color[] initialPixels = new Color[textureWidth];
			for (int i = 0; i < textureWidth; ++i)
			{
				initialPixels[i] = new Color (-1f, 0f, 0f, 0f);
			}
			scoreTexture.SetPixels (initialPixels);

			// リストのノーツデータをテクスチャのピクセルに書き込む
			// 1番目のノーツはx=0, 2番目のノーツはx=1... というように配置する
			for (int i = 0; i < noteDataList.Count && i < textureWidth; ++i)
			{
				Vector4 data = noteDataList[i];
				scoreTexture.SetPixel (i, 0, new Color (data.x, data.y, data.z, data.w));
			}

			// SetPixel/SetPixelsで行った変更をテクスチャに適用する
			scoreTexture.Apply (false, false);

			// テクスチャをEXR形式のバイト配列にエンコードする
			byte[] bytes = scoreTexture.EncodeToEXR (Texture2D.EXRFlags.OutputAsFloat);

			// ファイルの保存とインポート設定
			string csvAssetPath = AssetDatabase.GetAssetPath (csvFile);
			string outputDirectory = Path.GetDirectoryName (csvAssetPath);
			string path = Path.Combine (outputDirectory, outputFileName);
			File.WriteAllBytes (path, bytes);
			AssetDatabase.ImportAsset (path, ImportAssetOptions.ForceUpdate);

			// インポートしたテクスチャの設定をデータ用に最適化する
			TextureImporter textureImporter = AssetImporter.GetAtPath (path) as TextureImporter;
			if (textureImporter != null)
			{
				textureImporter.sRGBTexture = false;
				textureImporter.filterMode = FilterMode.Point;
				textureImporter.wrapMode = TextureWrapMode.Clamp;
				// プラットフォームごとのテクスチャ圧縮設定も上書きしフォーマットが変更されないようにする
				TextureImporterPlatformSettings settings = textureImporter.GetDefaultPlatformTextureSettings ();
				settings.format = TextureImporterFormat.RGBAHalf;
				settings.overridden = true;
				textureImporter.SetPlatformTextureSettings (settings);

				// 変更したインポート設定を保存
				AssetDatabase.WriteImportSettingsIfDirty (path);
				AssetDatabase.Refresh ();
			}

			Debug.Log ($"譜面テクスチャを {path} に生成しました。");
			Object.DestroyImmediate (scoreTexture);
		}
	}
}