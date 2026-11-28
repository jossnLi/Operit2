//! Provider-neutral account credential and authorization value types.
//!
//! Tokens are never printed: every type that carries them implements a redacted
//! `Debug`, and persistence is delegated to the runtime credential store.

use serde::{Deserialize, Serialize};

/// How the provider performs an account authorization.
#[derive(Clone, Copy, Debug, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum ProviderLoginStyle {
    /// Browser authorization returning to a loopback callback owned by the UI.
    Loopback,
    /// Device code shown to the user while the app polls the token endpoint.
    DeviceCode,
    /// Browser authorization that ends on a provider-hosted page; the user
    /// copies the displayed `code#state` back into the app.
    ManualCode,
}

impl ProviderLoginStyle {
    pub fn as_str(self) -> &'static str {
        match self {
            Self::Loopback => "loopback",
            Self::DeviceCode => "device_code",
            Self::ManualCode => "manual_code",
        }
    }
}

/// Immutable authorization contract for one provider.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct ProviderAuthProvider {
    pub provider_type_id: &'static str,
    pub auth_mode: &'static str,
    pub display_name: &'static str,
    pub login_style: ProviderLoginStyle,
    pub client_id: &'static str,
    pub scopes: &'static [&'static str],
    pub authorization_endpoint: Option<&'static str>,
    pub token_endpoint: &'static str,
    pub device_endpoint: Option<&'static str>,
    pub revocation_endpoint: Option<&'static str>,
    pub fixed_redirect_uri: Option<&'static str>,
    /// Extra fingerprint required by some CLI clients during token exchange.
    pub token_headers: &'static [(&'static str, &'static str)],
    /// Scopes sent on refresh; Anthropic intentionally drops `org:create_api_key`.
    pub refresh_scopes: Option<&'static [&'static str]>,
    /// OpenRouter authorizes a long-lived API key via a JSON key exchange.
    pub exchanges_long_lived_key: bool,
}

/// Browser authorization material held by the caller until the callback.
#[derive(Clone, Serialize, Deserialize)]
pub struct ProviderBrowserAuthorization {
    pub provider_type_id: String,
    pub authorization_url: String,
    pub state: String,
    pub code_verifier: String,
    pub redirect_uri: String,
    pub expires_at_millis: i64,
}

impl std::fmt::Debug for ProviderBrowserAuthorization {
    fn fmt(&self, formatter: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        formatter
            .debug_struct("ProviderBrowserAuthorization")
            .field("provider_type_id", &self.provider_type_id)
            .field("authorization_url", &self.authorization_url)
            .field("redirect_uri", &self.redirect_uri)
            .field("expires_at_millis", &self.expires_at_millis)
            .finish_non_exhaustive()
    }
}

/// Device authorization shown to the user before polling starts.
#[derive(Clone, Serialize, Deserialize)]
pub struct ProviderDeviceAuthorization {
    pub provider_type_id: String,
    pub device_code: String,
    pub user_code: String,
    pub verification_url: String,
    pub interval_seconds: u64,
    pub expires_at_millis: i64,
}

impl std::fmt::Debug for ProviderDeviceAuthorization {
    fn fmt(&self, formatter: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        formatter
            .debug_struct("ProviderDeviceAuthorization")
            .field("provider_type_id", &self.provider_type_id)
            .field("user_code", &self.user_code)
            .field("verification_url", &self.verification_url)
            .field("interval_seconds", &self.interval_seconds)
            .field("expires_at_millis", &self.expires_at_millis)
            .finish_non_exhaustive()
    }
}

/// Result of a single device-token poll.
#[derive(Clone, Debug)]
pub enum ProviderDevicePoll {
    Pending,
    SlowDown,
    Approved(Box<ProviderCredential>),
    Denied,
    Expired,
    Failed(String),
}

/// Persisted account credential shared by every provider with account auth.
#[derive(Clone, Serialize, Deserialize)]
pub struct ProviderCredential {
    pub provider_type_id: String,
    pub auth_mode: String,
    pub client_id: String,
    pub subject: String,
    pub email: Option<String>,
    pub display_name: Option<String>,
    pub access_token: String,
    pub refresh_token: String,
    pub id_token: String,
    pub account_id: Option<String>,
    pub expires_at_millis: i64,
    pub scopes: Vec<String>,
    pub obtained_at_millis: i64,
}

impl ProviderCredential {
    /// A provider-specific plan gate, evaluated without any network request.
    pub fn plan_enabled(&self) -> bool {
        match self.auth_mode.as_str() {
            "openai_chatgpt" => self.account_id.as_deref().is_some_and(|id| !id.is_empty()),
            "xai_grok" => self.has_scope("grok-cli:access"),
            "kimi_code" | "openrouter_oauth" => !self.access_token.is_empty(),
            "anthropic_claude" => {
                !self.access_token.is_empty() && self.has_scope("user:inference")
            }
            _ => false,
        }
    }

    pub fn has_scope(&self, scope: &str) -> bool {
        self.scopes.iter().any(|existing| existing == scope)
    }

    pub fn is_expired(&self, now_millis: i64, skew_millis: i64) -> bool {
        self.expires_at_millis > 0
            && self.expires_at_millis.saturating_sub(skew_millis) <= now_millis
    }

    pub fn summary(&self) -> ProviderAccountSummary {
        ProviderAccountSummary {
            email: self.email.clone(),
            display_name: self.display_name.clone(),
            plan_enabled: self.plan_enabled(),
            needs_reauth: self.access_token.is_empty(),
        }
    }

    /// Removes secrets before a credential crosses into UI-facing metadata.
    pub fn without_secrets(&self) -> Self {
        let mut copy = self.clone();
        copy.access_token.clear();
        copy.refresh_token.clear();
        copy.id_token.clear();
        copy.account_id = None;
        copy.expires_at_millis = 0;
        copy
    }
}

impl std::fmt::Debug for ProviderCredential {
    fn fmt(&self, formatter: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        let mut summary = self.summary();
        summary.plan_enabled = self.plan_enabled();
        formatter
            .debug_struct("ProviderCredential")
            .field("provider_type_id", &self.provider_type_id)
            .field("auth_mode", &self.auth_mode)
            .field("subject", &self.subject)
            .field("email", &self.email)
            .field("display_name", &self.display_name)
            .field("expires_at_millis", &self.expires_at_millis)
            .field("plan_enabled", &summary.plan_enabled)
            .finish_non_exhaustive()
    }
}

/// Secret-free metadata for lists and settings surfaces.
#[derive(Clone, Debug, PartialEq, Eq, Serialize, Deserialize)]
pub struct ProviderAccountSummary {
    pub email: Option<String>,
    pub display_name: Option<String>,
    pub plan_enabled: bool,
    pub needs_reauth: bool,
}

/// Failure taxonomy; messages are user-presentable and never include tokens.
#[derive(Clone, Debug, PartialEq, Eq, Serialize, Deserialize)]
pub struct ProviderAuthError {
    pub code: String,
    pub message: String,
}

impl ProviderAuthError {
    pub fn new(code: impl Into<String>, message: impl Into<String>) -> Self {
        Self {
            code: code.into(),
            message: message.into(),
        }
    }

    pub fn unsupported(message: impl Into<String>) -> Self {
        Self::new("unsupported_auth_mode", message)
    }

    pub fn invalid_response() -> Self {
        Self::new("oauth_invalid_response", "授权服务返回的数据无效")
    }

    pub fn request_failed(status: u16) -> Self {
        Self::new(
            "oauth_request_failed",
            format!("授权请求失败（HTTP {status}），请稍后重试"),
        )
    }
}

impl std::fmt::Display for ProviderAuthError {
    fn fmt(&self, formatter: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(formatter, "{}: {}", self.code, self.message)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn credential(auth_mode: &str, scopes: &[&str]) -> ProviderCredential {
        ProviderCredential {
            provider_type_id: "XAI".into(),
            auth_mode: auth_mode.into(),
            client_id: "client".into(),
            subject: "subject".into(),
            email: None,
            display_name: None,
            access_token: "token".into(),
            refresh_token: String::new(),
            id_token: String::new(),
            account_id: None,
            expires_at_millis: 10_000,
            scopes: scopes.iter().map(|scope| (*scope).to_string()).collect(),
            obtained_at_millis: 1,
        }
    }

    #[test]
    fn plan_gate_uses_scopes_for_xai() {
        let without = credential("xai_grok", &["openid"]);
        let with = credential("xai_grok", &["openid", "grok-cli:access"]);
        assert!(!without.plan_enabled());
        assert!(with.plan_enabled());
    }

    #[test]
    fn expiry_uses_safety_skew() {
        let value = credential("kimi_code", &[]);
        assert!(!value.is_expired(0, 5_000));
        assert!(value.is_expired(10_000, 5_000));
    }

    #[test]
    fn debug_never_prints_tokens() {
        let value = credential("kimi_code", &[]);
        let rendered = format!("{value:?}");
        assert!(!rendered.contains("token"));
        assert!(rendered.contains("kimi_code"));
    }

    #[test]
    fn sanitized_copy_drops_secrets() {
        let value = credential("kimi_code", &[]);
        let sanitized = value.without_secrets();
        assert!(sanitized.access_token.is_empty());
        assert!(sanitized.refresh_token.is_empty());
        assert_eq!(sanitized.subject, value.subject);
    }
}
