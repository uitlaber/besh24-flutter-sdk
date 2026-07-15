/// Besh24 mobile SDK — a typed Dart/Flutter client for the Besh24 tracking,
/// recommendations and search backend.
///
/// The public surface is intentionally small: construct a [Besh24Client], call
/// [Besh24Client.init] with a [Besh24Config], then use the tracking, profile,
/// recommendation and search methods. All calls return a [Result]; failures are
/// values, never exceptions.
///
/// Internal layers (`src/data`, `src/domain/usecases`, `src/domain/repositories`)
/// are deliberately not exported.
library besh24_sdk;

// Facade + purchase helper.
export 'src/besh24_client.dart' show Besh24Client, PurchaseItem;

// Core value types the consumer touches.
export 'src/core/config.dart' show Besh24Config;
export 'src/core/result.dart'
    show
        Result,
        Ok,
        Err,
        Besh24Error,
        NetworkError,
        ApiError,
        SerializationError,
        StorageError,
        ValidationError;
export 'src/core/logger.dart' show Besh24Logger, DefaultBesh24Logger;

// Swappable infrastructure (bring your own transport / storage).
export 'src/core/http/besh24_http_client.dart'
    show Besh24HttpClient, Besh24HttpResponse;
export 'src/core/http/http_besh24_http_client.dart' show HttpBesh24HttpClient;
export 'src/core/storage/besh24_storage.dart' show Besh24Storage;
export 'src/core/storage/in_memory_storage.dart' show InMemoryStorage;
export 'src/core/storage/shared_preferences_storage.dart'
    show SharedPreferencesStorage;
export 'src/core/clock.dart' show Clock, SystemClock;
export 'src/core/uuid_gen.dart' show UuidGenerator, UuidV4Generator;

// Domain entities returned/accepted by the facade.
export 'src/domain/entities/identity.dart' show Identity;
export 'src/domain/entities/track_event.dart' show TrackEventType;
export 'src/domain/entities/recommendation_result.dart'
    show RecommendationResult;
export 'src/domain/entities/search_result.dart'
    show SearchResult, SearchProduct;
export 'src/domain/entities/instant_search_item.dart' show InstantSearchItem;
export 'src/domain/entities/profile_input.dart' show ProfileInput, Gender;
export 'src/domain/entities/restock_input.dart' show RestockInput;
export 'src/domain/entities/push_token_input.dart' show PushTokenInput;
