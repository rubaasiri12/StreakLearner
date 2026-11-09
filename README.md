# Learning Streak — Xcode project

Open `LearningStreak.xcodeproj` (Xcode 16 or later), pick an iPhone simulator, and press Run (⌘R).
To see one page without running the app, open its file and turn on **Editor → Canvas** (⌥⌘↩).
Every file has its own previews, one for each state in the design.

## Files by task
```
LearningStreak/
├── App/
│   └── LearningStreakApp.swift          app entry + navigation (Full App preview)
├── Shared/
│   ├── LearningStore.swift              ALL the logic (streak, freezes, 32 h, goals)
│   ├── AppCalendar.swift                dates, week, month grid
│   ├── DayCircle.swift                  day number circle (orange / blue / today)
│   └── Theme.swift                      colors (#FA6400), glass style, buttons
├── Task1_StartLearning/
│   ├── Task1_OnboardingPage.swift       Hello Learner + Start Learning
│   └── Task1_GoalForm.swift             "I want to learn" + Week / Month / Year
├── Task2_LogDay/
│   ├── Task2_ActivityPage.swift         Activity page (4 state previews)
│   ├── Task2_WeekAndStreak.swift        S M T W T F S strip + days Learned / Freezed cards
│   └── Task2_LogButtons.swift           Log as Learned circle + Freeze for a day
├── Task3_GoalFinished/
│   └── Task3_GoalFinishedView.swift     Well done! / You didn't reach your goal
├── Task4_ChangeGoal/
│   └── Task4_LearningGoalPage.swift     Learning Goal page + "Update goal" alert
└── Task5_Calendar/
    └── Task5_ActivitiesCalendarPage.swift  Activities calendar (view only)
```

## Logic (Shared/LearningStore.swift)
- **Streak resets** after more than **32 hours** without logging Learned or using a Freeze, and when the **learning goal is updated**.
- **Freezes** keep the streak going. The limit depends on duration: **2 / week, 8 / month, 96 / year**.
- **Buttons are disabled** when all Freezes are used or today is already logged. They are enabled again at **12 AM**, even if the user logged at 11 PM.
- **Wording:** "1 day" and "4 days".
- **Goal complete:** learned + freezed days reach 7, 30 or 365. Task 3 then shows "Well done!". When the streak breaks, it shows "You didn't reach your goal this time.".
