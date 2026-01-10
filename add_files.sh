#!/bin/bash

# List of files to add
FILES=(
  "Intently/Data/Local/OnboardingQuestManager.swift"
  "Intently/Data/Local/StreakRecoveryManager.swift"
  "Intently/Domain/UseCase/UserBaselineCalculator.swift"
  "Intently/Presentation/Auth/SignInView.swift"
  "Intently/Presentation/Charts/AppBreakdownDonutChart.swift"
  "Intently/Presentation/Charts/ChartModels.swift"
  "Intently/Presentation/Charts/GoalProgressLineChart.swift"
  "Intently/Presentation/Charts/TimePatternHeatmap.swift"
  "Intently/Presentation/Charts/WeeklyUsageChart.swift"
  "Intently/Presentation/Home/BaselineComparisonCard.swift"
  "Intently/Presentation/Home/QuestProgressCard.swift"
  "Intently/Presentation/Home/QuickWinCelebrations.swift"
  "Intently/Presentation/Home/StreakRecoveryCard.swift"
)

echo "Files that need to be added to Xcode:"
for file in "${FILES[@]}"; do
  echo "  - $file"
done

echo ""
echo "Please follow these steps:"
echo "1. Xcode should now be open"
echo "2. In Xcode, right-click on the appropriate folder in the Navigator"
echo "3. Select 'Add Files to \"Intently\"...'"
echo "4. Navigate to and select the files listed above"
echo "5. Make sure 'Copy items if needed' is UNCHECKED"
echo "6. Make sure 'Intently' target is CHECKED"
echo "7. Click 'Add'"
echo ""
echo "Once done, press Enter to continue..."
read

echo "Building project..."
xcodebuild -project Intently.xcodeproj -scheme Intently -destination 'platform=iOS Simulator,name=iPhone 17' build 2>&1 | grep -E "(BUILD SUCCEEDED|BUILD FAILED|error:)"
