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
CREATE TABLE if not exists Players (
    UID UUID NOT NULL,
    CONSTRAINT FK_Players FOREIGN KEY (UID) REFERENCES Users (UID) ON DELETE CASCADE,
    CONSTRAINT PK_Players PRIMARY KEY (UID)
);
CREATE TABLE if not exists Problems (
    PID UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    ProblemLink VARCHAR(250),
    Difficulty VARCHAR(8)
);
CREATE TABLE if not exists Topics (Type VARCHAR(20) PRIMARY KEY);
CREATE TABLE IF NOT EXISTS Levels (
    PID UUID DEFAULT gen_random_uuid(),
    Type VARCHAR(20),
    CONSTRAINT FK_Problems FOREIGN KEY (PID) REFERENCES Problems(PID),
    CONSTRAINT FK_Topics FOREIGN KEY (Type) REFERENCES Topics(Type),
    CONSTRAINT PK_Levels PRIMARY KEY(PID, Type)
);
CREATE TABLE IF NOT EXISTS Quests (
    QID UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    UID UUID NOT NULL,
    CONSTRAINT FK_Quests_Admins FOREIGN KEY (UID) REFERENCES Admins(UID) ON DELETE CASCADE
);
-- No longer has Type attribute since Levels table already takes care of that
CREATE TABLE IF NOT EXISTS Features (
    QID UUID,
    PID UUID,
    CONSTRAINT FK_Features_Quests FOREIGN KEY (QID) REFERENCES Quests(QID),
    CONSTRAINT FK_Features_Problems FOREIGN KEY (PID) REFERENCES Problems(PID),
    CONSTRAINT PK_Features PRIMARY KEY (QID, PID)
);
-- No longer has Type attribute since Levels table already takes care of that
CREATE TABLE IF NOT EXISTS CompletedBy (
    UID UUID,
    PID UUID,
    Date DATE NOT NULL DEFAULT (current_date),
    CONSTRAINT FK_CompletedBy_Player FOREIGN KEY (UID) REFERENCES Players(UID),
    CONSTRAINT FK_CompletedBy_Problems FOREIGN KEY (PID) REFERENCES Problems(PID),
    CONSTRAINT PK_CompletedBy PRIMARY KEY (UID, PID)
);