List of non-game components:

| Component name  | Purpose |
| ------------- | ------------- |
| ServerGameVersionProvider  | This server has only one purpose: it provides the client version number to the user. Its intended use is that the launcher can ask for the version number, then download that version.  |
| ClientLauncher  | This component is what the player downloads explicitly. It has a simple UI, with a button: check version. When clicked this turns either into "play" or "update". "update" downloads the matching version from github as a zip, then turns into "play". Does not require login.|
| ServerGameDatabase  | This server stores all player data and other changing data in a database, for example sqlite. it is not accessible to clients directly, all requests shall come from other Server components.  |
| ServerLoginQueue  | This server is the entry point when a player wants to login. It has a queue where a new login attempt is inserted into. It is in contact with the ServerSessionManagers, which tell how many more sesions they can handle, and distributes among them. Once through the queue, the server tells the IP of the SessionManager to the client and disconnects|
| ServerSessionManagers  | This server is the manages the connection to the client. It has a fixed capacity, e.g. 1000 sessions, so it does not get overwhelmed. It can interact with the ServerGameDatabase to get character data, and other ServerSessionManagers in case synchronization is needed. It might be that multiple instances are responsible for different levels, then a take-over when switching will be done |

# Launcher

This minimalistic launcher does not support partial updates, it retrieves the entire game on update.
It can be phased out once a game is released on steam or another distribution platform, which would then handle the updates.

```mermaid
sequenceDiagram
    ClientLauncher->>+ServerGameVersionProvider: Get current version
    ServerGameVersionProvider-->>-ClientLauncher: 1.0.0
    ClientLauncher-->>+ClientLauncher: delete old version
    ClientLauncher->>+CDN: download 1.0.0
    CDN-->>-ClientLauncher: 1.0.0
    ClientLauncher-->>+ClientLauncher: extract
    ClientLauncher->>+Game: start 1.0.0
    Game-->>-ClientLauncher: ""
    ClientLauncher-->>+ClientLauncher: close
```

Detailed Flowchart of user interaction for the Launcher.

```mermaid
flowchart TD
    classDef user fill:#096
    classDef code fill:#f96
    classDef code_choice fill:#999
    A1("Press Launcher desktop shortcut / click Launcher.exe"):::user
    A2("press connect"):::user
    A3("press update"):::user
    A4("press play"):::user
    A5("press X / Alt+F4 etc"):::user
    P1("Start Launcher"):::code
    P2("read ip/address+port from last session file"):::code
    P3("leave ip/address+port empty"):::code
    P4("Create UI window"):::code
    P5("set server address label"):::code
    P6("Connect to server and retrieve version number"):::code
    P7("show version retrieve error message"):::code
    P8("show current version"):::code
    P8_1("persist ip/address+port to last session file"):::code
    P9("check installed version"):::code
    P10("display update button"):::code
    P11("display play button"):::code
    P12("erase installed version"):::code
    P13("download given version"):::code
    P14("show download error message"):::code
    P15("extract downloaded version"):::code
    P16("erase artifacts before trying again"):::code
    P17("start game"):::code
    PFinal("Close Launcher"):::code
    C1{"last session file exists"}:::code_choice
    C2{"success retrieving version?"}:::code_choice
    C3{"same version?"}:::code_choice
    C4{"download success?"}:::code_choice
    C5{"extract success?"}:::code_choice

    %%start launcher%%
    A1 --> P1
    P1 --> C1
    C1 -- yes --> P2
    C1 -- no --> P3
    P2 & P3 --> P4
    P4 --> P5

    %%end%%
    P5 & P7 & P10 & P11 & P16 --> A5
    A5 --> PFinal

    %%connect%%
    P5 --> A2
    A2 --> P6
    P6 --> C2
    C2 -- no --> P7
    P7 -- retry or maybe change address --> A2
    C2 -- yes --> P8
    P8 --> P8_1
    P8_1 --> P9
    
    %%update%%
    P9 --> C3
    C3 -- no --> P10
    C3 -- yes --> P11
    P10 --> A3
    A3 --> P12
    P12 --> P13
    P13 --> C4
    C4 -- no -->P14
    P14 --> P16
    P16 --> A3
    C4 -- yes -->P15
    P15 --> C5
    C5 -- no --> A3
    C5 -- yes --> P11

    %%play%%
    P11 --> A4
    A4 --> P17
    P17 --> PFinal
```

## Extension ideas:

### diff update
a diff update can be established, by just creating an archive which contains all new and changed files, plus a changes.txt file. that file lists all files to erase.
such a diff refers to two versions, e.g. 
1.0.0_to_1.1.0.zip
This can be implemented once the project side has grown to a point where a full update takes annoyingly long. (say more than 30 sec)
the diff package could be prepared by a simple command line tool that takes two versions and builds the change.

### download in parts
at some points full releases would become too large to be contained in a single file.
so part download might be needed, e.g. 1.0.0_part0 etc.
likewise some parts might be kept constant to avoid re-download (e.g. specific assets like models)
this could be achieved by returning an array from the ServerGameVersionProvider e.g.
Client_1.0.0
AssetPack1_1.0.0
AssetPack2_1.2.0

### file sizes
github releases can be up to 2GB in size, per file.
probably once the total size approaches 1GB or a regular user-base > 1000 it would make sense to look for a dedicated CDN to host the files.
see also github doc
https://docs.github.com/en/repositories/working-with-files/managing-large-files/about-large-files-on-github

# ServerLoginQueue

```mermaid
sequenceDiagram
    autonumber
    alt no keypair
        Game->>+Game: Create public+private key pair
    end
    alt no clientID
        Game->>+ServerLoginQueue: RegisterNewClient(public key, optional server pw)
        ServerLoginQueue->>+ServerLoginQueue: Verify pw, reject if wrong
        ServerLoginQueue->>+ServerLoginQueue: Queue calls to reduce parallel calls to DB server
        ServerLoginQueue->>+ServerGameDatabase: RegisterNewClient(public key)
        ServerGameDatabase->>-ServerLoginQueue: clientID
        ServerLoginQueue->>-Game: clientID
        Game->>+Game: save clientID to local file
    end
    Game->>+Game: create token
    Game->>+ServerLoginQueue: Login(token, optional server pw)
    ServerLoginQueue->>+ServerLoginQueue: Verify pw, reject if wrong
    ServerLoginQueue->>+ServerGameDatabase: VerifyToken
    ServerGameDatabase->>-ServerLoginQueue: confirmation result
    alt bad token
        ServerLoginQueue->>-Game: reject login
    end
    ServerLoginQueue->>+ServerLoginQueue: Queue call until a slot is free
    ServerLoginQueue->>+ServerSessionManagers: announce upcoming client(token)
    ServerSessionManagers->>-ServerLoginQueue: acknowledge
    ServerLoginQueue->>+Game: token
    Game->>+ServerSessionManagers: login
    alt not announced client
        ServerSessionManagers->>-Game: reject login
    end
```