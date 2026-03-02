# Lesson Structure Visualization

## Hierarchical Structure

```mermaid
graph TD
    A[App Learn English] --> B1[BEGINNER A1-A2]
    A --> B2[ELEMENTARY A2-B1]
    A --> B3[INTERMEDIATE B1-B2]
    A --> B4[ADVANCED B2-C1]
    
    B1 --> T1[16 Main Topics]
    T1 --> S1[48 Sub-Lessons]
    S1 --> Q1[~288 Questions]
    
    B2 --> T2[10 Main Topics]
    T2 --> S2[30 Sub-Lessons]
    S2 --> Q2[~180 Questions]
    
    B3 --> T3[7 Main Topics]
    T3 --> S3[21 Sub-Lessons]
    S3 --> Q3[~126 Questions]
    
    B4 --> T4[5 Main Topics]
    T4 --> S4[15 Sub-Lessons]
    S4 --> Q4[~90 Questions]
    
    style A fill:#4CAF50,color:#fff
    style B1 fill:#2196F3,color:#fff
    style B2 fill:#FFC107,color:#000
    style B3 fill:#FF9800,color:#fff
    style B4 fill:#F44336,color:#fff
```

## Question Type Distribution

```mermaid
pie title Question Types Distribution
    "Multiple Choice" : 36
    "Fill Blank" : 26
    "Matching" : 17
    "Translation" : 12
    "Conversation" : 6
    "Listening" : 3
```

## Data Flow

```mermaid
flowchart LR
    A[Dictionary CSV] --> B[Python Script]
    B --> C[SQL Statements]
    C --> D[(PostgreSQL DB)]
    D --> E[Flutter App]
    E --> F[QuizScreen]
    F --> G[User Progress]
    G --> D
    
    style A fill:#E1F5FE
    style B fill:#FFF9C4
    style C fill:#F3E5F5
    style D fill:#C8E6C9
    style E fill:#FFCCBC
    style F fill:#CFD8DC
    style G fill:#B2DFDB
```

## Beginner Topics Overview

```mermaid
mindmap
  root((BEGINNER))
    Basics
      Alphabet
      Colors
      Numbers
    Daily Life
      Food & Drinks
      Clothes
      Body Parts
    Time & Place
      Weather
      Seasons
      Time
      Places
    People & Animals
      Family
      Animals
      Daily Activities
      Transportation
```

## Elementary Topics Overview

```mermaid
mindmap
  root((ELEMENTARY))
    Home & Work
      House & Home
      Shopping
      Jobs
    Lifestyle
      Hobbies
      Sports
      Health
    Communication
      School
      Technology
      Emotions
      Travel
```

## Intermediate Topics Overview

```mermaid
mindmap
  root((INTERMEDIATE))
    Professional
      Business English
      Money & Banking
    Society
      Environment
      Culture
      Current Events
    Personal
      Entertainment
      Relationships
```

## Advanced Topics Overview

```mermaid
mindmap
  root((ADVANCED))
    Academia
      Science
      Philosophy
      Literature
    Society
      Politics
      Economics
```

## Lesson to Questions Flow

```mermaid
sequenceDiagram
    participant U as User
    participant A as App
    participant D as Database
    participant Q as QuizScreen
    
    U->>A: Select Main Topic
    A->>D: Fetch Sub-Lessons
    D-->>A: Return Sub-Lessons
    A->>U: Display Sub-Lessons
    
    U->>A: Select Sub-Lesson
    A->>D: Fetch Questions
    D-->>A: Return Questions + Options
    A->>Q: Navigate to Quiz
    
    Q->>U: Show Question 1
    U->>Q: Submit Answer
    Q->>Q: Validate & Score
    Q->>U: Show Next Question
    
    Q->>A: Quiz Complete
    A->>D: Save Progress
    D-->>A: Progress Saved
    A->>U: Show Results
```

## Database Schema Relationships

```mermaid
erDiagram
    LESSONS ||--o{ LESSONS : "parent-child"
    LESSONS ||--o{ LESSON_QUESTIONS : "has many"
    LESSON_QUESTIONS ||--o{ LESSON_OPTIONS : "has many"
    LESSONS ||--o{ USER_LESSON_PROGRESS : "tracks"
    LESSON_QUESTIONS ||--o{ USER_ANSWERS : "records"
    
    LESSONS {
        uuid id PK
        string title
        string level
        string lesson_type
        uuid parent_lesson_id FK
        int lesson_order
    }
    
    LESSON_QUESTIONS {
        uuid id PK
        uuid lesson_id FK
        string question_type
        text question_text
        text correct_answer
        text vietnamese_text
        int question_order
    }
    
    LESSON_OPTIONS {
        uuid id PK
        uuid question_id FK
        text option_text
        boolean is_correct
        string match_pair_id
        int option_order
    }
    
    USER_LESSON_PROGRESS {
        uuid id PK
        uuid user_id FK
        uuid lesson_id FK
        boolean completed
        int progress_percentage
    }
```

## Question Type Implementation

```mermaid
graph TB
    Q[Question] --> T{Question Type}
    
    T -->|multiple_choice| MC[Multiple Choice Widget]
    MC --> O[Show Options]
    O --> S1[Select Answer]
    
    T -->|fill_blank| FB[TextField Widget]
    FB --> I[User Input]
    I --> V1[Validate Text]
    
    T -->|matching| M[Matching Widget]
    M --> P[Show Pairs]
    P --> C[Connect Pairs]
    
    T -->|listening| L[Audio Player]
    L --> A[Play Audio]
    A --> S2[Select Answer]
    
    T -->|translation| TR[Translation Input]
    TR --> I2[User Input]
    I2 --> V2[Validate Translation]
    
    T -->|conversation| CO[Conversation Widget]
    CO --> CT[Show Context]
    CT --> S3[Select Response]
    
    S1 --> R[Check Answer]
    V1 --> R
    C --> R
    S2 --> R
    V2 --> R
    S3 --> R
    
    R --> E{Correct?}
    E -->|Yes| SC[+Score]
    E -->|No| EX[Show Explanation]
    
    SC --> N[Next Question]
    EX --> N
    
    style Q fill:#E3F2FD
    style MC fill:#C5E1A5
    style FB fill:#FFECB3
    style M fill:#F8BBD0
    style L fill:#B2EBF2
    style TR fill:#D1C4E9
    style CO fill:#FFCCBC
    style R fill:#FFF59D
    style SC fill:#A5D6A7
    style EX fill:#EF9A9A
```

## Dictionary Integration

```mermaid
flowchart TD
    A[Vietnamese CSV<br/>11,604 words] --> C[Python Script]
    B[English CSV<br/>82,991 words] --> C
    
    C --> D{Question Generator}
    
    D --> E[Translation Questions]
    D --> F[Matching Pairs]
    D --> G[Fill Blank]
    D --> H[Multiple Choice]
    
    E --> I[SQL Export]
    F --> I
    G --> I
    H --> I
    
    I --> J[(Database)]
    
    J --> K[Flutter App]
    K --> L[QuizScreen]
    
    style A fill:#81C784
    style B fill:#64B5F6
    style C fill:#FFD54F
    style D fill:#FFB74D
    style I fill:#BA68C8
    style J fill:#4DB6AC
    style K fill:#FF8A65
    style L fill:#A1887F
```

## Progress Tracking Flow

```mermaid
stateDiagram-v2
    [*] --> NotStarted: User sees lesson
    NotStarted --> InProgress: Start quiz
    InProgress --> InProgress: Answer questions
    InProgress --> Completed: Finish all questions
    Completed --> [*]: Return to lessons
    
    InProgress --> Paused: Exit mid-quiz
    Paused --> InProgress: Resume
    
    Completed --> InProgress: Retry lesson
    
    note right of NotStarted
        progression_percentage: 0%
        completed: false
    end note
    
    note right of InProgress
        progression_percentage: 1-99%
        completed: false
        track correct_answers
    end note
    
    note right of Completed
        progression_percentage: 100%
        completed: true
        unlock next lesson
    end note
```

---

## Legend

### Colors by Level
- 🟢 **Beginner (A1-A2)** - Blue
- 🟡 **Elementary (A2-B1)** - Yellow
- 🟠 **Intermediate (B1-B2)** - Orange
- 🔴 **Advanced (B2-C1)** - Red

### Question Type Icons
- ✅ Multiple Choice
- ✏️ Fill in the Blank
- 🔗 Matching
- 🎧 Listening
- 🌐 Translation
- 💬 Conversation

---

*This visualization helps understand the complete structure of 114 lessons and their relationships.*
