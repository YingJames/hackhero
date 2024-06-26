-- create database if not exists hackhero;
-- use hackhero;
CREATE TABLE if not exists Users (
    UID INTEGER PRIMARY KEY,
    UName VARCHAR(16),
    HashedPW VARCHAR(64)
);
CREATE TABLE if not exists Admins (
    UID INTEGER,
    CONSTRAINT FK_Admin FOREIGN KEY (UID) REFERENCES Users (UID) ON DELETE CASCADE,
    CONSTRAINT PK_Admin PRIMARY KEY (UID)
);
CREATE TABLE if not exists Player (
    UID INTEGER NOT NULL,
    CONSTRAINT FK_Player FOREIGN KEY (UID) REFERENCES Users (UID) ON DELETE CASCADE,
    CONSTRAINT PK_Player PRIMARY KEY (UID)
);
CREATE TABLE if not exists Problems (
    PID INTEGER PRIMARY KEY,
    ProblemLink VARCHAR(250),
    Difficulty VARCHAR(8)
);
CREATE TABLE if not exists Topics (Type VARCHAR(20) PRIMARY KEY);

-- aggregation (RelatedTo)
CREATE TABLE if not exists Levels (
    PID INTEGER REFERENCES Problems,
    Type VARCHAR(20) REFERENCES Topics,
    CONSTRAINT PK_Quests PRIMARY KEY (PID, Type)
);
CREATE TABLE if not exists Quests (
    QID INTEGER PRIMARY KEY,
    UID INTEGER NOT NULL REFERENCES Admins (UID) ON DELETE CASCADE
);
CREATE TABLE if not exists Features (
    QID INTEGER REFERENCES Quests,
    PID INTEGER REFERENCES Problems,
    Type VARCHAR(20) REFERENCES Topics,
    CONSTRAINT PK_Features PRIMARY KEY (QID, PID, Type)
);
CREATE TABLE if not exists CompletedBy (
    UID INTEGER REFERENCES Player,
    PID INTEGER REFERENCES Problems,
    Type VARCHAR(20) REFERENCES Topics,
    Date DATE NOT NULL DEFAULT (current_date),
    CONSTRAINT PK_CompletedBy PRIMARY KEY (UID, PID, Type)
);