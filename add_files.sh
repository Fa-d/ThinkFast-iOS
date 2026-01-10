#!/bin/bash

# List of files to add
FILES=(
  "ThinkFast/Data/Local/OnboardingQuestManager.swift"
  "ThinkFast/Data/Local/StreakRecoveryManager.swift"
  "ThinkFast/Domain/UseCase/UserBaselineCalculator.swift"
  "ThinkFast/Presentation/Auth/SignInView.swift"
  "ThinkFast/Presentation/Charts/AppBreakdownDonutChart.swift"
  "ThinkFast/Presentation/Charts/ChartModels.swift"
  "ThinkFast/Presentation/Charts/GoalProgressLineChart.swift"
  "ThinkFast/Presentation/Charts/TimePatternHeatmap.swift"
  "ThinkFast/Presentation/Charts/WeeklyUsageChart.swift"
  "ThinkFast/Presentation/Home/BaselineComparisonCard.swift"
  "ThinkFast/Presentation/Home/QuestProgressCard.swift"
  "ThinkFast/Presentation/Home/QuickWinCelebrations.swift"
  "ThinkFast/Presentation/Home/StreakRecoveryCard.swift"
)

echo "Files that need to be added to Xcode:"
for file in "${FILES[@]}"; do
  echo "  - $file"
done

echo ""
echo "Please follow these steps:"
echo "1. Xcode should now be open"
echo "2. In Xcode, right-click on the appropriate folder in the Navigator"
echo "3. Select 'Add Files to \"ThinkFast\"...'"
echo "4. Navigate to and select the files listed above"
echo "5. Make sure 'Copy items if needed' is UNCHECKED"
echo "6. Make sure 'ThinkFast' target is CHECKED"
echo "7. Click 'Add'"
echo ""
echo "Once done, press Enter to continue..."
read

echo "Building project..."
xcodebuild -project ThinkFast.xcodeproj -scheme ThinkFast -destination 'platform=iOS Simulator,name=iPhone 17' build 2>&1 | grep -E "(BUILD SUCCEEDED|BUILD FAILED|error:)"
