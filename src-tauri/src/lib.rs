use serde::Deserialize;
use std::collections::HashMap;
use std::sync::Mutex;
use tauri::Emitter;
use tauri::Manager;
use tokio::io::AsyncWriteExt;
use tokio_util::sync::CancellationToken;

#[derive(Default)]
struct DownloadCancels(Mutex<HashMap<String, CancellationToken>>);

#[tauri::command]
fn greet(name: &str) -> String {
    format!("Hello, {}! You've been greeted from Rust!", name)
}

/// Fetch Openlyst /apps/{slug}/latest from the backend to avoid CORS in production (tauri://localhost).
#[tauri::command]
async fn fetch_openlyst_latest(app_slug: String, lang: String) -> Result<String, String> {
    const BASE: &str = "https://openlyst.ink/api/v1";
    let url = format!("{BASE}/apps/{app_slug}/latest?lang={lang}");
    let client = reqwest::Client::builder()
        .connect_timeout(std::time::Duration::from_secs(10))
        .build()
        .map_err(|e| e.to_string())?;
    let body = client
        .get(&url)
        .header("Accept", "application/json")
        .send()
        .await
        .map_err(|e| e.to_string())?
        .error_for_status()
        .map_err(|e| e.to_string())?
        .text()
        .await
        .map_err(|e| e.to_string())?;
    Ok(body)
}

/// Returns the app's downloads directory path (e.g. app_data/Finar/Downloads).
#[tauri::command]
async fn get_downloads_dir(app: tauri::AppHandle) -> Result<String, String> {
    let app_data = app
        .path()
        .app_data_dir()
        .map_err(|e| e.to_string())?;
    let downloads = app_data.join("Finar").join("Downloads");
    tokio::fs::create_dir_all(&downloads)
        .await
        .map_err(|e| e.to_string())?;
    downloads
        .into_os_string()
        .into_string()
        .map_err(|_| "Invalid path".to_string())
}

#[derive(Deserialize)]
struct DownloadMediaFilePayload {
    url: String,
    path: String,
    #[serde(default)]
    auth_header: Option<String>,
    task_id: String,
}

/// Downloads a file from URL to path, emitting "download://progress" events.
/// Runs on a background task so the invoke returns immediately and the UI stays responsive.
#[tauri::command]
async fn download_media_file(
    app: tauri::AppHandle,
    state: tauri::State<'_, DownloadCancels>,
    payload: DownloadMediaFilePayload,
) -> Result<(), String> {
    let client = reqwest::Client::builder()
        .connect_timeout(std::time::Duration::from_secs(15))
        .build()
        .map_err(|e| e.to_string())?;

    if let Some(parent) = std::path::Path::new(&payload.path).parent() {
        tokio::fs::create_dir_all(parent)
            .await
            .map_err(|e| e.to_string())?;
    }

    let cancel = CancellationToken::new();
    {
        let mut map = state.0.lock().map_err(|_| "lock failed")?;
        map.insert(payload.task_id.clone(), cancel.clone());
    }

    let task_id = payload.task_id.clone();
    let path = payload.path.clone();
    let url = payload.url.clone();
    let auth_header = payload.auth_header.clone();
    let app = app.clone();

    tauri::async_runtime::spawn(async move {
        use futures_util::StreamExt;

        let result = async {
            let mut request = client.get(&url);
            if let Some(ref h) = auth_header {
                request = request.header("X-Emby-Authorization", h);
            }
            let response = request
                .send()
                .await
                .map_err(|e| e.to_string())?;
            if !response.status().is_success() {
                return Err::<(), String>(format!("HTTP {}", response.status()));
            }
            let total = response.content_length().unwrap_or(0);
            let stream = response.bytes_stream();
            let file = tokio::fs::File::create(&path)
                .await
                .map_err(|e| e.to_string())?;
            let mut file = tokio::io::BufWriter::new(file);
            let mut stream = std::pin::pin!(stream);
            let mut downloaded: u64 = 0;
            const PROGRESS_INTERVAL_MS: u64 = 150;
            let mut last_emit = tokio::time::Instant::now();

            loop {
                tokio::select! {
                    _ = cancel.cancelled() => return Err("cancelled".to_string()),
                    chunk = stream.next() => {
                        let Some(chunk) = chunk else { break };
                        let chunk = chunk.map_err(|e| e.to_string())?;
                        let len = chunk.len() as u64;
                        file.write_all(&chunk).await.map_err(|e| e.to_string())?;
                        downloaded += len;
                        if last_emit.elapsed().as_millis() as u64 >= PROGRESS_INTERVAL_MS {
                            last_emit = tokio::time::Instant::now();
                            let _ = app.emit(
                                "download://progress",
                                serde_json::json!({
                                    "taskId": task_id,
                                    "downloaded": downloaded,
                                    "total": total,
                                }),
                            );
                        }
                    }
                }
            }
            let _ = app.emit(
                "download://progress",
                serde_json::json!({
                    "taskId": task_id,
                    "downloaded": downloaded,
                    "total": total,
                }),
            );
            file.flush().await.map_err(|e| e.to_string())
        }
        .await;

        if let Some(state) = app.try_state::<DownloadCancels>() {
            let mut map = state.0.lock().unwrap();
            map.remove(&task_id);
        }

        match result {
            Ok(()) => {
                let _ = app.emit(
                    "download://complete",
                    serde_json::json!({ "taskId": task_id, "path": path }),
                );
            }
            Err(e) => {
                let _ = app.emit(
                    "download://error",
                    serde_json::json!({ "taskId": task_id, "error": e }),
                );
            }
        }
    });

    Ok(())
}

#[tauri::command]
fn cancel_download(state: tauri::State<'_, DownloadCancels>, task_id: String) -> Result<(), String> {
    let mut map = state.0.lock().map_err(|_| "lock failed")?;
    if let Some(token) = map.remove(&task_id) {
        token.cancel();
    }
    Ok(())
}

/// Deletes a file; path must be under the app downloads directory.
#[tauri::command]
async fn delete_download_file(app: tauri::AppHandle, path: String) -> Result<(), String> {
    let base = get_downloads_dir(app).await?;
    let path = std::path::Path::new(&path).canonicalize().map_err(|e| e.to_string())?;
    let base = std::path::Path::new(&base).canonicalize().map_err(|e| e.to_string())?;
    if !path.starts_with(&base) {
        return Err("Path not allowed".to_string());
    }
    if path.is_file() {
        tokio::fs::remove_file(&path).await.map_err(|e| e.to_string())?;
    }
    Ok(())
}

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    tauri::Builder::default()
        .plugin(tauri_plugin_devtools::init())
        .plugin(tauri_plugin_devtools_app::init())
        .plugin(tauri_plugin_opener::init())
        .plugin(tauri_plugin_fs::init())
        .manage(DownloadCancels::default())
        .invoke_handler(tauri::generate_handler![
            greet,
            fetch_openlyst_latest,
            get_downloads_dir,
            download_media_file,
            cancel_download,
            delete_download_file,
        ])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
