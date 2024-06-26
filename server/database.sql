CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE if not exists Users (
    UID UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    UName VARCHAR(16),
    HashedPW VARCHAR(64)
);
CREATE TABLE if not exists Admins (
    UID UUID,
    CONSTRAINT FK_Admin FOREIGN KEY (UID) REFERENCES Users (UID) ON DELETE CASCADE,
    CONSTRAINT PK_Admin PRIMARY KEY (UID)
);
CREATE TABLE if not exists Player (
    UID UUID NOT NULL,
    CONSTRAINT FK_Player FOREIGN KEY (UID) REFERENCES Users (UID) ON DELETE CASCADE,
    CONSTRAINT PK_Player PRIMARY KEY (UID)
);
CREATE TABLE if not exists Problems (
    PID UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    ProblemLink VARCHAR(250),
    Difficulty VARCHAR(8)
);
CREATE TABLE if not exists Topics (Type VARCHAR(20) PRIMARY KEY);

-- aggregation (RelatedTo)
CREATE TABLE if not exists Levels (
    PID UUID REFERENCES Problems,
    Type VARCHAR(20) REFERENCES Topics,
    CONSTRAINT PK_Quests PRIMARY KEY (PID, Type)
);
CREATE TABLE if not exists Quests (
    QID UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    UID UUID NOT NULL REFERENCES Admins (UID) ON DELETE CASCADE
);
CREATE TABLE if not exists Features (
    QID UUID REFERENCES Quests,
    PID UUID REFERENCES Problems,
    Type VARCHAR(20) REFERENCES Topics,
    CONSTRAINT PK_Features PRIMARY KEY (QID, PID, Type)
);
CREATE TABLE if not exists CompletedBy (
    UID UUID REFERENCES Player,
    PID UUID REFERENCES Problems,
    Type VARCHAR(20) REFERENCES Topics,
    Date DATE NOT NULL DEFAULT (current_date),
    CONSTRAINT PK_CompletedBy PRIMARY KEY (UID, PID, Type)
);