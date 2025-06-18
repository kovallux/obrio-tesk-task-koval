#!/usr/bin/env python3

import os
import uuid
import re

def generate_uuid():
    """Generate a UUID for Xcode project files"""
    return str(uuid.uuid4()).replace('-', '').upper()[:24]

def add_files_to_xcode_project():
    """Add new Swift files to the Xcode project"""
    
    # Files to add
    files_to_add = [
        # Logging
        "TransactionsTestTask/Core/Logging/BitcoinRateLogger.swift",
        
        # Use Cases
        "TransactionsTestTask/Domain/UseCases/AddTransactionUseCase.swift",
        "TransactionsTestTask/Domain/UseCases/UpdateBitcoinRateUseCase.swift", 
        "TransactionsTestTask/Domain/UseCases/FetchTransactionsUseCase.swift",
        
        # ViewModels
        "TransactionsTestTask/Presentation/ViewModels/AddTransactionViewModel.swift",
        "TransactionsTestTask/Presentation/ViewModels/DashboardViewModel.swift",
        
        # Views
        "TransactionsTestTask/Presentation/Views/Dashboard/DashboardViewController.swift",
        "TransactionsTestTask/Presentation/Views/Dashboard/DashboardHeaderView.swift",
        "TransactionsTestTask/Presentation/Views/Dashboard/TransactionListView.swift",
        "TransactionsTestTask/Presentation/Views/Common/LoadMoreTableViewCell.swift",
        "TransactionsTestTask/Presentation/Views/Common/TransactionTableViewCell.swift",
        "TransactionsTestTask/Presentation/Views/AddTransaction/AddTransactionViewController.swift",
        
        # Coordinator
        "TransactionsTestTask/Core/Coordinator/AppCoordinator.swift"
    ]
    
    project_file = "TransactionsTestTask.xcodeproj/project.pbxproj"
    
    if not os.path.exists(project_file):
        print(f"Error: {project_file} not found")
        return
    
    # Read the project file
    with open(project_file, 'r') as f:
        content = f.read()
    
    # Find the main group ID and sources build phase ID
    main_group_match = re.search(r'(\w{24}) = \{[^}]*isa = PBXGroup;[^}]*name = TransactionsTestTask;', content)
    if not main_group_match:
        print("Error: Could not find main group")
        return
    main_group_id = main_group_match.group(1)
    
    sources_phase_match = re.search(r'(\w{24}) = \{[^}]*isa = PBXSourcesBuildPhase;', content)
    if not sources_phase_match:
        print("Error: Could not find sources build phase")
        return
    sources_phase_id = sources_phase_match.group(1)
    
    # Generate UUIDs for new files
    file_refs = {}
    build_files = {}
    
    for file_path in files_to_add:
        if file_path in content:
            print(f"File {file_path} already exists in project")
            continue
            
        file_ref_id = generate_uuid()
        build_file_id = generate_uuid()
        
        file_refs[file_path] = file_ref_id
        build_files[file_path] = build_file_id
    
    if not file_refs:
        print("All files already exist in project")
        return
    
    # Add PBXFileReference entries
    file_ref_section = re.search(r'(\/\* Begin PBXFileReference section \*\/.*?)\/\* End PBXFileReference section \*\/', content, re.DOTALL)
    if file_ref_section:
        file_ref_content = file_ref_section.group(1)
        
        for file_path, file_ref_id in file_refs.items():
            filename = os.path.basename(file_path)
            file_ref_entry = f'\t\t{file_ref_id} /* {filename} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {filename}; sourceTree = "<group>"; }};\n'
            file_ref_content += file_ref_entry
        
        content = content.replace(file_ref_section.group(0), file_ref_content + "/* End PBXFileReference section */")
    
    # Add PBXBuildFile entries
    build_file_section = re.search(r'(\/\* Begin PBXBuildFile section \*\/.*?)\/\* End PBXBuildFile section \*\/', content, re.DOTALL)
    if build_file_section:
        build_file_content = build_file_section.group(1)
        
        for file_path, build_file_id in build_files.items():
            filename = os.path.basename(file_path)
            file_ref_id = file_refs[file_path]
            build_file_entry = f'\t\t{build_file_id} /* {filename} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_ref_id} /* {filename} */; }};\n'
            build_file_content += build_file_entry
        
        content = content.replace(build_file_section.group(0), build_file_content + "/* End PBXBuildFile section */")
    
    # Add files to sources build phase
    sources_phase_pattern = f'({sources_phase_id} = {{[^}}]*files = \\([^)]*)'
    sources_phase_match = re.search(sources_phase_pattern, content, re.DOTALL)
    if sources_phase_match:
        sources_content = sources_phase_match.group(1)
        
        for file_path, build_file_id in build_files.items():
            filename = os.path.basename(file_path)
            sources_entry = f'\t\t\t\t{build_file_id} /* {filename} in Sources */,\n'
            sources_content += sources_entry
        
        content = re.sub(sources_phase_pattern, sources_content, content, flags=re.DOTALL)
    
    # Write the updated project file
    with open(project_file, 'w') as f:
        f.write(content)
    
    print(f"Added {len(file_refs)} files to Xcode project")
    for file_path in file_refs.keys():
        print(f"  - {file_path}")

if __name__ == "__main__":
    add_files_to_xcode_project() 