//
//  ContentView.swift
//  video-editor-for-slideshow
//
//  Created by Md Asif Hasan on 8/1/26.
//

import SwiftUI
import PhotosUI
import AVKit
import AVFoundation

struct ContentView: View {
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedVideoURL: URL?
    @State private var isLoading = false
    @State private var currentTempFileURL: URL?
    @State private var videoModel: VideoModel?
    @State private var isProcessingVideo = false
    
    var body: some View {
        VStack(spacing: 20) {
            if let videoModel = videoModel {
                VideoTrimmerView(videoModel: videoModel)
            } else if isLoading || isProcessingVideo {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 300)
                    VStack {
                        ProgressView()
                        Text(isProcessingVideo ? "Processing video..." : "Loading video...")
                            .foregroundColor(.gray)
                    }
                }
                
                if !isProcessingVideo {
                    PhotosPicker(selection: $selectedItem, matching: .videos) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Select Video")
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                }
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 300)
                    VStack {
                        Image(systemName: "video.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("No video selected")
                            .foregroundColor(.gray)
                    }
                }
                
                PhotosPicker(selection: $selectedItem, matching: .videos) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Select Video")
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .onDisappear {
            // Clean up temporary file when view disappears
            if let tempURL = currentTempFileURL {
                try? FileManager.default.removeItem(at: tempURL)
            }
        }
        .onChange(of: selectedItem) { oldValue, newValue in
                    Task {
                        // Clean up previous temporary file
                        if let tempURL = currentTempFileURL {
                            try? FileManager.default.removeItem(at: tempURL)
                            currentTempFileURL = nil
                        }
                        
                        if let item = newValue {
                            isLoading = true
                            do {
                                var videoURL: URL?
                                
                                // Try to load as URL first (for files directly selected)
                                if let url = try await item.loadTransferable(type: URL.self) {
                                    videoURL = url
                                    currentTempFileURL = nil
                                } else {
                                    // For photos library videos, load as Data and save to temp file
                                    if let videoData = try await item.loadTransferable(type: Data.self) {
                                        // Create a temporary file URL with appropriate extension
                                        let tempDirectory = FileManager.default.temporaryDirectory
                                        let tempFileURL = tempDirectory.appendingPathComponent(UUID().uuidString + ".mp4")
                                        
                                        // Write the video data to the temporary file
                                        try videoData.write(to: tempFileURL)
                                        videoURL = tempFileURL
                                        currentTempFileURL = tempFileURL
                                    }
                                }
                                
                                if let url = videoURL {
                                    selectedVideoURL = url
                                    
                                    // Now process the video to create VideoModel for trimming
                                    isLoading = false
                                    isProcessingVideo = true
                                    
                                    // Get screen size for thumbnail generation
                                    let screenSize = UIScreen.main.bounds.size
                                    
                                    do {
                                        videoModel = try await VideoModel(url: url, size: screenSize)
                                    } catch {
                                        print("Error creating VideoModel: \(error)")
                                        selectedVideoURL = nil
                                        currentTempFileURL = nil
                                    }
                                    
                                    isProcessingVideo = false
                                }
                            } catch {
                                print("Error loading video: \(error)")
                                selectedVideoURL = nil
                                currentTempFileURL = nil
                                isLoading = false
                                isProcessingVideo = false
                            }
                        } else {
                            selectedVideoURL = nil
                            videoModel = nil
                            isLoading = false
                            isProcessingVideo = false
                            currentTempFileURL = nil
                        }
                    }
                }
        }
    }

#Preview {
    ContentView()
}
