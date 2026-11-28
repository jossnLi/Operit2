//! Account authorization façade used by the settings surface and chat binding.
//!
//! Only summaries cross this boundary. Access and refresh tokens stay inside the
//! runtime and are handed to inference transports through a dedicated request path.

use operit_providers::chat::llmprovider::ProviderAuthEngine;
use operit_providers::chat::llmprovider::ProviderAuthModels::{
    ProviderBrowserAuthorization, ProviderCredential, ProviderDeviceAuthorization,
    ProviderDevicePoll, ProviderLoginStyle,
};
use operit_providers::chat::llmprovider::ProviderAuthRegistry;
use serde::{Deserialize, Serialize};

use crate::data::preferences::ProviderAuthPreferences::ProviderAuthPreferences;

/// One provider row rendered by the settings surface.
#[derive(Clone, Debug, PartialEq, Eq, Serialize, Deserialize)]
#[allow(non_snake_case)]
pub struct ProviderAuthProviderView {
    pub providerTypeId: String,
    pub displayName: String,
    pub authMode: String,
    pub loginStyle: String,
    pub supportsBrowserLogin: bool,
    pub supportsDeviceLogin: bool,
    pub supportsManualLogin: bool,
    pub supportsLogout: bool,
}

/// Secret-free account state for a provider card.
#[derive(Clone, Debug, PartialEq, Eq, Serialize, Deserialize)]
#[allow(non_snake_case)]
pub struct ProviderAuthStatus {
    pub providerTypeId: String,
    pub signedIn: bool,
    pub email: String,
    pub displayName: String,
    pub planEnabled: bool,
    pub needsReauthentication: bool,
    pub expiresAtMillis: i64,
}

/// Result of a completed authorization.
#[derive(Clone, Debug, PartialEq, Eq, Serialize, Deserialize)]
#[allow(non_snake_case)]
pub struct ProviderAuthResult {
    pub providerTypeId: String,
    pub email: String,
    pub displayName: String,
    pub planEnabled: bool,
}

/// A single device poll outcome; `status` is `pending`, `slow_down`, `approved`,
/// `denied`, `expired` or `failed`.
#[derive(Clone, Debug, PartialEq, Eq, Serialize, Deserialize)]
#[allow(non_snake_case)]
pub struct ProviderDevicePollResult {
    pub status: String,
    pub account: Option<ProviderAuthResult>,
    pub message: String,
    pub nextIntervalSeconds: i64,
}

/// Provides registry metadata, login orchestration, status, and logout.
pub struct ProviderAuthService;

impl ProviderAuthService {
    pub fn getInstance() -> Self {
        Self
    }

    /// Lists every provider that supports account authorization.
    pub fn providers(&self) -> Vec<ProviderAuthProviderView> {
        ProviderAuthRegistry::providers()
            .iter()
            .map(|provider| ProviderAuthProviderView {
                providerTypeId: provider.provider_type_id.to_string(),
                displayName: provider.display_name.to_string(),
                authMode: provider.auth_mode.to_string(),
                loginStyle: provider.login_style.as_str().to_string(),
                supportsBrowserLogin: provider.login_style == ProviderLoginStyle::Loopback,
                supportsDeviceLogin: provider.login_style == ProviderLoginStyle::DeviceCode,
                supportsManualLogin: provider.login_style == ProviderLoginStyle::ManualCode,
                supportsLogout: true,
            })
            .collect()
    }

    /// Returns the stored account state for one provider.
    pub fn status(&self, providerTypeId: String) -> Result<ProviderAuthStatus, String> {
        let credential = self.load(providerTypeId.as_str())?;
        Ok(match credential {
            Some(credential) => ProviderAuthStatus {
                providerTypeId: credential.provider_type_id.clone(),
                signedIn: !credential.access_token.is_empty(),
                email: credential.email.clone().unwrap_or_default(),
                displayName: credential.display_name.clone().unwrap_or_default(),
                planEnabled: credential.plan_enabled(),
                needsReauthentication: credential
                    .is_expired(operit_host_api::TimeUtils::currentTimeMillis(), 0),
                expiresAtMillis: credential.expires_at_millis,
            },
            None => ProviderAuthStatus {
                providerTypeId,
                signedIn: false,
                email: String::new(),
                displayName: String::new(),
                planEnabled: false,
                needsReauthentication: false,
                expiresAtMillis: 0,
            },
        })
    }

    /// Returns all stored accounts for the provider list.
    pub fn statuses(&self) -> Result<Vec<ProviderAuthStatus>, String> {
        // Pull a legacy Codex session into the unified store before listing, so
        // an existing ChatGPT login is visible without opening its detail page.
        let _ = self.load(ProviderAuthRegistry::CODEX_PROVIDER_TYPE_ID)?;
        let credentials = ProviderAuthPreferences::getInstance().loadAll()?;
        Ok(credentials
            .into_iter()
            .map(|credential| ProviderAuthStatus {
                providerTypeId: credential.provider_type_id.clone(),
                signedIn: !credential.access_token.is_empty(),
                email: credential.email.clone().unwrap_or_default(),
                displayName: credential.display_name.clone().unwrap_or_default(),
                planEnabled: credential.plan_enabled(),
                needsReauthentication: credential
                    .is_expired(operit_host_api::TimeUtils::currentTimeMillis(), 0),
                expiresAtMillis: credential.expires_at_millis,
            })
            .collect())
    }

    /// Starts a browser login and returns the URL, state, and PKCE verifier.
    pub fn startBrowserLogin(
        &self,
        providerTypeId: String,
        redirectUri: String,
    ) -> Result<ProviderBrowserAuthorization, String> {
        ProviderAuthEngine::begin_browser_login(&providerTypeId, &redirectUri)
            .map_err(|error| error.message)
    }

    /// Completes a browser login after the shell receives the loopback callback.
    pub async fn completeBrowserLogin(
        &self,
        providerTypeId: String,
        code: String,
        state: String,
        expectedState: String,
        codeVerifier: String,
        redirectUri: String,
    ) -> Result<ProviderAuthResult, String> {
        if state != expectedState {
            return Err("授权回调的 state 不匹配，请重新登录".to_string());
        }
        let credential = ProviderAuthEngine::complete_browser_login(
            &providerTypeId,
            &code,
            &codeVerifier,
            &redirectUri,
        )
        .await
        .map_err(|error| error.message)?;
        self.save(credential)
    }

    /// Starts a manual-code login and returns the URL the shell should open.
    pub fn startManualLogin(
        &self,
        providerTypeId: String,
    ) -> Result<ProviderBrowserAuthorization, String> {
        ProviderAuthEngine::begin_manual_login(&providerTypeId)
            .map_err(|error| error.message)
    }

    /// Completes a manual-code login after the user pastes `code#state`.
    pub async fn completeManualLogin(
        &self,
        providerTypeId: String,
        pastedCode: String,
        expectedState: String,
        codeVerifier: String,
        redirectUri: String,
    ) -> Result<ProviderAuthResult, String> {
        let credential = ProviderAuthEngine::complete_manual_login(
            &providerTypeId,
            &pastedCode,
            &expectedState,
            &codeVerifier,
            &redirectUri,
        )
        .await
        .map_err(|error| error.message)?;
        self.save(credential)
    }

    /// Starts a device-code login.
    pub async fn startDeviceLogin(
        &self,
        providerTypeId: String,
    ) -> Result<ProviderDeviceAuthorization, String> {
        ProviderAuthEngine::begin_device_login(&providerTypeId, "")
            .await
            .map_err(|error| error.message)
    }

    /// Performs one device poll. The shell owns the interval and cancellation.
    pub async fn pollDeviceLogin(
        &self,
        providerTypeId: String,
        deviceCode: String,
    ) -> Result<ProviderDevicePollResult, String> {
        let outcome = ProviderAuthEngine::poll_device_login(&providerTypeId, &deviceCode)
            .await
            .map_err(|error| error.message)?;
        match outcome {
            ProviderDevicePoll::Pending => Ok(ProviderDevicePollResult {
                status: "pending".to_string(),
                account: None,
                message: String::new(),
                nextIntervalSeconds: 0,
            }),
            ProviderDevicePoll::SlowDown => Ok(ProviderDevicePollResult {
                status: "slow_down".to_string(),
                account: None,
                message: String::new(),
                nextIntervalSeconds: 5,
            }),
            ProviderDevicePoll::Denied => Ok(ProviderDevicePollResult {
                status: "denied".to_string(),
                account: None,
                message: "登录未获授权".to_string(),
                nextIntervalSeconds: 0,
            }),
            ProviderDevicePoll::Expired => Ok(ProviderDevicePollResult {
                status: "expired".to_string(),
                account: None,
                message: "验证码已过期，请重新登录".to_string(),
                nextIntervalSeconds: 0,
            }),
            ProviderDevicePoll::Failed(message) => Ok(ProviderDevicePollResult {
                status: "failed".to_string(),
                account: None,
                message,
                nextIntervalSeconds: 0,
            }),
            ProviderDevicePoll::Approved(credential) => {
                let account = self.save((*credential).clone())?;
                Ok(ProviderDevicePollResult {
                    status: "approved".to_string(),
                    account: Some(account),
                    message: String::new(),
                    nextIntervalSeconds: 0,
                })
            }
        }
    }

    /// Clears one provider credential without touching other accounts.
    pub fn logout(&self, providerTypeId: String) -> Result<(), String> {
        ProviderAuthPreferences::getInstance().clear(&providerTypeId)?;
        if providerTypeId.eq_ignore_ascii_case(ProviderAuthRegistry::CODEX_PROVIDER_TYPE_ID) {
            crate::data::preferences::CodexAuthPreferences::CodexAuthPreferences::getInstance()
                .clear()?;
        }
        Ok(())
    }

    /// Returns a fresh access token for an inference request. This method is
    /// intentionally not exposed to the UI proxy: tokens never cross the bridge.
    #[operit_route_macros::operit_core_internal]
    pub async fn accessTokenForRequest(
        &self,
        providerTypeId: String,
    ) -> Result<(String, Option<String>), String> {
        let credential = self
            .load(&providerTypeId)?
            .ok_or_else(|| "该服务商尚未完成账号授权".to_string())?;
        let refreshed = ProviderAuthEngine::refresh_credential(credential)
            .await
            .map_err(|error| error.message)?;
        let access_token = refreshed.access_token.clone();
        let account_id = refreshed.account_id.clone();
        self.save_silently(refreshed)?;
        Ok((access_token, account_id))
    }

    fn load(&self, providerTypeId: &str) -> Result<Option<ProviderCredential>, String> {
        if providerTypeId.eq_ignore_ascii_case(ProviderAuthRegistry::CODEX_PROVIDER_TYPE_ID) {
            return ProviderAuthPreferences::getInstance().migrateLegacyCodex();
        }
        ProviderAuthPreferences::getInstance().load(providerTypeId)
    }

    fn save(&self, credential: ProviderCredential) -> Result<ProviderAuthResult, String> {
        let result = ProviderAuthResult {
            providerTypeId: credential.provider_type_id.clone(),
            email: credential.email.clone().unwrap_or_default(),
            displayName: credential.display_name.clone().unwrap_or_default(),
            planEnabled: credential.plan_enabled(),
        };
        self.save_silently(credential)?;
        Ok(result)
    }

    fn save_silently(&self, credential: ProviderCredential) -> Result<(), String> {
        ProviderAuthPreferences::getInstance().save(&credential)
    }
}
