//! Built-in account authorization registry.
//!
//! One table drives the UI capability matrix, the engine's protocol selection,
//! and error messages. Adding a provider account flow means adding one row here.

use super::ProviderAuthModels::{ProviderAuthProvider, ProviderAuthError, ProviderLoginStyle};

pub const CODEX_PROVIDER_TYPE_ID: &str = "OPENAI_CODEX";
pub const XAI_PROVIDER_TYPE_ID: &str = "XAI";
pub const KIMI_PROVIDER_TYPE_ID: &str = "MOONSHOT";
pub const OPENROUTER_PROVIDER_TYPE_ID: &str = "OPENROUTER";
pub const ANTHROPIC_PROVIDER_TYPE_ID: &str = "ANTHROPIC_CLAUDE";

const ANTHROPIC_SCOPES: &[&str] = &[
    "org:create_api_key",
    "user:profile",
    "user:inference",
    "user:sessions:claude_code",
    "user:mcp_servers",
    "user:file_upload",
];
const ANTHROPIC_REFRESH_SCOPES: &[&str] = &[
    "user:profile",
    "user:inference",
    "user:sessions:claude_code",
    "user:mcp_servers",
    "user:file_upload",
];

/// Claude Code rejects token exchange unless the caller presents the CLI
/// fingerprint, so these headers travel with every authorization request.
const ANTHROPIC_TOKEN_HEADERS: &[(&str, &str)] = &[
    ("User-Agent", "claude-cli/2.1.280 (external, cli)"),
    ("X-Stainless-Lang", "js"),
    ("X-Stainless-Package-Version", "0.106.0"),
    ("X-Stainless-OS", "Linux"),
    ("X-Stainless-Arch", "arm64"),
    ("X-Stainless-Runtime", "node"),
    ("X-Stainless-Runtime-Version", "v24.18.0"),
    ("X-Stainless-Retry-Count", "0"),
    ("X-Stainless-Timeout", "600"),
    ("X-App", "cli"),
    ("Anthropic-Dangerous-Direct-Browser-Access", "true"),
];

const PROVIDERS: &[ProviderAuthProvider] = &[
    ProviderAuthProvider {
        provider_type_id: CODEX_PROVIDER_TYPE_ID,
        auth_mode: "openai_chatgpt",
        display_name: "ChatGPT Codex",
        login_style: ProviderLoginStyle::Loopback,
        client_id: crate::chat::llmprovider::CodexOAuth::CODEX_OAUTH_CLIENT_ID,
        scopes: &["openid", "profile", "email", "offline_access"],
        authorization_endpoint: Some("https://auth.openai.com/oauth/authorize"),
        token_endpoint: "https://auth.openai.com/oauth/token",
        device_endpoint: None,
        revocation_endpoint: None,
        fixed_redirect_uri: Some("http://localhost:1455/auth/callback"),
        token_headers: &[],
        refresh_scopes: None,
        exchanges_long_lived_key: false,
    },
    ProviderAuthProvider {
        provider_type_id: XAI_PROVIDER_TYPE_ID,
        auth_mode: "xai_grok",
        display_name: "xAI Grok",
        login_style: ProviderLoginStyle::DeviceCode,
        client_id: "b1a00492-073a-47ea-816f-4c329264a828",
        scopes: &[
            "openid",
            "profile",
            "email",
            "offline_access",
            "grok-cli:access",
            "api:access",
        ],
        authorization_endpoint: None,
        token_endpoint: "https://auth.x.ai/oauth2/token",
        device_endpoint: Some("https://auth.x.ai/oauth2/device/code"),
        revocation_endpoint: Some("https://auth.x.ai/oauth2/revoke"),
        fixed_redirect_uri: None,
        token_headers: &[],
        refresh_scopes: None,
        exchanges_long_lived_key: false,
    },
    ProviderAuthProvider {
        provider_type_id: KIMI_PROVIDER_TYPE_ID,
        auth_mode: "kimi_code",
        display_name: "Kimi Code",
        login_style: ProviderLoginStyle::DeviceCode,
        client_id: "17e5f671-d194-4dfb-9706-5516cb48c098",
        // Kimi rejects an explicitly empty scope, so the field is omitted entirely.
        scopes: &[],
        authorization_endpoint: None,
        token_endpoint: "https://auth.kimi.com/api/oauth/token",
        device_endpoint: Some("https://auth.kimi.com/api/oauth/device_authorization"),
        revocation_endpoint: None,
        fixed_redirect_uri: None,
        token_headers: &[],
        refresh_scopes: None,
        exchanges_long_lived_key: false,
    },
    ProviderAuthProvider {
        provider_type_id: ANTHROPIC_PROVIDER_TYPE_ID,
        auth_mode: "anthropic_claude",
        display_name: "Claude Code",
        login_style: ProviderLoginStyle::ManualCode,
        client_id: "9d1c250a-e61b-44d9-88ed-5944d1962f5e",
        scopes: ANTHROPIC_SCOPES,
        authorization_endpoint: Some("https://claude.com/cai/oauth/authorize"),
        token_endpoint: "https://platform.claude.com/v1/oauth/token",
        device_endpoint: None,
        revocation_endpoint: None,
        fixed_redirect_uri: Some("https://platform.claude.com/oauth/code/callback"),
        token_headers: ANTHROPIC_TOKEN_HEADERS,
        refresh_scopes: Some(ANTHROPIC_REFRESH_SCOPES),
        exchanges_long_lived_key: false,
    },
    ProviderAuthProvider {
        provider_type_id: OPENROUTER_PROVIDER_TYPE_ID,
        auth_mode: "openrouter_oauth",
        display_name: "OpenRouter",
        login_style: ProviderLoginStyle::Loopback,
        client_id: "",
        scopes: &[],
        authorization_endpoint: Some("https://openrouter.ai/auth"),
        token_endpoint: "https://openrouter.ai/api/v1/auth/keys",
        device_endpoint: None,
        revocation_endpoint: None,
        fixed_redirect_uri: None,
        token_headers: &[],
        refresh_scopes: None,
        exchanges_long_lived_key: true,
    },
];

/// Returns every provider that supports account authorization.
pub fn providers() -> &'static [ProviderAuthProvider] {
    PROVIDERS
}

/// Resolves a provider by the catalog's provider type id, case-insensitively.
pub fn provider(provider_type_id: &str) -> Result<&'static ProviderAuthProvider, ProviderAuthError> {
    PROVIDERS
        .iter()
        .find(|provider| provider.provider_type_id.eq_ignore_ascii_case(provider_type_id))
        .ok_or_else(|| {
            ProviderAuthError::unsupported(format!("{provider_type_id} 不支持账号授权"))
        })
}

/// Resolves a persisted credential's provider by its auth mode.
pub fn provider_by_auth_mode(auth_mode: &str) -> Result<&'static ProviderAuthProvider, ProviderAuthError> {
    PROVIDERS
        .iter()
        .find(|provider| provider.auth_mode == auth_mode)
        .ok_or_else(|| ProviderAuthError::unsupported(format!("{auth_mode} 不支持账号授权")))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn resolves_each_supported_provider() {
        for expected in PROVIDERS {
            assert_eq!(
                provider(expected.provider_type_id).unwrap().auth_mode,
                expected.auth_mode
            );
            assert_eq!(
                provider_by_auth_mode(expected.auth_mode)
                    .unwrap()
                    .provider_type_id,
                expected.provider_type_id
            );
        }
    }

    #[test]
    fn lookup_is_case_insensitive() {
        assert_eq!(provider("openai_codex").unwrap().auth_mode, "openai_chatgpt");
    }

    #[test]
    fn unknown_provider_is_rejected() {
        assert_eq!(
            provider("UNKNOWN").unwrap_err().code,
            "unsupported_auth_mode"
        );
    }

    #[test]
    fn anthropic_uses_manual_code_and_cli_headers() {
        let anthropic = provider(ANTHROPIC_PROVIDER_TYPE_ID).unwrap();
        assert_eq!(anthropic.login_style, ProviderLoginStyle::ManualCode);
        assert_eq!(
            anthropic.fixed_redirect_uri,
            Some("https://platform.claude.com/oauth/code/callback")
        );
        assert!(anthropic
            .token_headers
            .iter()
            .any(|(name, value)| *name == "User-Agent" && value.contains("claude-cli")));
        assert!(!anthropic
            .refresh_scopes
            .unwrap()
            .contains(&"org:create_api_key"));
    }

    #[test]
    fn codex_and_openrouter_require_distinct_loopback_contracts() {
        let codex = provider(CODEX_PROVIDER_TYPE_ID).unwrap();
        let openrouter = provider(OPENROUTER_PROVIDER_TYPE_ID).unwrap();
        assert_eq!(
            codex.fixed_redirect_uri,
            Some("http://localhost:1455/auth/callback")
        );
        assert!(openrouter.fixed_redirect_uri.is_none());
        assert!(openrouter.exchanges_long_lived_key);
    }

    #[test]
    fn kimi_omits_scopes_while_xai_declares_them() {
        assert!(provider(KIMI_PROVIDER_TYPE_ID).unwrap().scopes.is_empty());
        assert!(provider(XAI_PROVIDER_TYPE_ID)
            .unwrap()
            .scopes
            .contains(&"grok-cli:access"));
    }
}
