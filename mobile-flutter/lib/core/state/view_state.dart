/// Generic lifecycle status for an asynchronous operation, shared by the
/// providers so the UI can render loading / error / empty / content states
/// consistently.
enum ViewState { idle, loading, success, error }
