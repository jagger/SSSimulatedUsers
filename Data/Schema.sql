CREATE TABLE IF NOT EXISTS Config (
    Key   TEXT PRIMARY KEY,
    Value TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS ROUser (
    UserId          INTEGER PRIMARY KEY AUTOINCREMENT,
    Username        TEXT NOT NULL UNIQUE,
    Password        TEXT NOT NULL,
    Domain          TEXT NOT NULL,
    ActiveHourStart TEXT NOT NULL DEFAULT '07:00',
    ActiveHourEnd   TEXT NOT NULL DEFAULT '17:00',
    IsEnabled       INTEGER NOT NULL DEFAULT 1,
    CreatedAt            TEXT NOT NULL DEFAULT (datetime('now')),
    UpdatedAt            TEXT NOT NULL DEFAULT (datetime('now')),
    PasswordLastChanged  TEXT
);

CREATE TABLE IF NOT EXISTS ActionWeight (
    WeightId   INTEGER PRIMARY KEY AUTOINCREMENT,
    UserId     INTEGER NOT NULL REFERENCES ROUser(UserId) ON DELETE CASCADE,
    ActionName TEXT NOT NULL,
    Weight     INTEGER NOT NULL DEFAULT 10,
    UNIQUE(UserId, ActionName)
);

CREATE TABLE IF NOT EXISTS ActionLog (
    LogId        INTEGER PRIMARY KEY AUTOINCREMENT,
    Timestamp    TEXT NOT NULL DEFAULT (datetime('now')),
    UserId       INTEGER NOT NULL REFERENCES ROUser(UserId),
    Username     TEXT NOT NULL,
    ActionName   TEXT NOT NULL,
    TargetType   TEXT,
    TargetId     INTEGER,
    TargetName   TEXT,
    Result       TEXT NOT NULL,
    ErrorMessage TEXT,
    DurationMs   INTEGER
);

CREATE TABLE IF NOT EXISTS UserAccess (
    AccessId      INTEGER PRIMARY KEY AUTOINCREMENT,
    UserId        INTEGER NOT NULL REFERENCES ROUser(UserId) ON DELETE CASCADE,
    Username      TEXT NOT NULL,
    FolderCount   INTEGER NOT NULL DEFAULT 0,
    SecretCount   INTEGER NOT NULL DEFAULT 0,
    TemplateCount INTEGER NOT NULL DEFAULT 0,
    TemplateNames TEXT,                                    -- Denormalized comma-separated list for display
    CheckedAt     TEXT NOT NULL DEFAULT (datetime('now')),
    UNIQUE(UserId)                                         -- Enables upsert via ON CONFLICT
);

CREATE TABLE IF NOT EXISTS CycleLog (
    CycleId      INTEGER PRIMARY KEY AUTOINCREMENT,
    StartTime    TEXT NOT NULL,
    EndTime      TEXT,
    TotalUsers   INTEGER,
    ActiveUsers  INTEGER,
    TotalActions INTEGER,
    Errors       INTEGER
);
