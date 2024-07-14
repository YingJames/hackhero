-- Enable pgcrypto extension for UUID generation
CREATE EXTENSION IF NOT EXISTS pgcrypto;
-- Users table
CREATE TABLE IF NOT EXISTS Users (
    UID UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    UName VARCHAR(16) NOT NULL UNIQUE,
    Email VARCHAR(255) NOT NULL UNIQUE,
    HashedPW VARCHAR(64) NOT NULL,
    Role VARCHAR(6) DEFAULT NULL,
    CONSTRAINT CHK_Role CHECK (Role IN ('Player', 'Admin') OR Role IS NULL)
);

-- Admins table
CREATE TABLE IF NOT EXISTS Admins (
    UID UUID PRIMARY KEY,
    CONSTRAINT FK_Admin FOREIGN KEY (UID) REFERENCES Users (UID) ON DELETE CASCADE
);

-- Players table
CREATE TABLE IF NOT EXISTS Players (
    UID UUID PRIMARY KEY,
    CONSTRAINT FK_Players FOREIGN KEY (UID) REFERENCES Users (UID) ON DELETE CASCADE
);

-- Problems table
CREATE TABLE IF NOT EXISTS Problems (
    PID UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ProblemLink VARCHAR(250) NOT NULL,
    Difficulty VARCHAR(8) NOT NULL,
    CONSTRAINT CHK_Problems_Difficulty CHECK (Difficulty IN ('Easy', 'Medium', 'Hard'))
);

-- Topics table
CREATE TABLE IF NOT EXISTS Topics (
    Type VARCHAR(20) PRIMARY KEY
);

-- Levels table
CREATE TABLE IF NOT EXISTS Levels (
    LID UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    PID UUID NOT NULL,
    CONSTRAINT FK_Problems FOREIGN KEY (PID) REFERENCES Problems(PID)
);

-- LevelTopics table
CREATE TABLE IF NOT EXISTS LevelTopics (
    LID UUID,
    Type VARCHAR(20),
    PRIMARY KEY (LID, Type),
    CONSTRAINT FK_Levels FOREIGN KEY (LID) REFERENCES Levels(LID) ON DELETE CASCADE,
    CONSTRAINT FK_Topics FOREIGN KEY (Type) REFERENCES Topics(Type)
);

-- Quests table
CREATE TABLE IF NOT EXISTS Quests (
    QID UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    UID UUID NOT NULL,
    Quest_Name VARCHAR(100) NOT NULL,
    CONSTRAINT FK_Quests_Admins FOREIGN KEY (UID) REFERENCES Admins(UID) ON DELETE CASCADE
);

-- QuestLevels table
CREATE TABLE IF NOT EXISTS QuestLevels (
    QID UUID,
    LID UUID,
    PRIMARY KEY (QID, LID),
    CONSTRAINT FK_QuestLevels_Quests FOREIGN KEY (QID) REFERENCES Quests(QID) ON DELETE CASCADE,
    CONSTRAINT FK_QuestLevels_Levels FOREIGN KEY (LID) REFERENCES Levels(LID)
);

-- PlayerQuests table
CREATE TABLE IF NOT EXISTS PlayerQuests (
    UID UUID,
    QID UUID,
    StartDate DATE NOT NULL DEFAULT CURRENT_DATE,
    CompletionDate DATE,
    PRIMARY KEY (UID, QID),
    CONSTRAINT FK_PlayerQuests_Players FOREIGN KEY (UID) REFERENCES Players(UID) ON DELETE CASCADE,
    CONSTRAINT FK_PlayerQuests_Quests FOREIGN KEY (QID) REFERENCES Quests(QID) ON DELETE CASCADE
);

-- CompletedLevels table
CREATE TABLE IF NOT EXISTS CompletedLevels (
    UID UUID,
    LID UUID,
    CompletionDate DATE NOT NULL DEFAULT CURRENT_DATE,
    PRIMARY KEY (UID, LID),
    CONSTRAINT FK_CompletedLevels_Players FOREIGN KEY (UID) REFERENCES Players(UID) ON DELETE CASCADE,
    CONSTRAINT FK_CompletedLevels_Levels FOREIGN KEY (LID) REFERENCES Levels(LID)
);

-- UserStats table
CREATE TABLE IF NOT EXISTS UserStats (
    UID UUID PRIMARY KEY,
    TotalProblemsCompleted INT DEFAULT 0,
    LastCompletionDate DATE,
    CONSTRAINT FK_UserStats_Players FOREIGN KEY (UID) REFERENCES Players(UID) ON DELETE CASCADE
);

-- FriendRequests table
CREATE TABLE IF NOT EXISTS FriendRequests (
    RequestID UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    SenderUID UUID NOT NULL,
    ReceiverUID UUID NOT NULL,
    RequestDate TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    Status VARCHAR(10) NOT NULL DEFAULT 'Pending',
    CONSTRAINT FK_FriendRequests_Sender FOREIGN KEY (SenderUID) REFERENCES Players(UID) ON DELETE CASCADE,
    CONSTRAINT FK_FriendRequests_Receiver FOREIGN KEY (ReceiverUID) REFERENCES Players(UID) ON DELETE CASCADE,
    CONSTRAINT CHK_FriendRequests_Status CHECK (Status IN ('Pending', 'Accepted', 'Rejected')),
    CONSTRAINT CHK_FriendRequests_NotSelf CHECK (SenderUID != ReceiverUID)
);

-- Friendships table
CREATE TABLE IF NOT EXISTS Friendships (
    FriendshipID UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    Player1UID UUID NOT NULL,
    Player2UID UUID NOT NULL,
    FriendshipDate TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT FK_Friendships_Player1 FOREIGN KEY (Player1UID) REFERENCES Players(UID) ON DELETE CASCADE,
    CONSTRAINT FK_Friendships_Player2 FOREIGN KEY (Player2UID) REFERENCES Players(UID) ON DELETE CASCADE,
    CONSTRAINT CHK_Friendships_NotSelf CHECK (Player1UID < Player2UID)
);

-- Function to ensure a user is not both an admin and a player
CREATE OR REPLACE FUNCTION ensure_user_role()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.Role = 'Admin' THEN
        IF EXISTS (SELECT 1 FROM Players WHERE UID = NEW.UID) THEN
            RAISE EXCEPTION 'User cannot be both an admin and a player';
        END IF;
        INSERT INTO Admins (UID) VALUES (NEW.UID);
    ELSIF NEW.Role = 'Player' THEN
        IF EXISTS (SELECT 1 FROM Admins WHERE UID = NEW.UID) THEN
            RAISE EXCEPTION 'User cannot be both a player and an admin';
        END IF;
        INSERT INTO Players (UID) VALUES (NEW.UID);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for Users table to manage roles
CREATE TRIGGER trg_manage_user_role
AFTER UPDATE OF Role ON Users
FOR EACH ROW
WHEN (NEW.Role IS NOT NULL)
EXECUTE FUNCTION ensure_user_role();

-- Function to update user statistics
CREATE OR REPLACE FUNCTION update_user_stats()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO UserStats (UID, TotalProblemsCompleted, LastCompletionDate)
    VALUES (NEW.UID, 1, NEW.CompletionDate)
    ON CONFLICT (UID) DO UPDATE
    SET TotalProblemsCompleted = UserStats.TotalProblemsCompleted + 1,
        LastCompletionDate = NEW.CompletionDate;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update user statistics when a level is completed
CREATE TRIGGER trg_update_user_stats
AFTER INSERT ON CompletedLevels
FOR EACH ROW
EXECUTE FUNCTION update_user_stats();

-- Function to check quest completion
CREATE OR REPLACE FUNCTION check_quest_completion()
RETURNS TRIGGER AS $$
DECLARE
    total_levels INT;
    completed_levels INT;
BEGIN
    SELECT COUNT(*) INTO total_levels
    FROM QuestLevels
    WHERE QID = NEW.QID;

    SELECT COUNT(*) INTO completed_levels
    FROM QuestLevels ql
    JOIN CompletedLevels cl ON ql.LID = cl.LID
    WHERE ql.QID = NEW.QID AND cl.UID = NEW.UID;

    IF total_levels = completed_levels THEN
        UPDATE PlayerQuests
        SET CompletionDate = CURRENT_DATE
        WHERE UID = NEW.UID AND QID = NEW.QID;
    ELSE
        UPDATE PlayerQuests
        SET CompletionDate = NULL
        WHERE UID = NEW.UID AND QID = NEW.QID;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to check quest completion when a level is completed
CREATE TRIGGER trg_check_quest_completion
AFTER INSERT OR DELETE ON CompletedLevels
FOR EACH ROW
EXECUTE FUNCTION check_quest_completion();

-- Function to prevent duplicate friend requests
CREATE OR REPLACE FUNCTION prevent_duplicate_friend_requests()
RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM FriendRequests
        WHERE (SenderUID = NEW.SenderUID AND ReceiverUID = NEW.ReceiverUID)
           OR (SenderUID = NEW.ReceiverUID AND ReceiverUID = NEW.SenderUID)
    ) THEN
        RAISE EXCEPTION 'A friend request already exists between these users';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to prevent duplicate friend requests
CREATE TRIGGER trg_prevent_duplicate_friend_requests
BEFORE INSERT ON FriendRequests
FOR EACH ROW
EXECUTE FUNCTION prevent_duplicate_friend_requests();

-- Function to create friendship when a friend request is accepted
CREATE OR REPLACE FUNCTION create_friendship_on_accept()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.Status = 'Accepted' THEN
        INSERT INTO Friendships (Player1UID, Player2UID)
        VALUES (LEAST(NEW.SenderUID, NEW.ReceiverUID), GREATEST(NEW.SenderUID, NEW.ReceiverUID));
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to create friendship when a friend request is accepted
CREATE TRIGGER trg_create_friendship_on_accept
AFTER UPDATE ON FriendRequests
FOR EACH ROW
WHEN (NEW.Status = 'Accepted')
EXECUTE FUNCTION create_friendship_on_accept();


-- Function to prevent duplicate friendships
CREATE OR REPLACE FUNCTION prevent_duplicate_friendships()
RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM Friendships
        WHERE (Player1UID = NEW.Player1UID AND Player2UID = NEW.Player2UID)
           OR (Player1UID = NEW.Player2UID AND Player2UID = NEW.Player1UID)
    ) THEN
        RAISE EXCEPTION 'A friendship already exists between these users';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to prevent duplicate friendships
CREATE TRIGGER trg_prevent_duplicate_friendships
BEFORE INSERT ON Friendships
FOR EACH ROW
EXECUTE FUNCTION prevent_duplicate_friendships();

