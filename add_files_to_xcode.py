#!/usr/bin/env python3
"""
Script to add missing Swift files to Xcode project
"""
import hashlib
import re

# Files to add with their group paths
files_to_add = [
    ("ThinkFast/Data/Local/OnboardingQuestManager.swift", "Data/Local"),
    ("ThinkFast/Data/Local/StreakRecoveryManager.swift", "Data/Local"),
    ("ThinkFast/Domain/UseCase/UserBaselineCalculator.swift", "Domain/UseCase"),
    ("ThinkFast/Presentation/Auth/SignInView.swift", "Presentation/Auth"),
    ("ThinkFast/Presentation/Charts/AppBreakdownDonutChart.swift", "Presentation/Charts"),
    ("ThinkFast/Presentation/Charts/ChartModels.swift", "Presentation/Charts"),
    ("ThinkFast/Presentation/Charts/GoalProgressLineChart.swift", "Presentation/Charts"),
    ("ThinkFast/Presentation/Charts/TimePatternHeatmap.swift", "Presentation/Charts"),
    ("ThinkFast/Presentation/Charts/WeeklyUsageChart.swift", "Presentation/Charts"),
    ("ThinkFast/Presentation/Home/BaselineComparisonCard.swift", "Presentation/Home"),
    ("ThinkFast/Presentation/Home/QuestProgressCard.swift", "Presentation/Home"),
    ("ThinkFast/Presentation/Home/QuickWinCelebrations.swift", "Presentation/Home"),
    ("ThinkFast/Presentation/Home/StreakRecoveryCard.swift", "Presentation/Home"),
]

def generate_id(seed):
    """Generate a unique 24-character hex ID for Xcode"""
    hash_obj = hashlib.md5(seed.encode())
    return hash_obj.hexdigest()[:24].upper()

def add_files_to_project(project_path):
    """Add files to the Xcode project"""

    with open(project_path, 'r') as f:
        content = f.read()

    # Check which files are already in the project
    files_to_process = []
    for file_path, group_path in files_to_add:
        filename = file_path.split('/')[-1]
        if filename not in content:
            files_to_process.append((file_path, group_path, filename))
            print(f"Will add: {filename}")
        else:
            print(f"Already exists: {filename}")

    if not files_to_process:
        print("All files already in project!")
        return

    # Generate IDs for all files
    file_refs = {}
    build_files = {}

    for file_path, group_path, filename in files_to_process:
        file_ref_id = generate_id(f"fileref_{file_path}")
        build_file_id = generate_id(f"buildfile_{file_path}")
        file_refs[filename] = (file_ref_id, file_path)
        build_files[filename] = (build_file_id, file_ref_id)

    # Add to PBXFileReference section
    pbx_file_ref_marker = "/* Begin PBXFileReference section */"
    pbx_file_ref_pos = content.find(pbx_file_ref_marker)
    if pbx_file_ref_pos == -1:
        print("Error: Could not find PBXFileReference section")
        return

    # Find end of marker line
    insert_pos = content.find("\n", pbx_file_ref_pos)

    file_ref_entries = []
    for filename, (file_ref_id, file_path) in file_refs.items():
        relative_path = file_path.replace("ThinkFast/", "")
        entry = f"\t\t{file_ref_id} /* {filename} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {filename}; sourceTree = \"<group>\"; }};\n"
        file_ref_entries.append(entry)

    content = content[:insert_pos + 1] + ''.join(file_ref_entries) + content[insert_pos + 1:]

    # Add to PBXBuildFile section
    pbx_build_file_marker = "/* Begin PBXBuildFile section */"
    pbx_build_file_pos = content.find(pbx_build_file_marker)
    if pbx_build_file_pos == -1:
        print("Error: Could not find PBXBuildFile section")
        return

    insert_pos = content.find("\n", pbx_build_file_pos)

    build_file_entries = []
    for filename, (build_file_id, file_ref_id) in build_files.items():
        entry = f"\t\t{build_file_id} /* {filename} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_ref_id} /* {filename} */; }};\n"
        build_file_entries.append(entry)

    content = content[:insert_pos + 1] + ''.join(build_file_entries) + content[insert_pos + 1:]

    # Find and add to appropriate groups
    # For simplicity, we'll add all files to their parent group by finding similar files
    for filename, (file_ref_id, file_path) in file_refs.items():
        # Find a similar file in the same directory to insert near
        dir_name = '/'.join(file_path.split('/')[:-1])

        # Try to find existing files in the same directory
        pattern = re.escape(dir_name.split('/')[-1])

        # Add to children array - find the Home group or similar
        if "Home" in file_path:
            marker = "ManageAppsView.swift"
        elif "Charts" in file_path:
            marker = "ChartModels.swift"
            if marker not in content:
                marker = "Presentation /* Presentation */"
        elif "Auth" in file_path:
            marker = "Presentation /* Presentation */"
        elif "Data/Local" in file_path:
            marker = "Local /* Local */"
        elif "UseCase" in file_path:
            marker = "UseCase /* UseCase */"
        else:
            marker = "ThinkFast /* ThinkFast */"

        pos = content.find(marker)
        if pos != -1:
            # Find the next newline after this marker
            insert_pos = content.find("\n", pos)
            if insert_pos != -1:
                entry = f"\t\t\t\t{file_ref_id} /* {filename} */,\n"
                content = content[:insert_pos + 1] + entry + content[insert_pos + 1:]

    # Add to Sources build phase
    sources_marker = "/* Sources */ = {"
    sources_pos = content.find(sources_marker)
    if sources_pos != -1:
        # Find the "files = (" part
        files_start = content.find("files = (", sources_pos)
        if files_start != -1:
            insert_pos = content.find("\n", files_start)

            source_entries = []
            for filename, (build_file_id, file_ref_id) in build_files.items():
                entry = f"\t\t\t\t{build_file_id} /* {filename} in Sources */,\n"
                source_entries.append(entry)

            content = content[:insert_pos + 1] + ''.join(source_entries) + content[insert_pos + 1:]

    # Write back
    with open(project_path, 'w') as f:
        f.write(content)

    print(f"\nSuccessfully added {len(files_to_process)} files to project!")

if __name__ == "__main__":
    add_files_to_project("ThinkFast.xcodeproj/project.pbxproj")
