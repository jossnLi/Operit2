use operit_host_api::HostManager::defaultHostRuntimeTaskSchedulerHost;
use operit_host_api::{HostManager, HttpHost, HttpRequestData};
use operit_providers::chat::llmprovider::CodexOAuth::{
    account_id_from_tokens, browser_authorization, poll_device_authorization_once,
    start_device_authorization, CodexBrowserAuthorization, CodexDeviceAuthorization,
    CodexOAuthTokens,
};
use operit_providers::chat::llmprovider::ProviderAuthEngine;
use operit_providers::chat::llmprovider::ProviderAuthModels::ProviderCredential;
use operit_providers::chat::llmprovider::ProviderAuthRegistry;
use serde::{Deserialize, Serialize};

use crate::data::preferences::ProviderAuthPreferences::ProviderAuthPreferences;

/// Codex subscription usage endpoint owned by ChatGPT's subscription backend.
const CODEX_USAGE_URL: &str = "https://chatgpt.com/backend-api/wham/usage";

/// Largest usage payload accepted from the subscription backend.
const CODEX_USAGE_BODY_LIMIT_BYTES: usize = 512 * 1024;


/// Public result returned after a Codex login is stored.
#[derive(Clone, Debug, PartialEq, Eq, Serialize, Deserialize)]
#[allow(non_snake_case)]
pub struct CodexLoginResult {
    pub email: String,
    pub accountId: String,
}

/// Public view of the saved ChatGPT Codex session.
#[derive(Clone, Debug, PartialEq, Eq, Serialize, Deserialize)]
#[allow(non_snake_case)]
pub struct CodexSessionStatus {
    pub signedIn: bool,
    pub email: String,
    pub accountId: String,
}

/// One measured usage window of the ChatGPT subscription.
#[derive(Clone, Debug, PartialEq, Serialize, Deserialize)]
#[allow(non_snake_case)]
pub struct CodexUsageWindow {
    pub label: String,
    pub usedPercent: i32,
    pub resetAtEpochSeconds: i64,
}

/// One raw subscription value such as credits or reset coupons.
#[derive(Clone, Debug, PartialEq, Serialize, Deserialize)]
#[allow(non_snake_case)]
pub struct CodexUsageDetail {
    pub label: String,
    pub value: String,
}

/// Live subscription usage reported by ChatGPT for the signed-in account.
#[derive(Clone, Debug, PartialEq, Serialize, Deserialize)]
#[allow(non_snake_case)]
pub struct CodexSubscriptionUsage {
    pub signedIn: bool,
    pub planType: String,
    pub windows: Vec<CodexUsageWindow>,
    pub details: Vec<CodexUsageDetail>,
}

/// Owns ChatGPT Codex login, refresh, and credential lookup.
pub struct CodexOAuthService;

impl CodexOAuthService {
    /// Creates the Codex authorization service.
    pub fn getInstance() -> Self {
        Self
    }

    /// Creates the browser authorization URL for the fixed Codex callback.
    pub fn startBrowserLogin(&self) -> Result<CodexBrowserAuthorization, String> {
        browser_authorization().map_err(|error| error.to_string())
    }

    /// Exchanges a browser callback and stores the resulting session.
    pub async fn completeBrowserLogin(
        &self,
        code: String,
        state: String,
        expectedState: String,
        codeVerifier: String,
    ) -> Result<CodexLoginResult, String> {
        if state != expectedState {
            return Err("Codex authorization state does not match".to_string());
        }
        let credential = ProviderAuthEngine::complete_browser_login(
            ProviderAuthRegistry::CODEX_PROVIDER_TYPE_ID,
            &code,
            &codeVerifier,
            "",
        )
        .await
        .map_err(|error| error.message)?;
        self.store(&credential)
    }

    /// Requests a device code for a headless Codex login.
    pub async fn startDeviceLogin(&self) -> Result<CodexDeviceAuthorization, String> {
        start_device_authorization()
            .await
            .map_err(|error| error.to_string())
    }

    /// Waits for device approval, exchanges the code, and stores the session.
    pub async fn completeDeviceLogin(
        &self,
        authorization: CodexDeviceAuthorization,
    ) -> Result<CodexLoginResult, String> {
        let tokens = poll_codex_device(&authorization).await?;
        self.store(&credentialFromTokens(tokens)?)
    }

    /// Returns whether a ChatGPT Codex session is stored, without exposing tokens.
    pub fn sessionStatus(&self) -> Result<CodexSessionStatus, String> {
        match self.loadCredential()? {
            Some(credential) => Ok(CodexSessionStatus {
                signedIn: true,
                email: credential.email.unwrap_or_default(),
                accountId: credential.account_id.unwrap_or_default(),
            }),
            None => Ok(CodexSessionStatus {
                signedIn: false,
                email: String::new(),
                accountId: String::new(),
            }),
        }
    }

    /// Returns a fresh access token and the ChatGPT account id for inference.
    #[operit_route_macros::operit_core_internal]
    pub async fn accessForRequest(&self) -> Result<(String, String), String> {
        let stored = self
            .loadCredential()?
            .ok_or_else(|| "Codex authorization is required".to_string())?;
        let storedExpiry = stored.expires_at_millis;
        let refreshed = ProviderAuthEngine::refresh_credential(stored)
            .await
            .map_err(|error| error.message)?;
        if refreshed.expires_at_millis != storedExpiry {
            self.store(&refreshed)?;
        }
        let accountId = refreshed
            .account_id
            .clone()
            .filter(|value| !value.is_empty())
            .ok_or_else(|| "Codex authorization is missing the ChatGPT account id".to_string())?;
        Ok((refreshed.access_token, accountId))
    }

    /// Removes the saved Codex session from both the unified and legacy stores.
    pub fn logout(&self) -> Result<(), String> {
        ProviderAuthPreferences::getInstance()
            .clear(ProviderAuthRegistry::CODEX_PROVIDER_TYPE_ID)?;
        crate::data::preferences::CodexAuthPreferences::CodexAuthPreferences::getInstance()
            .clear()
    }

    /// Queries live subscription usage for the signed-in ChatGPT account.
    ///
    /// The payload mirrors the fields the official Codex client shows: plan
    /// type, per-window used percentage with reset time, credits and resets.
    pub async fn subscriptionUsage(&self) -> Result<CodexSubscriptionUsage, String> {
        let status = self.sessionStatus()?;
        if !status.signedIn {
            return Ok(CodexSubscriptionUsage {
                signedIn: false,
                planType: String::new(),
                windows: Vec::new(),
                details: Vec::new(),
            });
        }
        let (accessToken, accountId) = self.accessForRequest().await?;
        let body = fetch_codex_usage(&accessToken, &accountId)?;
        parse_codex_usage(&body)
    }

    fn loadCredential(&self) -> Result<Option<ProviderCredential>, String> {
        ProviderAuthPreferences::getInstance().migrateLegacyCodex()
    }

    fn store(&self, credential: &ProviderCredential) -> Result<CodexLoginResult, String> {
        ProviderAuthPreferences::getInstance().save(credential)?;
        Ok(CodexLoginResult {
            email: credential.email.clone().unwrap_or_default(),
            accountId: credential.account_id.clone().unwrap_or_default(),
        })
    }
}

/// Projects legacy token documents into the unified credential shape.
fn credentialFromTokens(tokens: CodexOAuthTokens) -> Result<ProviderCredential, String> {
    let accountId = account_id_from_tokens(&tokens).map_err(|error| error.to_string())?;
    let provider = ProviderAuthRegistry::provider(ProviderAuthRegistry::CODEX_PROVIDER_TYPE_ID)
        .map_err(|error| error.message)?;
    Ok(ProviderCredential {
        provider_type_id: provider.provider_type_id.to_string(),
        auth_mode: provider.auth_mode.to_string(),
        client_id: provider.client_id.to_string(),
        subject: if accountId.is_empty() {
            "openai_chatgpt".to_string()
        } else {
            format!("openai_chatgpt:{accountId}")
        },
        email: (!tokens.email.is_empty()).then(|| tokens.email.clone()),
        display_name: None,
        access_token: tokens.accessToken,
        refresh_token: tokens.refreshToken,
        id_token: tokens.idToken,
        account_id: (!accountId.is_empty()).then_some(accountId),
        expires_at_millis: tokens.expiresAtMillis,
        scopes: provider
            .scopes
            .iter()
            .map(|scope| (*scope).to_string())
            .collect(),
        obtained_at_millis: operit_host_api::TimeUtils::currentTimeMillis(),
    })
}

/// Polls until the device login is approved or the Codex device timeout elapses.
async fn poll_codex_device(
    authorization: &CodexDeviceAuthorization,
) -> Result<CodexOAuthTokens, String> {
    let startedAtMillis = operit_host_api::TimeUtils::currentTimeMillisU128();
    let timeoutMillis = 15 * 60 * 1000;
    loop {
        if operit_host_api::TimeUtils::currentTimeMillisU128().saturating_sub(startedAtMillis)
            >= timeoutMillis
        {
            return Err("Codex device authorization timed out".to_string());
        }
        match poll_device_authorization_once(&authorization.deviceAuthId, &authorization.userCode)
            .await
            .map_err(|error| error.to_string())?
        {
            Some(tokens) => return Ok(tokens),
            None => {
                let delayMs = authorization.intervalSeconds.max(1).saturating_mul(1000) as u64;
                defaultHostRuntimeTaskSchedulerHost()
                    .waitForHostRuntimeDelay(delayMs)
                    .await
                    .map_err(|error| error.to_string())?;
            }
        }
    }
}

/// Reads the raw usage document with the signed-in subscription credentials.
fn fetch_codex_usage(accessToken: &str, accountId: &str) -> Result<String, String> {
    let host = HostManager::defaultHttpHost();
    let response = host
        .executeHttpRequest(HttpRequestData {
        url: CODEX_USAGE_URL.to_string(),
        method: "GET".to_string(),
        headers: vec![
            ("Accept".to_string(), "application/json".to_string()),
            (
                "Authorization".to_string(),
                format!("Bearer {accessToken}"),
            ),
            ("ChatGPT-Account-Id".to_string(), accountId.to_string()),
            (
                "User-Agent".to_string(),
                "Operit2-Codex-Usage".to_string(),
            ),
        ],
        body: Vec::new(),
        formFields: Vec::new(),
        fileParts: Vec::new(),
        connectTimeoutSeconds: 15,
        readTimeoutSeconds: 20,
        followRedirects: true,
        ignoreSsl: false,
        proxyHost: String::new(),
        proxyPort: 0,
        })
        .map_err(|error| error.to_string())?;
    if response.statusCode < 200 || response.statusCode >= 300 {
        return Err(format!("查询订阅用量失败 (HTTP {})", response.statusCode));
    }
    if response.body.len() > CODEX_USAGE_BODY_LIMIT_BYTES {
        return Err("订阅用量响应超过大小限制".to_string());
    }
    String::from_utf8(response.body).map_err(|error| error.to_string())
}

/// Projects the usage document onto the fields the provider card renders.
fn parse_codex_usage(body: &str) -> Result<CodexSubscriptionUsage, String> {
    let root: serde_json::Value =
        serde_json::from_str(body).map_err(|error| format!("无法解析订阅用量: {error}"))?;
    let mut windows = Vec::new();
    if let Some(rateLimit) = root.get("rate_limit") {
        for (key, fallbackSeconds) in [
            ("primary_window", 18_000_i64),
            ("secondary_window", 604_800_i64),
        ] {
            let Some(window) = rateLimit.get(key) else {
                continue;
            };
            let limitSeconds = window
                .get("limit_window_seconds")
                .and_then(|value| value.as_i64())
                .unwrap_or(fallbackSeconds);
            let usedPercent = window
                .get("used_percent")
                .and_then(|value| value.as_f64())
                .unwrap_or(0.0)
                .clamp(0.0, 100.0) as i32;
            let resetAt = window
                .get("reset_at")
                .and_then(|value| value.as_i64())
                .unwrap_or(0);
            windows.push(CodexUsageWindow {
                label: window_label(limitSeconds),
                usedPercent,
                resetAtEpochSeconds: resetAt,
            });
        }
    }
    let mut details = Vec::new();
    if let Some(credits) = root.get("credits") {
        if credits
            .get("unlimited")
            .and_then(|value| value.as_bool())
            .unwrap_or(false)
        {
            details.push(CodexUsageDetail {
                label: "Credits".to_string(),
                value: "Unlimited".to_string(),
            });
        } else if let Some(balance) = credits
            .get("balance")
            .and_then(|value| value.as_f64())
            .filter(|balance| *balance >= 0.0)
        {
            details.push(CodexUsageDetail {
                label: "Credits".to_string(),
                value: format_decimal(balance),
            });
        }
    }
    if let Some(resets) = root.get("rate_limit_reset_credits") {
        if let Some(count) = resets
            .get("available_count")
            .and_then(|value| value.as_i64())
            .filter(|count| *count >= 0)
        {
            details.push(CodexUsageDetail {
                label: "Resets".to_string(),
                value: count.to_string(),
            });
        }
    }
    let planType = root
        .get("plan_type")
        .and_then(|value| value.as_str())
        .unwrap_or_default()
        .to_string();
    Ok(CodexSubscriptionUsage {
        signedIn: true,
        planType,
        windows,
        details,
    })
}

/// Renders a usage window length as the compact label Codex shows.
fn window_label(seconds: i64) -> String {
    if seconds <= 0 {
        return "Window".to_string();
    }
    if seconds % 86_400 == 0 {
        return format!("{}d", seconds / 86_400);
    }
    if seconds % 3_600 == 0 {
        return format!("{}h", seconds / 3_600);
    }
    format!("{}m", seconds / 60)
}

/// Keeps whole numbers free of a trailing decimal part.
fn format_decimal(value: f64) -> String {
    if value == value.trunc() {
        format!("{}", value.trunc() as i64)
    } else {
        format!("{value:.2}")
    }
}
