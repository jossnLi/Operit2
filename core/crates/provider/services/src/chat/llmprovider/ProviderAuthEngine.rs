//! Provider-neutral account authorization engine.
//!
//! The engine owns protocol construction and token exchange only. It deliberately
//! does not open a local callback server: the Flutter shell already binds the
//! loopback listener and hands the code and state back, which keeps platform
//! networking in one place and makes every step testable without sockets.

use base64::engine::general_purpose::URL_SAFE_NO_PAD;
use base64::Engine;
use serde_json::Value;
use sha2::{Digest, Sha256};

use super::ProviderAuthModels::{
    ProviderAuthError, ProviderAuthProvider, ProviderBrowserAuthorization,
    ProviderCredential, ProviderDeviceAuthorization, ProviderDevicePoll, ProviderLoginStyle,
};
use super::ProviderAuthRegistry;
use super::ProviderHttp;

const BROWSER_LOGIN_LIFETIME_MILLIS: i64 = 10 * 60 * 1_000;
const PERMANENT_KEY_LIFETIME_MILLIS: i64 = 10 * 365 * 24 * 60 * 60 * 1_000;
const MAX_TOKEN_LIFETIME_SECONDS: i64 = 31_536_000;
const REFRESH_SKEW_MILLIS: i64 = 60_000;

/// Builds a browser authorization request. The caller supplies the loopback
/// redirect URI, except for Codex, whose public client only accepts port 1455.
pub fn begin_browser_login(
    provider_type_id: &str,
    redirect_uri: &str,
) -> Result<ProviderBrowserAuthorization, ProviderAuthError> {
    let provider = ProviderAuthRegistry::provider(provider_type_id)?;
    if provider.login_style != ProviderLoginStyle::Loopback {
        return Err(ProviderAuthError::unsupported("该服务商不支持浏览器授权"));
    }
    let redirect_uri = provider.fixed_redirect_uri.unwrap_or(redirect_uri);
    if redirect_uri.trim().is_empty() {
        return Err(ProviderAuthError::new(
            "oauth_callback_unavailable",
            "缺少登录回调地址，请重试",
        ));
    }

    // Codex carries extra CLI parameters that its public client validates.
    if provider.provider_type_id == ProviderAuthRegistry::CODEX_PROVIDER_TYPE_ID {
        let authorization = crate::chat::llmprovider::CodexOAuth::browser_authorization()
            .map_err(|error| ProviderAuthError::new("oauth_request_failed", error.to_string()))?;
        return Ok(ProviderBrowserAuthorization {
            provider_type_id: provider.provider_type_id.to_string(),
            authorization_url: authorization.authorizationUrl,
            state: authorization.state,
            code_verifier: authorization.codeVerifier,
            redirect_uri: authorization.redirectUri,
            expires_at_millis: now_millis().saturating_add(BROWSER_LOGIN_LIFETIME_MILLIS),
        });
    }

    let state = random_value()?;
    let code_verifier = random_value()?;
    let challenge = pkce_challenge(&code_verifier);
    let mut url = url::Url::parse(
        provider
            .authorization_endpoint
            .ok_or_else(|| ProviderAuthError::unsupported("该服务商缺少授权端点"))?,
    )
    .map_err(|_| ProviderAuthError::invalid_response())?;
    {
        let mut query = url.query_pairs_mut();
        if provider.exchanges_long_lived_key {
            query
                .append_pair("callback_url", redirect_uri)
                .append_pair("code_challenge", &challenge)
                .append_pair("code_challenge_method", "S256")
                .append_pair("state", &state);
        } else {
            query
                .append_pair("client_id", provider.client_id)
                .append_pair("response_type", "code")
                .append_pair("redirect_uri", redirect_uri)
                .append_pair("scope", &provider.scopes.join(" "))
                .append_pair("state", &state)
                .append_pair("code_challenge", &challenge)
                .append_pair("code_challenge_method", "S256");
        }
    }
    Ok(ProviderBrowserAuthorization {
        provider_type_id: provider.provider_type_id.to_string(),
        authorization_url: url.to_string(),
        state,
        code_verifier,
        redirect_uri: redirect_uri.to_string(),
        expires_at_millis: now_millis().saturating_add(BROWSER_LOGIN_LIFETIME_MILLIS),
    })
}

/// Builds the manual-code authorization URL used by Claude Code. The provider
/// keeps the callback on its own HTTPS page, so no local listener is opened.
pub fn begin_manual_login(
    provider_type_id: &str,
) -> Result<ProviderBrowserAuthorization, ProviderAuthError> {
    let provider = ProviderAuthRegistry::provider(provider_type_id)?;
    if provider.login_style != ProviderLoginStyle::ManualCode {
        return Err(ProviderAuthError::unsupported("该服务商不支持手动授权码"));
    }
    let redirect_uri = provider.fixed_redirect_uri.ok_or_else(|| {
        ProviderAuthError::new("oauth_callback_unavailable", "缺少登录回调地址，请重试")
    })?;
    let state = random_value()?;
    let code_verifier = random_value()?;
    let challenge = pkce_challenge(&code_verifier);
    let mut url = url::Url::parse(
        provider
            .authorization_endpoint
            .ok_or_else(|| ProviderAuthError::unsupported("该服务商缺少授权端点"))?,
    )
    .map_err(|_| ProviderAuthError::invalid_response())?;
    {
        let mut query = url.query_pairs_mut();
        query
            .append_pair("client_id", provider.client_id)
            .append_pair("response_type", "code")
            .append_pair("redirect_uri", redirect_uri)
            .append_pair("scope", &provider.scopes.join(" "))
            .append_pair("state", &state)
            .append_pair("code_challenge_method", "S256")
            .append_pair("code_challenge", &challenge)
            .append_pair("code", "true");
    }
    Ok(ProviderBrowserAuthorization {
        provider_type_id: provider.provider_type_id.to_string(),
        authorization_url: url.to_string(),
        state,
        code_verifier,
        redirect_uri: redirect_uri.to_string(),
        expires_at_millis: now_millis().saturating_add(BROWSER_LOGIN_LIFETIME_MILLIS),
    })
}

/// Completes a manual-code login. The provider displays `code#state`; the state
/// half must match the one this device generated before the code is exchanged.
pub async fn complete_manual_login(
    provider_type_id: &str,
    pasted_code: &str,
    expected_state: &str,
    code_verifier: &str,
    redirect_uri: &str,
) -> Result<ProviderCredential, ProviderAuthError> {
    let provider = ProviderAuthRegistry::provider(provider_type_id)?;
    if provider.login_style != ProviderLoginStyle::ManualCode {
        return Err(ProviderAuthError::unsupported("该服务商不支持手动授权码"));
    }
    if code_verifier.trim().is_empty() || redirect_uri.trim().is_empty() {
        return Err(ProviderAuthError::invalid_response());
    }
    let (code, returned_state) = split_manual_code(pasted_code, expected_state)?;
    if code.len() > 4_096 || returned_state != expected_state.trim() {
        return Err(ProviderAuthError::new(
            "oauth_state_mismatch",
            "授权码与本次登录不匹配，请重新登录",
        ));
    }
    let body = serde_json::json!({
        "grant_type": "authorization_code",
        "client_id": provider.client_id,
        "code": code,
        "code_verifier": code_verifier,
        "redirect_uri": redirect_uri,
        "state": expected_state,
    });
    let (status, response) = ProviderHttp::auth_post_json(
        provider.token_endpoint,
        &body,
        provider.token_headers,
    )
    .await
    .map_err(|_| ProviderAuthError::request_failed(0))?;
    if !(200..300).contains(&status) {
        return Err(oauth_failure(status, &response));
    }
    let json: Value =
        serde_json::from_str(&response).map_err(|_| ProviderAuthError::invalid_response())?;
    credential_from_token_response(provider, &json, None, provider.scopes)
}

/// Splits the provider-displayed `code#state` payload without trusting it.
fn split_manual_code<'a>(
    pasted_code: &'a str,
    expected_state: &'a str,
) -> Result<(&'a str, &'a str), ProviderAuthError> {
    let pasted = pasted_code.trim();
    if pasted.is_empty() || pasted.len() > 4_096 {
        return Err(ProviderAuthError::invalid_response());
    }
    let (code, state) = match pasted.split_once('#') {
        Some((code, state)) => (code.trim(), state.trim()),
        None => (pasted, expected_state.trim()),
    };
    if code.is_empty() || state.is_empty() {
        return Err(ProviderAuthError::invalid_response());
    }
    Ok((code, state))
}

/// Exchanges a browser callback code for a credential. Codex keeps its existing
/// protocol implementation; OpenRouter exchanges the code for a long-lived key.
pub async fn complete_browser_login(
    provider_type_id: &str,
    code: &str,
    code_verifier: &str,
    _redirect_uri: &str,
) -> Result<ProviderCredential, ProviderAuthError> {
    let provider = ProviderAuthRegistry::provider(provider_type_id)?;
    if provider.login_style != ProviderLoginStyle::Loopback {
        return Err(ProviderAuthError::unsupported("该服务商不支持浏览器授权"));
    }
    if code.trim().is_empty() || code_verifier.trim().is_empty() {
        return Err(ProviderAuthError::invalid_response());
    }

    if provider.provider_type_id == ProviderAuthRegistry::CODEX_PROVIDER_TYPE_ID {
        let tokens = crate::chat::llmprovider::CodexOAuth::exchange_browser_code(code, code_verifier)
            .await
            .map_err(|_| ProviderAuthError::new("oauth_request_failed", "Codex 授权换码失败，请重试"))?;
        let now = now_millis();
        return Ok(ProviderCredential {
            provider_type_id: provider.provider_type_id.to_string(),
            auth_mode: provider.auth_mode.to_string(),
            client_id: provider.client_id.to_string(),
            subject: codex_subject(&tokens),
            email: non_empty(&tokens.email),
            display_name: None,
            access_token: tokens.accessToken,
            refresh_token: tokens.refreshToken,
            id_token: tokens.idToken,
            account_id: non_empty(&tokens.accountId),
            expires_at_millis: tokens.expiresAtMillis,
            scopes: strings(provider.scopes),
            obtained_at_millis: now,
        });
    }

    let body = serde_json::json!({
        "code": code,
        "code_verifier": code_verifier,
        "code_challenge_method": "S256",
    });
    let (status, response) =
        ProviderHttp::auth_post_json(provider.token_endpoint, &body, &[]).await
            .map_err(|_| ProviderAuthError::request_failed(0))?;
    if !(200..300).contains(&status) {
        return Err(ProviderAuthError::request_failed(status));
    }
    let json: Value = serde_json::from_str(&response).map_err(|_| ProviderAuthError::invalid_response())?;

    if provider.exchanges_long_lived_key {
        let key = json
            .get("key")
            .and_then(Value::as_str)
            .filter(|value| !value.is_empty() && value.len() <= 8_192)
            .ok_or_else(ProviderAuthError::invalid_response)?;
        let now = now_millis();
        return Ok(ProviderCredential {
            provider_type_id: provider.provider_type_id.to_string(),
            auth_mode: provider.auth_mode.to_string(),
            client_id: String::new(),
            subject: format!("openrouter:{}", token_fingerprint(key)),
            email: None,
            display_name: None,
            access_token: key.to_string(),
            refresh_token: String::new(),
            id_token: String::new(),
            account_id: None,
            expires_at_millis: now.saturating_add(PERMANENT_KEY_LIFETIME_MILLIS),
            scopes: Vec::new(),
            obtained_at_millis: now,
        });
    }

    credential_from_token_response(provider, &json, None, provider.scopes)
}

/// Starts a device-code login. Kimi's client rejects an explicit scope field,
/// so the field is omitted whenever the registry declares no scopes.
pub async fn begin_device_login(
    provider_type_id: &str,
    redirect_uri: &str,
) -> Result<ProviderDeviceAuthorization, ProviderAuthError> {
    let provider = ProviderAuthRegistry::provider(provider_type_id)?;
    if provider.login_style != ProviderLoginStyle::DeviceCode {
        return Err(ProviderAuthError::unsupported("该服务商不支持设备码登录"));
    }
    let endpoint = provider
        .device_endpoint
        .ok_or_else(|| ProviderAuthError::unsupported("该服务商缺少设备码端点"))?;
    let mut form = vec![("client_id", provider.client_id)];
    let joined_scopes = provider.scopes.join(" ");
    if !provider.scopes.is_empty() {
        form.push(("scope", joined_scopes.as_str()));
    }
    // Codex's device flow has a distinct device-auth protocol and is intentionally
    // not routed through this generic endpoint.
    let _ = redirect_uri;
    let (status, body) = ProviderHttp::auth_post_form(endpoint, &form)
        .await
        .map_err(|_| ProviderAuthError::request_failed(0))?;
    if !(200..300).contains(&status) {
        return Err(ProviderAuthError::request_failed(status));
    }
    let json: Value = serde_json::from_str(&body).map_err(|_| ProviderAuthError::invalid_response())?;
    let device_code = required_string(&json, "device_code", 65_536)?;
    let user_code = required_string(&json, "user_code", 128)?;
    let verification_url = json
        .get("verification_uri_complete")
        .and_then(Value::as_str)
        .filter(|value| !value.is_empty())
        .or_else(|| json.get("verification_uri").and_then(Value::as_str))
        .ok_or_else(ProviderAuthError::invalid_response)?;
    validate_device_url(provider, verification_url)?;
    let expires_in = positive_seconds(&json, "expires_in")?;
    let interval_seconds = if json.get("interval").is_some() {
        positive_seconds(&json, "interval")?
    } else {
        5
    };
    Ok(ProviderDeviceAuthorization {
        provider_type_id: provider.provider_type_id.to_string(),
        device_code,
        user_code,
        verification_url: verification_url.to_string(),
        interval_seconds: interval_seconds as u64,
        expires_at_millis: now_millis().saturating_add(expires_in.saturating_mul(1_000)),
    })
}

/// Performs one device-token poll. The UI owns the delay loop so a cancelled
/// login can stop immediately without a Rust-side timer.
pub async fn poll_device_login(
    provider_type_id: &str,
    device_code: &str,
) -> Result<ProviderDevicePoll, ProviderAuthError> {
    let provider = ProviderAuthRegistry::provider(provider_type_id)?;
    if provider.login_style != ProviderLoginStyle::DeviceCode {
        return Err(ProviderAuthError::unsupported("该服务商不支持设备码登录"));
    }
    if device_code.trim().is_empty() {
        return Err(ProviderAuthError::invalid_response());
    }
    let form = [
        ("grant_type", "urn:ietf:params:oauth:grant-type:device_code"),
        ("client_id", provider.client_id),
        ("device_code", device_code),
    ];
    let (status, body) = ProviderHttp::auth_post_form(provider.token_endpoint, &form)
        .await
        .map_err(|_| ProviderAuthError::new("oauth_network_error", "网络请求失败，请重试"))?;
    let json: Value = serde_json::from_str(&body).unwrap_or(Value::Null);
    if (200..300).contains(&status) {
        return credential_from_token_response(provider, &json, None, provider.scopes)
            .map(|credential| ProviderDevicePoll::Approved(Box::new(credential)));
    }
    let error = json
        .get("error")
        .and_then(Value::as_str)
        .unwrap_or_default();
    Ok(match error {
        "authorization_pending" => ProviderDevicePoll::Pending,
        "slow_down" => ProviderDevicePoll::SlowDown,
        "access_denied" => ProviderDevicePoll::Denied,
        "expired_token" => ProviderDevicePoll::Expired,
        "invalid_client" => ProviderDevicePoll::Failed("授权服务不接受此客户端".into()),
        _ => ProviderDevicePoll::Failed(format!("授权请求失败（HTTP {status}）")),
    })
}

/// Refreshes an expiring credential. OpenRouter holds a long-lived key and has
/// no refresh semantics; Codex reuses its existing refresh path.
pub async fn refresh_credential(
    credential: ProviderCredential,
) -> Result<ProviderCredential, ProviderAuthError> {
    let provider = ProviderAuthRegistry::provider_by_auth_mode(&credential.auth_mode)?;
    if provider.exchanges_long_lived_key {
        return Ok(credential);
    }
    if credential.refresh_token.trim().is_empty() {
        return Err(ProviderAuthError::new("oauth_session_expired", "登录已失效，请重新登录"));
    }

    let now = now_millis();
    if !credential.is_expired(now, REFRESH_SKEW_MILLIS) {
        return Ok(credential);
    }

    if provider.provider_type_id == ProviderAuthRegistry::CODEX_PROVIDER_TYPE_ID {
        let tokens = crate::chat::llmprovider::CodexOAuth::CodexOAuthTokens {
            accessToken: credential.access_token.clone(),
            refreshToken: credential.refresh_token.clone(),
            idToken: credential.id_token.clone(),
            accountId: credential.account_id.clone().unwrap_or_default(),
            email: credential.email.clone().unwrap_or_default(),
            expiresAtMillis: credential.expires_at_millis,
        };
        let refreshed = crate::chat::llmprovider::CodexOAuth::ensure_fresh_tokens(tokens)
            .await
            .map_err(|_| ProviderAuthError::new("oauth_request_failed", "Codex 登录续期失败，请重试"))?;
        let mut next = credential;
        next.access_token = refreshed.accessToken;
        next.refresh_token = refreshed.refreshToken;
        next.id_token = refreshed.idToken;
        next.account_id = non_empty(&refreshed.accountId);
        next.email = non_empty(&refreshed.email);
        next.expires_at_millis = refreshed.expiresAtMillis;
        next.obtained_at_millis = now;
        return Ok(next);
    }

    if provider.provider_type_id == ProviderAuthRegistry::ANTHROPIC_PROVIDER_TYPE_ID {
        let scopes = provider.refresh_scopes.unwrap_or(provider.scopes);
        let body = serde_json::json!({
            "grant_type": "refresh_token",
            "client_id": provider.client_id,
            "refresh_token": credential.refresh_token,
            "scope": scopes.join(" "),
        });
        let (status, response) = ProviderHttp::auth_post_json(
            provider.token_endpoint,
            &body,
            provider.token_headers,
        )
        .await
        .map_err(|_| ProviderAuthError::new("oauth_network_error", "网络请求失败，请重试"))?;
        if !(200..300).contains(&status) {
            return Err(oauth_failure(status, &response));
        }
        let json: Value = serde_json::from_str(&response)
            .map_err(|_| ProviderAuthError::invalid_response())?;
        return credential_from_token_response(provider, &json, Some(&credential), scopes);
    }

    let form = [
        ("grant_type", "refresh_token"),
        ("client_id", provider.client_id),
        ("refresh_token", credential.refresh_token.as_str()),
    ];
    let (status, body) = ProviderHttp::auth_post_form(provider.token_endpoint, &form)
        .await
        .map_err(|_| ProviderAuthError::new("oauth_network_error", "网络请求失败，请重试"))?;
    if !(200..300).contains(&status) {
        return Err(oauth_failure(status, &body));
    }
    let json: Value = serde_json::from_str(&body).map_err(|_| ProviderAuthError::invalid_response())?;
    let previous_scopes: Vec<&str> = credential
        .scopes
        .iter()
        .map(String::as_str)
        .collect();
    credential_from_token_response(provider, &json, Some(&credential), &previous_scopes)
}

/// Revokes the refresh token when the provider exposes a revocation endpoint.
pub async fn revoke_credential(
    credential: &ProviderCredential,
) -> Result<Option<bool>, ProviderAuthError> {
    if credential.refresh_token.trim().is_empty() {
        return Ok(Some(true));
    }
    let provider = ProviderAuthRegistry::provider_by_auth_mode(&credential.auth_mode)?;
    let Some(endpoint) = provider.revocation_endpoint else {
        return Ok(None);
    };
    let form = [
        ("token", credential.refresh_token.as_str()),
        ("token_type_hint", "refresh_token"),
        ("client_id", provider.client_id),
    ];
    let (status, _) = ProviderHttp::auth_post_form(endpoint, &form)
        .await
        .map_err(|_| ProviderAuthError::new("oauth_network_error", "网络请求失败，请重试"))?;
    Ok(Some((200..300).contains(&status)))
}

fn credential_from_token_response(
    provider: &ProviderAuthProvider,
    json: &Value,
    previous: Option<&ProviderCredential>,
    default_scopes: &[&str],
) -> Result<ProviderCredential, ProviderAuthError> {
    let access_token = required_string(json, "access_token", 65_536)?;
    let token_type = json.get("token_type").and_then(Value::as_str).unwrap_or_default();
    if !token_type.is_empty() && !token_type.eq_ignore_ascii_case("Bearer") {
        return Err(ProviderAuthError::invalid_response());
    }
    let expires_in = positive_seconds(json, "expires_in")?;
    let refresh_token = json
        .get("refresh_token")
        .and_then(Value::as_str)
        .filter(|value| !value.is_empty())
        .map(str::to_string)
        .or_else(|| previous.map(|value| value.refresh_token.clone()))
        .unwrap_or_default();
    let id_token = json
        .get("id_token")
        .and_then(Value::as_str)
        .filter(|value| !value.is_empty())
        .map(str::to_string)
        .or_else(|| previous.map(|value| value.id_token.clone()))
        .unwrap_or_default();

    let claims = decode_jwt_claims(&id_token);
    // Claude's token response has no id_token; identity comes from the account
    // object or, on refresh without that object, from the previous credential.
    let anthropic_account = (provider.auth_mode == "anthropic_claude")
        .then(|| anthropic_account_identity(json, previous, &access_token));
    let subject = claims
        .as_ref()
        .and_then(|claims| claims.get("sub"))
        .and_then(Value::as_str)
        .filter(|value| !value.is_empty())
        .map(|value| format!("{}:{value}", provider.auth_mode))
        .or_else(|| anthropic_account.as_ref().map(|account| account.0.clone()))
        .or_else(|| previous.map(|value| value.subject.clone()))
        // Kimi does not always return an id_token; a token fingerprint is still a
        // stable local identity and never leaves the device.
        .unwrap_or_else(|| format!("{}:{}", provider.auth_mode, token_fingerprint(&access_token)));
    let email = claims
        .as_ref()
        .and_then(|claims| claims.get("email"))
        .and_then(Value::as_str)
        .filter(|value| !value.is_empty())
        .map(str::to_string)
        .or_else(|| anthropic_account.as_ref().and_then(|account| account.1.clone()))
        .or_else(|| previous.and_then(|value| value.email.clone()));
    let display_name = claims
        .as_ref()
        .and_then(|claims| claims.get("name"))
        .and_then(Value::as_str)
        .filter(|value| !value.is_empty())
        .map(str::to_string)
        .or_else(|| anthropic_account.as_ref().and_then(|account| account.2.clone()))
        .or_else(|| previous.and_then(|value| value.display_name.clone()));
    let scopes = json
        .get("scope")
        .and_then(Value::as_str)
        .filter(|value| !value.is_empty())
        .map(|value| value.split_whitespace().map(str::to_string).collect())
        .or_else(|| previous.map(|value| value.scopes.clone()))
        .unwrap_or_else(|| strings(default_scopes));
    let account_id = if provider.provider_type_id == ProviderAuthRegistry::CODEX_PROVIDER_TYPE_ID {
        claims
            .as_ref()
            .and_then(codex_account_id)
            .or_else(|| previous.and_then(|value| value.account_id.clone()))
    } else {
        None
    };
    let now = now_millis();
    Ok(ProviderCredential {
        provider_type_id: provider.provider_type_id.to_string(),
        auth_mode: provider.auth_mode.to_string(),
        client_id: provider.client_id.to_string(),
        subject,
        email,
        display_name,
        access_token,
        refresh_token,
        id_token,
        account_id,
        expires_at_millis: now.saturating_add(expires_in.saturating_mul(1_000)),
        scopes,
        obtained_at_millis: now,
    })
}

fn anthropic_account_identity(
    json: &Value,
    previous: Option<&ProviderCredential>,
    access_token: &str,
) -> (String, Option<String>, Option<String>) {
    let account = json.get("account");
    let uuid = account
        .and_then(|value| value.get("uuid"))
        .and_then(Value::as_str)
        .filter(|value| !value.is_empty());
    let subject = uuid
        .map(|value| format!("anthropic:{value}"))
        .or_else(|| previous.map(|value| value.subject.clone()))
        .unwrap_or_else(|| format!("anthropic:{}", token_fingerprint(access_token)));
    let email = account
        .and_then(|value| {
            value
                .get("email_address")
                .or_else(|| value.get("email"))
        })
        .and_then(Value::as_str)
        .filter(|value| !value.is_empty())
        .map(str::to_string)
        .or_else(|| previous.and_then(|value| value.email.clone()));
    let display_name = account
        .and_then(|value| value.get("display_name"))
        .and_then(Value::as_str)
        .filter(|value| !value.is_empty())
        .map(str::to_string)
        .or_else(|| previous.and_then(|value| value.display_name.clone()));
    (subject, email, display_name)
}

fn codex_subject(
    tokens: &crate::chat::llmprovider::CodexOAuth::CodexOAuthTokens,
) -> String {
    let claims = decode_jwt_claims(&tokens.idToken);
    claims
        .as_ref()
        .and_then(|claims| claims.get("sub"))
        .and_then(Value::as_str)
        .map(|value| format!("openai_chatgpt:{value}"))
        .unwrap_or_else(|| format!("openai_chatgpt:{}", token_fingerprint(&tokens.accessToken)))
}

fn codex_account_id(claims: &Value) -> Option<String> {
    claims
        .get("https://api.openai.com/auth")
        .and_then(|auth| auth.get("chatgpt_account_id"))
        .and_then(Value::as_str)
        .filter(|value| !value.is_empty())
        .map(str::to_string)
}

fn decode_jwt_claims(token: &str) -> Option<Value> {
    let payload = token.split('.').nth(1)?;
    let bytes = URL_SAFE_NO_PAD.decode(payload).ok()?;
    serde_json::from_slice(&bytes).ok()
}

fn token_fingerprint(token: &str) -> String {
    let digest = Sha256::digest(token.as_bytes());
    URL_SAFE_NO_PAD.encode(&digest[..16])
}

fn validate_device_url(
    provider: &ProviderAuthProvider,
    value: &str,
) -> Result<(), ProviderAuthError> {
    let url = url::Url::parse(value).map_err(|_| ProviderAuthError::invalid_response())?;
    let host = url.host_str().unwrap_or_default();
    let allowed = match provider.provider_type_id {
        ProviderAuthRegistry::XAI_PROVIDER_TYPE_ID => {
            matches!(host, "auth.x.ai" | "accounts.x.ai" | "grok.com" | "www.grok.com")
        }
        ProviderAuthRegistry::KIMI_PROVIDER_TYPE_ID => {
            matches!(host, "auth.kimi.com" | "kimi.com" | "www.kimi.com")
        }
        _ => false,
    };
    if url.scheme() != "https" || !allowed || url.port_or_known_default() != Some(443) {
        return Err(ProviderAuthError::invalid_response());
    }
    Ok(())
}

fn oauth_failure(status: u16, body: &str) -> ProviderAuthError {
    let code = serde_json::from_str::<Value>(body)
        .ok()
        .and_then(|json| json.get("error").and_then(Value::as_str).map(str::to_string))
        .unwrap_or_default();
    match code.as_str() {
        "invalid_grant" | "invalid_refresh_token" | "token_expired" | "refresh_token_expired"
        | "refresh_token_invalidated" | "refresh_token_reused" => {
            ProviderAuthError::new("oauth_session_expired", "登录已失效，请重新登录")
        }
        "invalid_client" => {
            ProviderAuthError::new("oauth_client_rejected", "授权服务未接受此客户端")
        }
        _ => ProviderAuthError::request_failed(status),
    }
}

fn required_string(json: &Value, key: &str, limit: usize) -> Result<String, ProviderAuthError> {    json.get(key)
        .and_then(Value::as_str)
        .filter(|value| !value.is_empty() && value.len() <= limit)
        .map(str::to_string)
        .ok_or_else(ProviderAuthError::invalid_response)
}

fn positive_seconds(json: &Value, key: &str) -> Result<i64, ProviderAuthError> {
    let value = json.get(key).and_then(|value| {
        value
            .as_i64()
            .or_else(|| value.as_str().and_then(|text| text.parse().ok()))
    });
    match value {
        Some(seconds) if (1..=MAX_TOKEN_LIFETIME_SECONDS).contains(&seconds) => Ok(seconds),
        _ => Err(ProviderAuthError::invalid_response()),
    }
}

fn random_value() -> Result<String, ProviderAuthError> {
    let mut bytes = [0u8; 32];
    getrandom::getrandom(&mut bytes).map_err(|_| {
        ProviderAuthError::new("oauth_entropy_unavailable", "无法生成安全的登录参数，请重试")
    })?;
    Ok(URL_SAFE_NO_PAD.encode(bytes))
}

fn pkce_challenge(verifier: &str) -> String {
    let digest = Sha256::digest(verifier.as_bytes());
    URL_SAFE_NO_PAD.encode(digest)
}

fn non_empty(value: &str) -> Option<String> {
    (!value.trim().is_empty()).then(|| value.to_string())
}

fn strings(values: &[&str]) -> Vec<String> {
    values.iter().map(|value| (*value).to_string()).collect()
}

fn now_millis() -> i64 {
    operit_host_api::TimeUtils::currentTimeMillis()
}

#[cfg(test)]
mod tests {
    use super::*;
    use serde_json::json;

    #[test]
    fn pkce_challenge_matches_rfc_vector() {
        // RFC 7636 appendix B.
        assert_eq!(
            pkce_challenge("dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk"),
            "E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM"
        );
    }

    #[test]
    fn codex_browser_authorization_uses_fixed_callback() {
        let start = begin_browser_login("OPENAI_CODEX", "").unwrap();
        assert_eq!(start.redirect_uri, "http://localhost:1455/auth/callback");
        assert!(start.authorization_url.contains("codex_cli_simplified_flow=true"));
        assert!(!start.authorization_url.contains("openrouter"));
    }

    #[test]
    fn openrouter_authorization_requires_caller_callback() {
        let start = begin_browser_login(
            "OPENROUTER",
            "http://127.0.0.1:53682/auth/callback",
        )
        .unwrap();
        assert!(start
            .authorization_url
            .contains("callback_url=http%3A%2F%2F127.0.0.1%3A53682"));
        assert!(start.authorization_url.contains("code_challenge_method=S256"));
        assert_eq!(start.state.len(), 43);
    }

    #[test]
    fn empty_callback_is_rejected_for_openrouter() {
        assert_eq!(
            begin_browser_login("OPENROUTER", "").unwrap_err().code,
            "oauth_callback_unavailable"
        );
    }

    #[test]
    fn manual_login_uses_claude_callback_and_pkce() {
        let start = begin_manual_login("ANTHROPIC_CLAUDE").unwrap();
        assert_eq!(
            start.redirect_uri,
            "https://platform.claude.com/oauth/code/callback"
        );
        assert!(start.authorization_url.contains("code=true"));
        assert!(start.authorization_url.contains("code_challenge_method=S256"));
        assert!(start
            .authorization_url
            .contains("user%3Asessions%3Aclaude_code"));
        assert_eq!(
            split_manual_code("#state", &start.state)
                .unwrap_err()
                .code,
            "oauth_invalid_response"
        );
    }

    #[test]
    fn manual_code_accepts_displayed_state_and_plain_code() {
        assert_eq!(
            split_manual_code("abc#xyz", "xyz").unwrap(),
            ("abc", "xyz")
        );
        assert_eq!(
            split_manual_code("abc", "xyz").unwrap(),
            ("abc", "xyz")
        );
        assert!(split_manual_code("abc#wrong", "xyz").is_ok());
    }

    #[test]
    fn anthropic_identity_prefers_account_uuid() {
        let json = json!({
            "access_token": "a",
            "expires_in": 3600,
            "account": {
                "uuid": "u-1",
                "email_address": "a@b.c",
                "display_name": "A"
            }
        });
        let provider = ProviderAuthRegistry::provider("ANTHROPIC_CLAUDE").unwrap();
        let credential =
            credential_from_token_response(provider, &json, None, provider.scopes).unwrap();
        assert_eq!(credential.subject, "anthropic:u-1");
        assert_eq!(credential.email.as_deref(), Some("a@b.c"));
        assert_eq!(credential.display_name.as_deref(), Some("A"));
        assert!(credential.plan_enabled());
    }

    #[test]
    fn device_provider_rejects_browser_login() {
        assert_eq!(
            begin_browser_login("XAI", "http://localhost/callback")
                .unwrap_err()
                .code,
            "unsupported_auth_mode"
        );
    }

    #[test]
    fn jwt_identity_comes_from_payload() {
        let payload = URL_SAFE_NO_PAD.encode(br#"{"sub":"abc","email":"a@b.c","name":"A"}"#);
        let token = format!("header.{payload}.signature");
        let claims = decode_jwt_claims(&token).unwrap();
        assert_eq!(claims["sub"], "abc");
    }

    #[test]
    fn token_response_requires_bearer_and_positive_lifetime() {
        let provider = ProviderAuthRegistry::provider("XAI").unwrap();
        let json = json!({ "access_token": "a", "token_type": "bearer", "expires_in": 3600 });
        let credential =
            credential_from_token_response(provider, &json, None, provider.scopes).unwrap();
        assert_eq!(credential.auth_mode, "xai_grok");
        assert_eq!(credential.scopes, strings(provider.scopes));
    }

    #[test]
    fn non_bearer_token_is_rejected() {
        let provider = ProviderAuthRegistry::provider("XAI").unwrap();
        let json = json!({ "access_token": "a", "token_type": "mac", "expires_in": 3600 });
        assert_eq!(
            credential_from_token_response(provider, &json, None, provider.scopes)
                .unwrap_err()
                .code,
            "oauth_invalid_response"
        );
    }

    #[test]
    fn refresh_preserves_identity_when_id_token_is_absent() {
        let provider = ProviderAuthRegistry::provider("XAI").unwrap();
        let previous = ProviderCredential {
            provider_type_id: "XAI".into(),
            auth_mode: "xai_grok".into(),
            client_id: provider.client_id.into(),
            subject: "xai_grok:stable".into(),
            email: Some("a@b.c".into()),
            display_name: Some("A".into()),
            access_token: "old".into(),
            refresh_token: "refresh".into(),
            id_token: String::new(),
            account_id: None,
            expires_at_millis: 1,
            scopes: vec!["grok-cli:access".into()],
            obtained_at_millis: 1,
        };
        let json = json!({ "access_token": "new", "token_type": "Bearer", "expires_in": 3600 });
        let next =
            credential_from_token_response(provider, &json, Some(&previous), provider.scopes)
                .unwrap();
        assert_eq!(next.subject, "xai_grok:stable");
        assert_eq!(next.email.as_deref(), Some("a@b.c"));
        assert_eq!(next.refresh_token, "refresh");
    }

    #[test]
    fn device_urls_are_allowlisted() {
        let provider = ProviderAuthRegistry::provider("MOONSHOT").unwrap();
        assert!(validate_device_url(provider, "https://auth.kimi.com/device").is_ok());
        assert!(validate_device_url(provider, "https://evil.example/device").is_err());
    }
}
