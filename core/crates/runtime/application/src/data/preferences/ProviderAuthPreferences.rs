//! Encrypted persistence for provider account credentials.
//!
//! One file holds every provider credential so a future migration never has to
//! discover separate secret files. The legacy Codex file is read once and copied
//! here, after which this store is the only writer.

use operit_providers::chat::llmprovider::ProviderAuthModels::ProviderCredential;
use operit_providers::chat::llmprovider::CodexOAuth::CodexOAuthTokens;
use operit_providers::chat::llmprovider::ProviderAuthRegistry;
use operit_store::PreferencesDataStore::{
    stringPreferencesKey, CoreNodeSecretStore, Preferences, PreferencesDataStoreError,
};
use operit_store::RuntimeStorageHost::defaultRuntimeStorageHost;
use operit_util::OperitPaths;

use super::CodexAuthPreferences::CodexAuthPreferences;

const CREDENTIALS_KEY: &str = "provider_credentials";

/// Stores account credentials for every provider under one encrypted node file.
pub struct ProviderAuthPreferences {
    dataStore: CoreNodeSecretStore,
}

impl ProviderAuthPreferences {
    pub fn getInstance() -> Self {
        Self {
            dataStore: CoreNodeSecretStore::newWithStorage(
                defaultRuntimeStorageHost(),
                OperitPaths::PROVIDER_AUTH_PREFERENCES_PATH,
            )
            .withSchema(1, |version, _preferences| match version {
                0 => Ok(()),
                from => Err(PreferencesDataStoreError::MissingMigration {
                    from,
                    to: from + 1,
                }),
            }),
        }
    }

    /// Returns a credential without ever writing it to a log.
    #[operit_route_macros::operit_core_internal]
    pub fn load(&self, providerTypeId: &str) -> Result<Option<ProviderCredential>, String> {
        let preferences = self
            .dataStore
            .dataFlow()
            .first()
            .map_err(|error| error.to_string())?;
        Ok(readCredentials(&preferences)?
            .into_iter()
            .find(|credential| {
                credential
                    .provider_type_id
                    .eq_ignore_ascii_case(providerTypeId)
            }))
    }

    /// Loads every stored credential for status lists.
    #[operit_route_macros::operit_core_internal]
    pub fn loadAll(&self) -> Result<Vec<ProviderCredential>, String> {
        let preferences = self
            .dataStore
            .dataFlow()
            .first()
            .map_err(|error| error.to_string())?;
        readCredentials(&preferences)
    }

    /// Replaces one provider credential, preserving every other provider.
    #[operit_route_macros::operit_core_internal]
    pub fn save(&self, credential: &ProviderCredential) -> Result<(), String> {
        let mut credentials = self.loadAll()?;
        credentials.retain(|existing| {
            !existing
                .provider_type_id
                .eq_ignore_ascii_case(&credential.provider_type_id)
        });
        credentials.push(credential.clone());
        self.writeAll(&credentials)
    }

    /// Removes one provider credential.
    pub fn clear(&self, providerTypeId: &str) -> Result<(), String> {
        let mut credentials = self.loadAll()?;
        credentials.retain(|existing| {
            !existing
                .provider_type_id
                .eq_ignore_ascii_case(providerTypeId)
        });
        self.writeAll(&credentials)
    }

    /// Copies the legacy Codex file into the unified store exactly once.
    ///
    /// The legacy file is left untouched so a downgrade can still read it.
    #[operit_route_macros::operit_core_internal]
    pub fn migrateLegacyCodex(&self) -> Result<Option<ProviderCredential>, String> {
        if let Some(credential) = self.load(ProviderAuthRegistry::CODEX_PROVIDER_TYPE_ID)? {
            return Ok(Some(credential));
        }
        let Some(tokens) = CodexAuthPreferences::getInstance().load()? else {
            return Ok(None);
        };
        let credential = credentialFromLegacyTokens(tokens)?;
        self.save(&credential)?;
        Ok(Some(credential))
    }

    fn writeAll(&self, credentials: &[ProviderCredential]) -> Result<(), String> {
        let encoded = serde_json::to_value(credentials).map_err(|error| error.to_string())?;
        self.dataStore
            .edit(|preferences| {
                preferences.set(&stringPreferencesKey(CREDENTIALS_KEY), encoded.clone());
            })
            .map_err(|error| error.to_string())
    }
}

fn readCredentials(preferences: &Preferences) -> Result<Vec<ProviderCredential>, String> {
    let Some(encoded) = preferences.get(&stringPreferencesKey(CREDENTIALS_KEY)) else {
        return Ok(Vec::new());
    };
    serde_json::from_value(encoded.clone()).map_err(|error| error.to_string())
}

/// Projects the old token document onto the provider-neutral credential shape.
fn credentialFromLegacyTokens(tokens: CodexOAuthTokens) -> Result<ProviderCredential, String> {
    let provider = ProviderAuthRegistry::provider(ProviderAuthRegistry::CODEX_PROVIDER_TYPE_ID)
        .map_err(|error| error.message)?;
    Ok(ProviderCredential {
        provider_type_id: provider.provider_type_id.to_string(),
        auth_mode: provider.auth_mode.to_string(),
        client_id: provider.client_id.to_string(),
        subject: if tokens.accountId.is_empty() {
            "openai_chatgpt".to_string()
        } else {
            format!("openai_chatgpt:{}", tokens.accountId)
        },
        email: (!tokens.email.is_empty()).then(|| tokens.email.clone()),
        display_name: None,
        access_token: tokens.accessToken,
        refresh_token: tokens.refreshToken,
        id_token: tokens.idToken,
        account_id: (!tokens.accountId.is_empty()).then(|| tokens.accountId.clone()),
        expires_at_millis: tokens.expiresAtMillis,
        scopes: provider
            .scopes
            .iter()
            .map(|scope| (*scope).to_string())
            .collect(),
        obtained_at_millis: operit_host_api::TimeUtils::currentTimeMillis(),
    })
}
